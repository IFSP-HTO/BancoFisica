#!/usr/bin/env python3
"""Generate the public demo question catalog for the BancoFisica site.

The generator is intentionally conservative: it only exports questions marked
explicitly with visibility = "demo". This keeps the public site aligned with the
visibility policy documented in docs/politica-visibilidade-site.md.
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Any

REQUIRED_STRING_FIELDS = (
    "id",
    "title",
    "area",
    "subject",
    "level",
    "visibility",
    "statementHtml",
    "solutionHtml",
)


def fail(message: str) -> None:
    print(f"ERROR: {message}", file=sys.stderr)
    raise SystemExit(1)


def require_object(value: Any, context: str) -> dict[str, Any]:
    if not isinstance(value, dict):
        fail(f"{context} must be a JSON object")
    return value


def require_string(value: Any, context: str) -> str:
    if not isinstance(value, str) or not value.strip():
        fail(f"{context} must be a non-empty string")
    return value


def validate_question(question: dict[str, Any], index: int) -> None:
    prefix = f"questions[{index}]"

    for field in REQUIRED_STRING_FIELDS:
        require_string(question.get(field), f"{prefix}.{field}")

    if question["visibility"] != "demo":
        fail(
            f"{prefix} has visibility={question['visibility']!r}; "
            "only visibility='demo' may be exported to the public site"
        )

    tags = question.get("tags")
    if not isinstance(tags, list) or not tags:
        fail(f"{prefix}.tags must be a non-empty list")

    for tag_index, tag in enumerate(tags):
        require_string(tag, f"{prefix}.tags[{tag_index}]")



def validate_catalog(catalog: dict[str, Any]) -> None:
    metadata = require_object(catalog.get("metadata"), "metadata")
    require_string(metadata.get("project"), "metadata.project")
    require_string(metadata.get("description"), "metadata.description")
    require_string(metadata.get("visibilityPolicy"), "metadata.visibilityPolicy")

    questions = catalog.get("questions")
    if not isinstance(questions, list) or not questions:
        fail("questions must be a non-empty list")

    seen_ids: set[str] = set()
    for index, question_value in enumerate(questions):
        question = require_object(question_value, f"questions[{index}]")
        validate_question(question, index)
        question_id = question["id"]
        if question_id in seen_ids:
            fail(f"duplicated question id: {question_id}")
        seen_ids.add(question_id)



def load_json(path: Path) -> dict[str, Any]:
    try:
        with path.open("r", encoding="utf-8") as handle:
            return require_object(json.load(handle), str(path))
    except FileNotFoundError:
        fail(f"file not found: {path}")
    except json.JSONDecodeError as error:
        fail(f"invalid JSON in {path}: {error}")


def write_json(path: Path, data: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8") as handle:
        json.dump(data, handle, ensure_ascii=False, indent=2)
        handle.write("\n")


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Generate site/data/questoes-demo.json from a validated demo source."
    )
    parser.add_argument(
        "--source",
        default="site/data/questoes-demo-source.json",
        help="source JSON with explicitly public demo questions",
    )
    parser.add_argument(
        "--output",
        default="site/data/questoes-demo.json",
        help="generated JSON consumed by the public site",
    )
    args = parser.parse_args()

    source_path = Path(args.source)
    output_path = Path(args.output)

    catalog = load_json(source_path)
    validate_catalog(catalog)
    write_json(output_path, catalog)

    print(
        f"Generated {output_path} from {source_path} "
        f"with {len(catalog['questions'])} demo questions."
    )


if __name__ == "__main__":
    main()
