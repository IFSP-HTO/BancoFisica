#!/usr/bin/env python3
"""Choose which BancoFisica questions need expensive CI compilation tests."""

from __future__ import annotations

import argparse
from pathlib import Path, PurePosixPath

GLOBAL_PREFIXES = (
    "tests/",
    "R/",
    "templates/",
)
GLOBAL_EXACT = {
    ".github/workflows/ci-image.yml",
    ".github/workflows/r-tests.yml",
    "docker/ci/Dockerfile",
    "DESCRIPTION",
    "NAMESPACE",
    "renv.lock",
    "tools/ci_test_scope.py",
    "tools/moodle_xml_split.R",
}
GLOBAL_SUFFIXES = (".sty", ".cls", ".tex")


def normalize_changed_path(raw: str) -> str:
    path = raw.strip().replace("\\", "/")
    # Remove only an explicit relative-path prefix.  str.lstrip("./") is not
    # appropriate here: it treats its argument as a *set of characters* and
    # therefore turns ".github/..." into "github/...", preventing workflow
    # changes from matching GLOBAL_EXACT.
    while path.startswith("./"):
        path = path[2:]
    return path


def all_questions(repo_root: Path) -> list[str]:
    files = []
    for path in (repo_root / "BancoDeQuestoes").rglob("*"):
        if path.is_file() and path.suffix.lower() == ".rnw":
            files.append(path.relative_to(repo_root).as_posix())
    return sorted(files)


def is_global_change(path: str) -> bool:
    if path in GLOBAL_EXACT:
        return True
    if any(path.startswith(prefix) for prefix in GLOBAL_PREFIXES):
        return True
    # R tooling can alter validation/reporting behavior even without touching a question.
    # Fall back to the full suite so changes to those helpers are exercised in CI.
    if path.startswith("tools/") and path.lower().endswith(".r"):
        return True
    if not path.startswith("BancoDeQuestoes/") and path.lower().endswith(GLOBAL_SUFFIXES):
        return True
    return False


def topic_questions(repo_root: Path, topic: str) -> list[str]:
    topic_dir = repo_root / "BancoDeQuestoes" / topic
    if not topic_dir.exists():
        return []
    return sorted(
        path.relative_to(repo_root).as_posix()
        for path in topic_dir.rglob("*")
        if path.is_file() and path.suffix.lower() == ".rnw"
    )


def choose_scope(repo_root: Path, changed_paths: list[str], force_full: bool = False):
    changed = [normalize_changed_path(path) for path in changed_paths]
    changed = [path for path in changed if path]

    if force_full or any(is_global_change(path) for path in changed):
        questions = all_questions(repo_root)
        reason = "full run requested" if force_full else "global CI/test infrastructure changed"
        return "full", questions, reason

    affected: set[str] = set()
    bank_changed = False

    for path in changed:
        if not path.startswith("BancoDeQuestoes/"):
            continue

        bank_changed = True
        pure = PurePosixPath(path)
        parts = pure.parts
        if len(parts) < 2:
            continue

        topic = parts[1]
        if topic == "figuras":
            questions = all_questions(repo_root)
            return "full", questions, "shared BancoDeQuestoes/figuras asset changed"

        if pure.suffix.lower() == ".rnw":
            candidate = repo_root / Path(*parts)
            # Deleted questions do not need compilation; structural validation still runs.
            if candidate.exists():
                affected.add(pure.as_posix())
            continue

        # Supporting assets/data inside a topic can be shared by several questions.
        # Recompile the topic instead of trying to infer fragile file references.
        affected.update(topic_questions(repo_root, topic))

    if affected:
        return "incremental", sorted(affected), "BancoDeQuestoes changes mapped to affected questions"

    if bank_changed:
        return "incremental", [], "BancoDeQuestoes changed but no existing question requires compilation"

    return "none", [], "no question or shared compilation dependency changed"


def read_changed_files(path: Path) -> list[str]:
    if not path.exists():
        raise FileNotFoundError(f"changed-files list not found: {path}")
    return path.read_text(encoding="utf-8").splitlines()


def write_manifest(path: Path, questions: list[str]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    text = "".join(f"{question}\n" for question in questions)
    path.write_text(text, encoding="utf-8")


def append_github_output(path: Path, mode: str, count: int, reason: str) -> None:
    with path.open("a", encoding="utf-8") as handle:
        handle.write(f"mode={mode}\n")
        handle.write(f"question_count={count}\n")
        handle.write(f"reason={reason}\n")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--repo-root", default=".")
    parser.add_argument("--changed-files")
    parser.add_argument("--manifest", required=True)
    parser.add_argument("--github-output")
    parser.add_argument("--full", action="store_true")
    args = parser.parse_args()

    repo_root = Path(args.repo_root).resolve()
    if not args.full and not args.changed_files:
        parser.error("--changed-files is required unless --full is used")

    changed_paths = [] if args.full else read_changed_files(Path(args.changed_files))
    mode, questions, reason = choose_scope(repo_root, changed_paths, force_full=args.full)

    write_manifest(Path(args.manifest), questions)
    if args.github_output:
        append_github_output(Path(args.github_output), mode, len(questions), reason)

    print(f"CI test scope: {mode} ({len(questions)} question(s))")
    print(f"Reason: {reason}")
    for question in questions:
        print(question)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
