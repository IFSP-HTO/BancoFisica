#!/usr/bin/env python3
"""Validate public-site artifacts for BancoFisica.

This script is intentionally conservative: the public site must contain only
explicit demo data and must not expose private bank paths, Rnw sources, Moodle
XML exports, or non-demo visibility levels.
"""

from __future__ import annotations

import json
import sys
from pathlib import Path
from typing import Any

REQUIRED_FILES = (
    Path("README.md"),
    Path("docs/politica-visibilidade-site.md"),
    Path("site/index.html"),
    Path("site/questoes.html"),
    Path("site/documentacao.html"),
    Path("site/visibilidade.html"),
    Path("site/js/app.js"),
    Path("site/data/questoes-demo-source.json"),
    Path("site/data/questoes-demo.json"),
    Path("tools/generate_demo_site_data.py"),
)

PUBLIC_TEXT_FILES = (
    "*.html",
    "*.css",
    "*.js",
    "*.json",
)

FORBIDDEN_PUBLIC_TOKENS = (
    "BancoDeQuestoes",
    ".Rnw",
    "exams2moodle",
    "exsolution",
    "visibility=private",
    "visibility=internal",
    '"visibility": "private"',
    '"visibility": "internal"',
)

REQUIRED_QUESTION_FIELDS = (
    "id",
    "title",
    "area",
    "subject",
    "level",
    "visibility",
    "tags",
    "statementHtml",
    "solutionHtml",
)


def fail(message: str) -> None:
    print(f"ERROR: {message}", file=sys.stderr)
    raise SystemExit(1)


def load_json(path: Path) -> dict[str, Any]:
    try:
        with path.open("r", encoding="utf-8") as handle:
            data = json.load(handle)
    except FileNotFoundError:
        fail(f"missing JSON file: {path}")
    except json.JSONDecodeError as error:
        fail(f"invalid JSON in {path}: {error}")
    if not isinstance(data, dict):
        fail(f"{path} must contain a JSON object")
    return data


def assert_required_files() -> None:
    for path in REQUIRED_FILES:
        if not path.exists():
            fail(f"required public/workflow file is missing: {path}")


def assert_demo_catalog(path: Path) -> None:
    catalog = load_json(path)
    metadata = catalog.get("metadata")
    if not isinstance(metadata, dict):
        fail(f"{path}: metadata must be an object")
    policy = str(metadata.get("visibilityPolicy", ""))
    if "demo" not in policy:
        fail(f"{path}: metadata.visibilityPolicy must explicitly mention demo visibility")

    questions = catalog.get("questions")
    if not isinstance(questions, list) or not questions:
        fail(f"{path}: questions must be a non-empty list")

    seen: set[str] = set()
    for index, question in enumerate(questions):
        if not isinstance(question, dict):
            fail(f"{path}: questions[{index}] must be an object")
        for field in REQUIRED_QUESTION_FIELDS:
            if field not in question:
                fail(f"{path}: questions[{index}] missing field {field!r}")
        question_id = question["id"]
        if not isinstance(question_id, str) or not question_id.startswith("DEMO-"):
            fail(f"{path}: questions[{index}].id must start with DEMO-")
        if question_id in seen:
            fail(f"{path}: duplicated question id {question_id}")
        seen.add(question_id)
        if question.get("visibility") != "demo":
            fail(f"{path}: questions[{index}] is not visibility='demo'")
        tags = question.get("tags")
        if not isinstance(tags, list) or not tags or not all(isinstance(tag, str) and tag for tag in tags):
            fail(f"{path}: questions[{index}].tags must be a non-empty list of strings")
        for html_field in ("statementHtml", "solutionHtml"):
            value = question.get(html_field)
            if not isinstance(value, str) or "<" not in value or ">" not in value:
                fail(f"{path}: questions[{index}].{html_field} must contain HTML")


def assert_generated_matches_source() -> None:
    source = load_json(Path("site/data/questoes-demo-source.json"))
    generated = load_json(Path("site/data/questoes-demo.json"))
    if source != generated:
        fail("site/data/questoes-demo.json is not synchronized with questoes-demo-source.json")


def iter_public_files() -> list[Path]:
    files: list[Path] = []
    root = Path("site")
    for pattern in PUBLIC_TEXT_FILES:
        files.extend(root.rglob(pattern))
    return sorted(set(files))


def assert_no_private_tokens() -> None:
    for path in iter_public_files():
        text = path.read_text(encoding="utf-8")
        for token in FORBIDDEN_PUBLIC_TOKENS:
            if token in text:
                fail(f"forbidden token {token!r} found in public file {path}")


def assert_site_references_demo_json() -> None:
    app = Path("site/js/app.js").read_text(encoding="utf-8")
    if "data/questoes-demo.json" not in app:
        fail("site/js/app.js must load data/questoes-demo.json")
    if "visibility === 'demo'" not in app:
        fail("site/js/app.js must filter public questions by visibility === 'demo'")


def main() -> None:
    assert_required_files()
    assert_generated_matches_source()
    assert_demo_catalog(Path("site/data/questoes-demo-source.json"))
    assert_demo_catalog(Path("site/data/questoes-demo.json"))
    assert_no_private_tokens()
    assert_site_references_demo_json()
    print("Public site validation passed.")


if __name__ == "__main__":
    main()
