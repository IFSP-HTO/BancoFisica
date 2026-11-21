#!/usr/bin/env python3
"""Coordena lotes editoriais de questões, mantendo a fonte original auditável.

O único adaptador de captura habilitado neste momento é Professor Filatte.
Os motores legados de estágio e recorte de óptica permanecem inalterados.
Nenhum comando cria .Rnw, realiza commit ou publica questões automaticamente.
"""
from __future__ import annotations

import argparse
from collections import Counter
import json
from pathlib import Path
import re
import subprocess
import sys
from urllib.parse import urlparse

ROOT = Path(__file__).resolve().parents[1]
SOURCES = {"professor-filatte": "provas.professorfilatte.com.br"}
ID_RE = re.compile(r"^[a-z0-9][a-z0-9._-]{2,99}$")
PNG_RE = re.compile(r"^[A-Za-z0-9][A-Za-z0-9_.-]*\.png$")
SHA_RE = re.compile(r"^[0-9a-f]{64}$")
DECISIONS = {"candidata", "selecionada", "rejeitada", "aprovada"}
DIFFICULTIES = {"facil", "media", "dificil"}
QUALITY = ("clareza", "correcao_fisica", "alinhamento_curricular", "raciocinio")
APPROVAL_CHECKS = (
    "enunciado_conferido", "gabarito_conferido", "fisica_conferida",
    "figura_conferida", "direitos_revisados", "duplicidade_conferida",
    "parametrizacao_testada", "exams_testado",
)


def read_json(path):
    return json.loads(Path(path).read_text(encoding="utf-8"))


def inspect_manifest(path, repo_root=ROOT):
    """Retorna (manifesto, problemas, alertas). Não altera arquivos."""
    data = read_json(path)
    problems, alerts = [], []
    if data.get("schema_version") != 1:
        problems.append("schema_version deve ser 1")
    source = data.get("source")
    subject = data.get("subject")
    if source not in SOURCES:
        problems.append("Fonte não suportada: " + str(source))
    if not isinstance(subject, str) or not ID_RE.fullmatch(subject):
        problems.append("subject deve ser um identificador de assunto seguro")
    batch_id = data.get("batch_id", "")
    if not isinstance(batch_id, str) or not ID_RE.fullmatch(batch_id):
        problems.append("batch_id inválido")
    questions = data.get("questions")
    if not isinstance(questions, list):
        problems.append("questions deve ser uma lista")
        questions = []
    if not questions:
        alerts.append("Lote sem itens: estrutura preparada, nenhuma questão selecionada")

    ids, urls = set(), set()
    existing_texts = []
    question_dir = Path(repo_root) / "BancoDeQuestoes"
    if question_dir.exists():
        for file in question_dir.rglob("*.Rnw"):
            existing_texts.append((str(file.relative_to(repo_root)), file.read_text(
                encoding="utf-8", errors="replace"
            )))
    for i, q in enumerate(questions, 1):
        label = f"item {i}"
        if not isinstance(q, dict):
            problems.append(label + ": item não é objeto")
            continue
        qid, url = q.get("id"), q.get("url")
        if not isinstance(qid, str) or not ID_RE.fullmatch(qid):
            problems.append(label + ": id inválido")
            continue
        label = qid
        if qid in ids:
            problems.append(label + ": ID duplicado no lote")
        ids.add(qid)
        parsed = urlparse(url) if isinstance(url, str) else None
        if (not parsed or parsed.scheme != "https" or parsed.hostname != SOURCES.get(source)
                or parsed.username or parsed.password):
            problems.append(label + ": URL fora da fonte HTTPS autorizada")
        if url in urls:
            problems.append(label + ": URL duplicada no lote")
        urls.add(url)
        correct = q.get("correct")
        if correct not in ("A", "B", "C", "D", "E"):
            problems.append(label + ": correct deve ser uma letra de A a E conferida")
        pedagogy = q.get("pedagogy") or {}
        if not isinstance(pedagogy, dict):
            problems.append(label + ": pedagogy inválida")
            continue
        decision = pedagogy.get("decision")
        if decision not in DECISIONS:
            problems.append(label + ": decisão editorial ausente/inválida")
        if pedagogy.get("difficulty") not in DIFFICULTIES:
            problems.append(label + ": dificuldade ausente/inválida")
        for field in ("topic", "skill", "justification"):
            if not isinstance(pedagogy.get(field), str) or not pedagogy[field].strip():
                problems.append(label + ": ficha pedagógica sem " + field)
        checks = q.get("verification") or {}
        if not isinstance(checks, dict):
            problems.append(label + ": verification inválida")
            continue
        quality = pedagogy.get("quality") or {}
        if decision in ("selecionada", "aprovada"):
            if not checks.get("enunciado_conferido") or not checks.get("gabarito_conferido"):
                problems.append(label + ": selecionar exige enunciado e gabarito conferidos")
            if not isinstance(pedagogy.get("reason_for_selection"), str) or not pedagogy["reason_for_selection"].strip():
                problems.append(label + ": justificar o ganho em relação ao banco atual")
        if decision == "aprovada":
            for name in APPROVAL_CHECKS:
                if checks.get(name) is not True:
                    problems.append(label + ": aprovação bloqueada; falta " + name)
            if not isinstance(quality, dict):
                problems.append(label + ": quality inválida")
                quality = {}
            for field in QUALITY:
                value = quality.get(field)
                if type(value) is not int or not 1 <= value <= 5:
                    problems.append(label + ": nota de qualidade ausente/inválida: " + field)
            if (quality.get("correcao_fisica") != 5
                    or (isinstance(quality.get("alinhamento_curricular"), int)
                        and quality["alinhamento_curricular"] < 4)):
                problems.append(label + ": física deve receber 5 e alinhamento pelo menos 4")
        if decision != "rejeitada" and isinstance(url, str):
            found = [file for file, content in existing_texts if url in content]
            if found:
                problems.append(label + ": URL já encontrada no banco: " + ", ".join(found[:3]))
    return data, problems, alerts


def check_crop_plan(path, stage_dir):
    plan = read_json(path)
    report_path = Path(stage_dir) / "manifest.json"
    if not report_path.is_file():
        raise ValueError("Relatório de estágio inexistente: " + str(report_path))
    report = read_json(report_path)
    staged = {item["id"]: item for item in report["items"] if item.get("status") != "blocked"}
    if not isinstance(plan.get("items"), list) or not plan["items"]:
        raise ValueError("Plano de recortes vazio ou inválido")
    output_names = set()
    for entry in plan["items"]:
        qid = entry.get("id")
        if qid not in staged:
            raise ValueError("Item não encontrado no estágio: " + str(qid))
        if entry.get("visual_reviewed") is not True:
            raise ValueError("Recorte sem conferência visual explícita: " + str(qid))
        sha = entry.get("source_sha256")
        if not isinstance(sha, str) or not SHA_RE.fullmatch(sha):
            raise ValueError("SHA-256 inválido para: " + str(qid))
        if sha != staged[qid].get("sha256"):
            raise ValueError("Hash do plano difere do estágio: " + str(qid))
        figures = entry.get("figures")
        if not isinstance(figures, list) or not figures:
            raise ValueError("Figuras não revisadas: " + str(qid))
        for fig in figures:
            name, box = fig.get("name"), fig.get("box")
            if not isinstance(name, str) or not PNG_RE.fullmatch(name):
                raise ValueError("Nome inseguro de figura")
            if name in output_names:
                raise ValueError("Figura duplicada no plano: " + name)
            output_names.add(name)
            if (not isinstance(box, list) or len(box) != 4
                    or not all(type(x) is int and x >= 0 for x in box)
                    or box[0] >= box[2] or box[1] >= box[3]):
                raise ValueError("Coordenadas inválidas: " + name)
    return len(plan["items"]), len(output_names)


def command_validate(args):
    data, problems, alerts = inspect_manifest(args.manifest, args.repo_root)
    decisions = Counter((q.get("pedagogy") or {}).get("decision", "sem_decisao")
                        for q in data.get("questions", []) if isinstance(q, dict))
    if args.require_approved:
        if not data.get("questions"):
            problems.append("Não é possível aprovar um lote vazio")
        for q in data.get("questions", []):
            if q.get("pedagogy", {}).get("decision") != "aprovada":
                problems.append(q.get("id", "?") + ": não está aprovada para publicação")
    print(json.dumps({"batch_id": data.get("batch_id"), "source": data.get("source"),
                      "subject": data.get("subject"), "total": len(data.get("questions", [])),
                      "decisions": decisions, "problems": problems, "alerts": alerts},
                     ensure_ascii=False, indent=2))
    return 1 if problems else 0


def command_stage(args):
    data, problems, alerts = inspect_manifest(args.manifest, args.repo_root)
    if problems:
        raise ValueError("Manifesto inválido:\n" + "\n".join(problems))
    if not data["questions"]:
        raise ValueError("Lote vazio; estágio não realizado")
    if data["source"] != "professor-filatte":
        raise ValueError("Não existe adaptador de captura para a fonte escolhida")
    import requests
    from stage_filatte_optica import HEADERS, stage as stage_filatte
    outdir = Path(args.out_dir)
    outdir.mkdir(parents=True, exist_ok=True)
    session = requests.Session()
    session.headers.update(HEADERS)
    results = []
    for q in data["questions"]:
        decision = q["pedagogy"]["decision"]
        if decision == "rejeitada":
            results.append({"id": q["id"], "status": "skipped_rejected"})
            continue
        staged_q = dict(q)
        checks = q.get("verification") or {}
        # Em HTML 403, o motor antigo só pode usar metadados conferidos
        # por revisão humana documentada no manifesto.
        if not (checks.get("enunciado_conferido") is True
                and checks.get("gabarito_conferido") is True):
            staged_q.pop("image_url", None)
        try:
            result = stage_filatte(session, staged_q, outdir)
            result["editorial_decision"] = decision
            result["subject"] = data["subject"]
        except Exception as exc:
            result = {"id": q["id"], "url": q["url"], "status": "blocked",
                      "error": type(exc).__name__ + ": " + str(exc)}
        results.append(result)
    blocked = sum(x.get("status") == "blocked" for x in results)
    report = {"batch_id": data["batch_id"], "subject": data["subject"],
              "source": data["source"], "total": len(results),
              "staged": sum(x.get("status") == "pending_visual_review" for x in results),
              "blocked": blocked, "items": results}
    (outdir / "manifest.json").write_text(
        json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    print(json.dumps({k: v for k, v in report.items() if k != "items"}, ensure_ascii=False))
    return 2 if blocked else 0


def command_crop(args):
    count, figures = check_crop_plan(args.manifest, args.stage_dir)
    cmd = [sys.executable, str(ROOT / "tools" / "crop_filatte_optica.py"),
           "--manifest", str(args.manifest), "--stage-dir", str(args.stage_dir),
           "--dest", str(args.dest)]
    subprocess.run(cmd, cwd=ROOT, check=True)
    print(json.dumps({"source_items": count, "cropped_figures": figures},
                     ensure_ascii=False))
    return 0


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="command", required=True)
    val = sub.add_parser("validate", help="Valida ficha editorial, duplicatas e aprovação")
    val.add_argument("--manifest", required=True)
    val.add_argument("--repo-root", default=str(ROOT))
    val.add_argument("--require-approved", action="store_true")
    stage = sub.add_parser("stage", help="Obtém fontes originais e registra hashes")
    stage.add_argument("--manifest", required=True)
    stage.add_argument("--repo-root", default=str(ROOT))
    stage.add_argument("--out-dir", default="build/questoes-stage")
    crop = sub.add_parser("crop", help="Recorta figuras originais verificadas")
    crop.add_argument("--manifest", required=True)
    crop.add_argument("--stage-dir", default="build/questoes-stage")
    crop.add_argument("--dest", default="BancoDeQuestoes/figuras")
    args = parser.parse_args()
    try:
        return {"validate": command_validate, "stage": command_stage,
                "crop": command_crop}[args.command](args)
    except (OSError, ValueError, KeyError, subprocess.CalledProcessError) as exc:
        print("ERRO: " + str(exc), file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
