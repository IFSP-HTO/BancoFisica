#!/usr/bin/env python3
"""Generate printable BancoFisica exams in the IFSP OMR format.

The exam is described by YAML. Questions may be inline or may point to a simple
R/exams `schoice` .Rnw file. Rnw rendering uses `tools/render_exam_question.R`.

Outputs one TeX/PDF per version plus manifest.json and answer_key.csv.
"""
from __future__ import annotations

import argparse
import csv
import json
import random
import re
import shutil
import string
import subprocess
import sys
import tempfile
from dataclasses import dataclass
from pathlib import Path
from typing import Any

try:
    import yaml
except ImportError as exc:  # pragma: no cover
    raise SystemExit("PyYAML is required. Install with: pip install -r provas/requirements.txt") from exc

LETTERS = "ABCDE"
TOKEN_RE = re.compile(r"\{\{\s*([A-Za-z_][A-Za-z0-9_]*)\s*\}\}")


class ExamError(RuntimeError):
    pass


def load_yaml(path: Path) -> dict[str, Any]:
    with path.open("r", encoding="utf-8") as f:
        data = yaml.safe_load(f)
    if not isinstance(data, dict):
        raise ExamError(f"YAML root must be a mapping: {path}")
    return data


def substitute(text: str, params: dict[str, Any]) -> str:
    """Substitute only {{name}} tokens, leaving LaTeX braces untouched."""
    return TOKEN_RE.sub(lambda m: str(params.get(m.group(1), m.group(0))), text)


def opaque_code(rng: random.Random, used: set[str], length: int = 4) -> str:
    alphabet = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
    while True:
        code = "".join(rng.choice(alphabet) for _ in range(length))
        if code not in used:
            used.add(code)
            return code


def _extract_items(answerlist: str) -> list[str]:
    parts = re.split(r"\\item\s+", answerlist)
    return [p.strip() for p in parts[1:] if p.strip()]


def parse_schoice_rnw(source_text: str, rendered_tex: str) -> tuple[str, list[str], str]:
    if not re.search(r"%%\s*\\extype\{schoice\}", source_text):
        raise ExamError("Rnw source mode currently supports only extype{schoice}; adapt cloze/mchoice inline in the exam YAMl")
    sol = re.search(r"%%\s*\\exsolution\{([01]+)\}", source_text)
    if not sol:
        raise ExamError("Missing %% \\exsolution{...} in Rnw source")
    bits = sol.group(1)
    if bits.count("1") != 1:
        raise ExamError("Printed OMR exams require exactly one correct alternative")
    correct_index = bits.index("1")

    q = re.search(r"\\begin\{question\}(.*?)\\end\{question\}", rendered_tex, re.S)
    if not q:
        raise ExamError("Rendered Rnw has no question environment")
    body = q.group(1).strip()
    al = re.search(r"\\begin\{answerlist\}(.*?)\\end\{answerlist\}", body, re.S)
    if not al:
        raise ExamError("Rendered Rnw question has no answerlist")
    prompt = body[: al.start()].strip()
    alternatives = _extract_items(al.group(1))
    if len(alternatives) != len(bits):
        raise ExamError("Number of rendered alternatives differs from exsolution")
    return prompt, alternatives, LETTERS[correct_index]


def render_rnw(repo: Path, source: Path, seed: int) -> tuple[str, list[str], str]:
    helper = repo / "tools" / "render_exam_question.R"
    if not helper.exists():
        raise ExamError(f"Missing helper: {helper}")
    if shutil.which("Rscript") is None:
        raise ExamError("Rscript not found; required for Rnw question rendering")
    source_text = source.read_text(encoding="utf-8")
    with tempfile.TemporaryDirectory(prefix="bf-exam-") as td:
        rendered = Path(td) / "rendered.tex"
        cmd = ["Rscript", str(helper), str(source), str(rendered), str(seed)]
        proc = subprocess.run(cmd, cwd=repo, capture_output=True, text=True, errors="replace")
        if proc.returncode:
            raise ExamError(f"Rnw rendering failed for {source}:\n{proc.stderr or proc.stdout}")
        tex = rendered.read_text(encoding="utf-8")
    return parse_schoice_rnw(source_text, tex)


def copy_assets(repo: Path, output_assets: Path, tex: str) -> None:
    output_assets.mkdir(parents=True, exist_ok=True)
    refs = re.findall(r"\\includegraphics(?:\[[^\]]*\])?\{([^}]+)\}", tex)
    for ref in refs:
        p = Path(ref)
        if p.is_absolute() and p.exists():
            src = p
        else:
            candidates = [repo / ref, repo / "BancoDeQuestoes" / "figuras" / p.name]
            src = next((c for c in candidates if c.exists()), None)
        if src is None:
            raise ExamError(f"Image referenced by question was not found: {ref}")
        shutil.copy2(src, output_assets / src.name)


@dataclass
class RenderedQuestion:
    question_id: str
    difficulty: str
    skills: list[str]
    prompt: str
    alternatives: list[str]
    answer: str


def render_question(spec: dict[str, Any], version_index: int, version_seed: int, repo: Path) -> RenderedQuestion:
    qid = str(spec.get("id") or f"Q{version_index}")
    difficulty = str(spec.get("difficulty", "unspecified"))
    skills = [str(x) for x in spec.get("skills", [])]

    if "source_rnw" in spec:
        path = repo / str(spec["source_rnw"])
        if not path.exists():
            raise ExamError(f"Question source not found: {path}")
        prompt, alternatives, answer = render_rnw(repo, path, version_seed)
        return RenderedQuestion(qid, difficulty, skills, prompt, alternatives, answer)

    variants = spec.get("variants")
    if variants:
        variant = variants[(version_index - 1) % len(variants)]
        merged = {**spec, **variant}
    else:
        merged = spec

    params_sets = merged.get("parameter_sets") or [{}]
    params = params_sets[(version_index - 1) % len(params_sets)]
    prompt = substitute(str(merged.get("prompt", "")), params)
    alternatives = [substitute(str(x), params) for x in merged.get("alternatives", [])]
    answer = str(merged.get("answer", "")).strip().upper()
    if len(alternatives) != 5:
        raise ExamError(f"{qid}: printed profile requires exactly five alternatives")
    if answer not in LETTERS:
        raise ExamError(f"{qid}: answer must be one of A-E")
    return RenderedQuestion(qid, difficulty, skills, prompt, alternatives, answer)


def shuffle_alternatives(q: RenderedQuestion, rng: random.Random) -> RenderedQuestion:
    correct_text = q.alternatives[LETTERS.index(q.answer)]
    shuffled = q.alternatives[:]
    rng.shuffle(shuffled)
    answer = LETTERS[shuffled.index(correct_text)]
    return RenderedQuestion(q.question_id, q.difficulty, q.skills, q.prompt, shuffled, answer)


def question_tex(number: int, q: RenderedQuestion) -> str:
    items = "\n".join(f"\\item {a}" for a in q.alternatives)
    return f"\\qtitle{{{number}}}\n{q.prompt}\n\\begin{{alts}}\n{items}\n\\end{{alts}}\n"


def build_questions_tex(questions: list[RenderedQuestion], page_plan: list[dict[str, Any]]) -> str:
    out: list[str] = []
    seen: set[int] = set()
    for page_i, page in enumerate(page_plan):
        if page_i:
            out.append("\\end{multicols}\n\\newpage")
        out.append("\\begin{multicols}{2}\\raggedcolumns")
        breaks = set(int(x) for x in page.get("column_breaks_before", []))
        for n in [int(x) for x in page.get("questions", [])]:
            if n < 1 or n > len(questions):
                raise ExamError(f"page_plan refers to invalid question {n}")
            if n in seen:
                raise ExamError(f"page_plan repeats question {n}")
            seen.add(n)
            if n in breaks:
                out.append("\\columnbreak")
            out.append(question_tex(n, questions[n - 1]))
    out.append("\\end{multicols}")
    if seen != set(range(1, len(questions) + 1)):
        missing = sorted(set(range(1, len(questions) + 1)) - seen)
        raise ExamError(f"page_plan does not include questions: {missing}")
    return "\n".join(out)


def fill_template(template: str, replacements: dict[str, str]) -> str:
    for key, value in replacements.items():
        template = template.replace(f"%%BF_{key}%%", value)
    leftovers = sorted(set(re.findall(r"%%BF_([A-Z0-9_]+)%%", template)))
    if leftovers:
        raise ExamError(f"Unfilled template placeholders: {leftovers}")
    return template


def compile_tex(tex_path: Path) -> Path:
    if shutil.which("pdflatex") is None:
        raise ExamError("pdflatex not found; rerun with --no-compile or install a LaTeX distribution")
    for _ in range(2):
        proc = subprocess.run(
            ["pdflatex", "-interaction=nonstopmode", "-halt-on-error", tex_path.name],
            cwd=tex_path.parent,
            capture_output=True,
            text=True,
            errors="replace",
        )
        if proc.returncode:
            raise ExamError(f"LaTeX compilation failed for {tex_path.name}:\n{proc.stdout[-5000:]}")
    return tex_path.with_suffix(".pdf")


def validate_config(exam: dict[str, Any], profile: dict[str, Any]) -> None:
    questions = exam.get("questions") or []
    expected = int(profile.get("questions", 10))
    if len(questions) != expected:
        raise ExamError(f"Exam has {len(questions)} questions; profile requires {expected}")
    alternatives = profile.get("alternatives", list(LETTERS))
    if list(alternatives) != list(LETTERS):
        raise ExamError("Current OMR template expects alternatives A-E")


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("exam", type=Path, help="Exam YAML")
    ap.add_argument("--repo", type=Path, default=Path.cwd(), help="BancoFisica repository root")
    ap.add_argument("--no-compile", action="store_true", help="Write .tex but do not run pdflatex")
    ap.add_argument("--validate-only", action="store_true")
    args = ap.parse_args()

    repo = args.repo.resolve()
    exam_path = args.exam.resolve()
    exam = load_yaml(exam_path)
    profile_path = repo / str(exam.get("profile", "provas/profiles/ifsp-omr.yaml"))
    profile = load_yaml(profile_path)
    validate_config(exam, profile)
    if args.validate_only:
        print(f"OK: {exam_path}")
        return 0

    versions = int(exam.get("versions", profile.get("versions_default", profile.get("versions", 10))))
    seed = int(exam.get("seed", 1))
    exam_id = str(exam.get("exam_id", exam_path.stem))
    output = repo / str(exam.get("output_dir", f"build/provas/{exam_id}"))
    output.mkdir(parents=True, exist_ok=True)
    assets_dir = output / "assets"
    assets_dir.mkdir(exist_ok=True)

    template_path = repo / str(exam.get("template", "provas/templates/ifsp-omr.tex"))
    template = template_path.read_text(encoding="utf-8")
    page_plan = profile["layout"]["page_plan"]
    used_codes: set[str] = set()
    code_rng = random.Random(seed ^ 0xBFA11)

    manifest: dict[str, Any] = {
        "schema_version": 1,
        "exam_id": exam_id,
        "title": exam.get("title", "Avaliação"),
        "profile": str(profile_path.relative_to(repo)),
        "versions": {},
    }
    key_rows: list[list[str]] = [["control_code", "internal_id", *[f"Q{i}" for i in range(1, 11)]]]

    for v in range(1, versions + 1):
        version_seed = seed + v * 1009
        rng = random.Random(version_seed)
        control_code = opaque_code(code_rng, used_codes)
        internal_id = f"{exam_id}-{v:02d}"
        rendered: list[RenderedQuestion] = []
        for qspec in exam["questions"]:
            q = render_question(qspec, v, version_seed, repo)
            if bool(exam.get("shuffle_alternatives", profile.get("shuffle_alternatives", True))):
                q = shuffle_alternatives(q, rng)
            rendered.append(q)
            copy_assets(repo, assets_dir, q.prompt + "\n" + "\n".join(q.alternatives))

        answers = [q.answer for q in rendered]
        qr_payload = f"BancoFisica|{exam_id}|{control_code}"
        replacements = {
            "INSTITUTION": str(exam.get("institution", "Instituto Federal de São Paulo")),
            "CAMPUS": str(exam.get("campus", "Câmpus Hortolândia")),
            "SUBJECT": str(exam.get("subject", "Física")),
            "TITLE": str(exam.get("title", "Avaliação")),
            "QUESTION_COUNT": str(len(rendered)),
            "HEADER_LEFT": str(exam.get("header_left", "IFSP - Câmpus Hortolândia")),
            "HEADER_RIGHT": str(exam.get("header_right", exam.get("subject", "Física"))),
            "CONTROL_CODE": control_code,
            "QR_PAYLOAD": qr_payload,
            "EXTRA_INSTRUCTIONS": str(exam.get("extra_instructions_tex", "")),
            "FORMULA_SHEET": str(exam.get("formula_sheet_tex", "")),
            "QUESTIONS": build_questions_tex(rendered, page_plan),
        }
        tex = fill_template(template, replacements)
        tex_path = output / f"prova_{v:02d}.tex"
        tex_path.write_text(tex, encoding="utf-8")
        if not args.no_compile:
            compile_tex(tex_path)

        manifest["versions"][control_code] = {
            "internal_id": internal_id,
            "qr_payload": qr_payload,
            "answers": answers,
            "questions": [
                {"number": i + 1, "id": q.question_id, "difficulty": q.difficulty, "skills": q.skills}
                for i, q in enumerate(rendered)
            ],
        }
        key_rows.append([control_code, internal_id, *answers])

    (output / "manifest.json").write_text(json.dumps(manifest, ensure_ascii=False, indent=2), encoding="utf-8")
    with (output / "answer_key.csv").open("w", encoding="utf-8", newline="") as f:
        csv.writer(f).writerows(key_rows)

    print(f"Generated {versions} version(s) in {output}")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except ExamError as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        raise SystemExit(2)
