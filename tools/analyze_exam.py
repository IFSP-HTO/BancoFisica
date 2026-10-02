#!/usr/bin/env python3
"""Analyze BancoFisica OMR grade CSVs without storing student-level history."""
from __future__ import annotations

import argparse
import csv
import json
import statistics
from collections import defaultdict
from datetime import date
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

def assert_private_input(path: Path) -> None:
    try:
        rel = path.resolve().relative_to(ROOT)
    except ValueError:
        return
    if len(rel.parts) < 2 or rel.parts[:2] != ("build", "private"):
        raise SystemExit("Privacy guard: student-level grades inside the repository must live under build/private/.")


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("grades", type=Path)
    ap.add_argument("--manifest", type=Path, required=True)
    ap.add_argument("--output-dir", type=Path, default=Path("analysis"))
    ap.add_argument("--cohort", default="unspecified")
    ap.add_argument("--date", default=str(date.today()))
    ap.add_argument("--pass-score", type=float, default=6.0)
    ap.add_argument("--history", type=Path, help="Append aggregate item statistics to item_history.csv")
    args = ap.parse_args()

    assert_private_input(args.grades)
    manifest = json.loads(args.manifest.read_text(encoding="utf-8"))
    with args.grades.open(encoding="utf-8-sig", newline="") as f:
        rows = list(csv.DictReader(f))
    valid = [r for r in rows if r.get("key") and r.get("responses") and r.get("score") not in (None, "")]
    scores = [float(r["score"]) for r in valid]
    if not scores:
        raise SystemExit("No gradable rows found")

    item = defaultdict(lambda: {"n": 0, "correct": 0, "difficulty": "", "skills": set()})
    for r in valid:
        code = r["control_code"]
        version = manifest["versions"].get(code)
        if not version:
            continue
        resp, key = r["responses"], r["key"]
        for i, meta in enumerate(version["questions"]):
            qid = meta["id"]
            rec = item[qid]
            rec["n"] += 1
            rec["correct"] += int(i < len(resp) and i < len(key) and resp[i] == key[i])
            rec["difficulty"] = meta.get("difficulty", "")
            rec["skills"].update(meta.get("skills", []))

    summary = {
        "exam_id": manifest.get("exam_id"),
        "cohort": args.cohort,
        "date": args.date,
        "n": len(scores),
        "mean": statistics.fmean(scores),
        "median": statistics.median(scores),
        "min": min(scores),
        "max": max(scores),
        "pass_score": args.pass_score,
        "n_pass": sum(s >= args.pass_score for s in scores),
        "n_below": sum(s < args.pass_score for s in scores),
    }
    args.output_dir.mkdir(parents=True, exist_ok=True)
    (args.output_dir / "summary.json").write_text(json.dumps(summary, ensure_ascii=False, indent=2), encoding="utf-8")

    item_rows = []
    for qid, rec in sorted(item.items()):
        p = rec["correct"] / rec["n"] if rec["n"] else 0
        item_rows.append([qid, rec["difficulty"], ",".join(sorted(rec["skills"])), rec["n"], rec["correct"], p])
    with (args.output_dir / "item_analysis.csv").open("w", encoding="utf-8", newline="") as f:
        w = csv.writer(f)
        w.writerow(["question_id", "difficulty_expected", "skills", "n_students", "n_correct", "p_correct"])
        w.writerows(item_rows)

    if args.history:
        new_file = not args.history.exists()
        args.history.parent.mkdir(parents=True, exist_ok=True)
        with args.history.open("a", encoding="utf-8", newline="") as f:
            w = csv.writer(f)
            if new_file:
                w.writerow(["date", "exam_id", "cohort", "question_id", "difficulty_expected", "skills", "n_students", "n_correct", "p_correct", "notes"])
            for qid, difficulty, skills, n, correct, p in item_rows:
                w.writerow([args.date, manifest.get("exam_id"), args.cohort, qid, difficulty, skills, n, correct, f"{p:.6f}", ""])

    print(json.dumps(summary, ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
