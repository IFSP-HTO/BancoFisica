#!/usr/bin/env python3
"""Small regression checks for the printed-exam workflow.

Run from the repository root:
    python tools/test_exam_workflow.py
"""
from __future__ import annotations

import importlib.util
import random
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
GEN = ROOT / "tools" / "generate_printed_exam.py"
spec = importlib.util.spec_from_file_location("generate_printed_exam", GEN)
mod = importlib.util.module_from_spec(spec)
sys.modules[spec.name] = mod
assert spec.loader is not None
spec.loader.exec_module(mod)


def main() -> int:
    profile = mod.load_yaml(ROOT / "provas" / "profiles" / "ifsp-omr.yaml")
    exam = mod.load_yaml(ROOT / "provas" / "examples" / "lancamento-obliquo" / "prova.yaml")
    mod.validate_config(exam, profile)
    assert len(exam["questions"]) == 10
    assert profile["layout"]["target_pages"] == 4

    q = mod.render_question(exam["questions"][0], 1, 1234, ROOT)
    before = q.alternatives[mod.LETTERS.index(q.answer)]
    q2 = mod.shuffle_alternatives(q, random.Random(9))
    after = q2.alternatives[mod.LETTERS.index(q2.answer)]
    assert before == after

    code1 = mod.opaque_code(random.Random(42), set())
    code2 = mod.opaque_code(random.Random(42), set())
    assert code1 == code2
    print("exam workflow unit checks: OK")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
