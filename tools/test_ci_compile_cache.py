#!/usr/bin/env python3
"""Regression checks for tools/ci_compile_cache.py."""

from __future__ import annotations

import tempfile
from pathlib import Path

from ci_compile_cache import fingerprint_questions


def write(path: Path, data: str | bytes) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    if isinstance(data, bytes):
        path.write_bytes(data)
    else:
        path.write_text(data, encoding="utf-8")


def fp(root: Path, env: str = "env-A") -> str:
    return fingerprint_questions(
        root, ["BancoDeQuestoes/topico/Q1.Rnw"], env
    )[0][1]


def scaffold(root: Path) -> None:
    write(root / "BancoDeQuestoes/topico/Q1.Rnw", "question-v1")
    write(root / "BancoDeQuestoes/outro/Q2.Rnw", "unrelated-v1")
    write(root / "BancoDeQuestoes/topico/figura.png", b"image-v1")
    write(root / "templates/plain8.tex", "template-v1")
    write(root / "R/helper.R", "helper-v1")
    write(root / "DESCRIPTION", "Package: BancoFisica\nVersion: 0.0.1\n")
    write(root / "NAMESPACE", "")
    write(root / "docker/ci/Dockerfile", "FROM example\n")
    write(root / "tests/tests.R", "validator-v1")
    write(root / "tests/run_tests_parallel.R", "runner-v1")
    write(root / "tools/ci_compile_cache.py", "fingerprinter-v1")
    write(root / ".github/workflows/r-tests.yml", "workflow-v1")


def main() -> int:
    with tempfile.TemporaryDirectory() as tmp:
        root = Path(tmp)
        scaffold(root)

        base = fp(root)
        assert fp(root) == base, "identical inputs must produce identical fingerprints"

        write(root / "BancoDeQuestoes/topico/Q1.Rnw", "question-v2")
        assert fp(root) != base, ".Rnw change must invalidate"
        write(root / "BancoDeQuestoes/topico/Q1.Rnw", "question-v1")
        assert fp(root) == base

        # An unrelated question source is not a dependency of Q1 and must not
        # invalidate Q1's content-addressed cache entry.
        write(root / "BancoDeQuestoes/outro/Q2.Rnw", "unrelated-v2")
        assert fp(root) == base, "unrelated .Rnw must not invalidate Q1"

        write(root / "BancoDeQuestoes/topico/figura.png", b"image-v2")
        assert fp(root) != base, "support asset change must invalidate"
        write(root / "BancoDeQuestoes/topico/figura.png", b"image-v1")
        assert fp(root) == base

        write(root / "templates/plain8.tex", "template-v2")
        assert fp(root) != base, "template change must invalidate"
        write(root / "templates/plain8.tex", "template-v1")
        assert fp(root) == base

        write(root / "tests/tests.R", "validator-v2")
        assert fp(root) != base, "validator change must invalidate"
        write(root / "tests/tests.R", "validator-v1")
        assert fp(root) == base

        write(root / "tests/run_tests_parallel.R", "runner-v2")
        assert fp(root) != base, "runner/tool change must invalidate"
        write(root / "tests/run_tests_parallel.R", "runner-v1")
        assert fp(root) == base

        write(root / "tools/ci_compile_cache.py", "fingerprinter-v2")
        assert fp(root) != base, "fingerprint implementation change must invalidate"
        write(root / "tools/ci_compile_cache.py", "fingerprinter-v1")
        assert fp(root) == base

        write(root / "docker/ci/Dockerfile", "FROM other-example\n")
        assert fp(root) != base, "toolchain definition change must invalidate"
        write(root / "docker/ci/Dockerfile", "FROM example\n")
        assert fp(root) == base

        assert fp(root, env="env-B") != base, "environment change must invalidate"

    print("ci_compile_cache regression checks: PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
