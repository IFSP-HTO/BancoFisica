#!/usr/bin/env python3
"""Content fingerprints for BancoFisica compilation-cache entries.

The cache is intentionally conservative.  A question fingerprint includes:

* the exact .Rnw bytes;
* every non-.Rnw support file below BancoDeQuestoes/ (safe superset of assets
  actually used by the question);
* global compilation/validation inputs (templates, R helpers, CI/test runner,
  dependency declarations and relevant workflow files);
* an exact environment fingerprint supplied by the caller.

This can create extra misses when an unrelated asset changes, but it cannot
create a false hit because a support dependency was omitted.  Task-specific
format/seed are appended by the R runner to this base fingerprint.
"""

from __future__ import annotations

import argparse
import csv
import hashlib
from pathlib import Path

SCHEMA_VERSION = "bancofisica-compile-cache-v1"

GLOBAL_FILES = (
    "DESCRIPTION",
    "NAMESPACE",
    "docker/ci/Dockerfile",
    "tests/tests.R",
    "tests/run_tests_parallel.R",
    "tools/ci_compile_cache.py",
    ".github/workflows/r-tests.yml",
)
GLOBAL_DIRS = ("templates", "R")
ROOT_GLOBAL_SUFFIXES = (".sty", ".cls", ".tex")


def _rel(path: Path, root: Path) -> str:
    return path.relative_to(root).as_posix()


def _iter_existing_files(root: Path, paths: list[Path]) -> list[Path]:
    return sorted({path for path in paths if path.is_file()}, key=lambda p: _rel(p, root))


def global_input_files(root: Path) -> list[Path]:
    files: list[Path] = [root / rel for rel in GLOBAL_FILES]
    for dirname in GLOBAL_DIRS:
        base = root / dirname
        if base.exists():
            files.extend(path for path in base.rglob("*") if path.is_file())
    files.extend(
        path
        for path in root.iterdir()
        if path.is_file() and path.suffix.lower() in ROOT_GLOBAL_SUFFIXES
    )
    return _iter_existing_files(root, files)


def support_input_files(root: Path) -> list[Path]:
    bank = root / "BancoDeQuestoes"
    if not bank.exists():
        return []
    return _iter_existing_files(
        root,
        [
            path
            for path in bank.rglob("*")
            if path.is_file() and path.suffix.lower() != ".rnw"
        ],
    )


def hash_files(root: Path, files: list[Path]) -> str:
    """Hash both relative paths and bytes in deterministic order."""
    digest = hashlib.sha256()
    for path in files:
        rel = _rel(path, root).encode("utf-8")
        digest.update(len(rel).to_bytes(8, "big"))
        digest.update(rel)
        data = path.read_bytes()
        digest.update(len(data).to_bytes(8, "big"))
        digest.update(data)
    return digest.hexdigest()


def fingerprint_question(
    root: Path,
    question: str,
    environment_fingerprint: str,
    global_hash: str | None = None,
    support_hash: str | None = None,
) -> str:
    question_path = root / question
    if not question_path.is_file():
        raise FileNotFoundError(f"Question not found: {question}")
    if question_path.suffix.lower() != ".rnw":
        raise ValueError(f"Not an .Rnw question: {question}")

    if global_hash is None:
        global_hash = hash_files(root, global_input_files(root))
    if support_hash is None:
        support_hash = hash_files(root, support_input_files(root))

    digest = hashlib.sha256()
    for label, value in (
        ("schema", SCHEMA_VERSION),
        ("environment", environment_fingerprint),
        ("global", global_hash),
        ("support", support_hash),
        ("question-path", question),
    ):
        encoded = f"{label}\0{value}".encode("utf-8")
        digest.update(len(encoded).to_bytes(8, "big"))
        digest.update(encoded)

    question_bytes = question_path.read_bytes()
    digest.update(len(question_bytes).to_bytes(8, "big"))
    digest.update(question_bytes)
    return digest.hexdigest()


def fingerprint_questions(
    root: Path, questions: list[str], environment_fingerprint: str
) -> list[tuple[str, str]]:
    global_hash = hash_files(root, global_input_files(root))
    support_hash = hash_files(root, support_input_files(root))
    return [
        (
            question,
            fingerprint_question(
                root,
                question,
                environment_fingerprint,
                global_hash=global_hash,
                support_hash=support_hash,
            ),
        )
        for question in questions
    ]


def read_manifest(path: Path) -> list[str]:
    return [line.strip().replace("\\", "/") for line in path.read_text(encoding="utf-8").splitlines() if line.strip()]


def write_tsv(path: Path, rows: list[tuple[str, str]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.writer(handle, delimiter="\t", lineterminator="\n")
        writer.writerow(("question", "fingerprint"))
        writer.writerows(rows)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--repo-root", default=".")
    parser.add_argument("--manifest", required=True)
    parser.add_argument("--output", required=True)
    parser.add_argument("--environment", required=True)
    args = parser.parse_args()

    root = Path(args.repo_root).resolve()
    questions = read_manifest(Path(args.manifest))
    rows = fingerprint_questions(root, questions, args.environment)
    write_tsv(Path(args.output), rows)
    print(
        f"Compile-cache fingerprints: {len(rows)} question(s); "
        f"schema={SCHEMA_VERSION}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
