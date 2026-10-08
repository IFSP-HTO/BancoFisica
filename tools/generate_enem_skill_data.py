#!/usr/bin/env python3
"""Generate the public ENEM CN skill-summary JSON from canonical metadata."""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path


def fail(message: str) -> None:
    print(f"ERROR: {message}", file=sys.stderr)
    raise SystemExit(1)


def load_json(path: Path) -> dict:
    try:
        with path.open("r", encoding="utf-8") as handle:
            data = json.load(handle)
    except FileNotFoundError:
        fail(f"file not found: {path}")
    except json.JSONDecodeError as error:
        fail(f"invalid JSON in {path}: {error}")
    if not isinstance(data, dict):
        fail(f"{path} must contain an object")
    return data


def validate(data: dict) -> None:
    metadata = data.get("metadata")
    if not isinstance(metadata, dict):
        fail("metadata must be an object")
    for field in ("project", "area", "description", "sourceLabel", "sourceUrl"):
        if not isinstance(metadata.get(field), str) or not metadata[field].strip():
            fail(f"metadata.{field} must be a non-empty string")

    skills = data.get("skills")
    if not isinstance(skills, list) or len(skills) != 30:
        fail("skills must contain exactly 30 entries")

    expected = {f"H{i}" for i in range(1, 31)}
    seen: set[str] = set()
    for index, skill in enumerate(skills):
        if not isinstance(skill, dict):
            fail(f"skills[{index}] must be an object")
        code = skill.get("code")
        if not isinstance(code, str) or not re.fullmatch(r"H(?:[1-9]|[12][0-9]|30)", code):
            fail(f"skills[{index}].code is invalid")
        if code in seen:
            fail(f"duplicated skill code: {code}")
        seen.add(code)

        competency = skill.get("competency")
        if not isinstance(competency, int) or not 1 <= competency <= 8:
            fail(f"skills[{index}].competency must be 1..8")

        label = skill.get("label")
        if not isinstance(label, str) or not label.strip():
            fail(f"skills[{index}].label must be a non-empty string")
        if len(label) > 90:
            fail(f"skills[{index}].label is too long for the public UI")

    if seen != expected:
        missing = sorted(expected - seen)
        extra = sorted(seen - expected)
        fail(f"skill code mismatch; missing={missing}, extra={extra}")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--source",
        default="metadata/enem/cn_habilidades_resumo.json",
    )
    parser.add_argument(
        "--output",
        default="site/data/enem-habilidades-cn.json",
    )
    args = parser.parse_args()

    source = Path(args.source)
    output = Path(args.output)

    data = load_json(source)
    validate(data)

    output.parent.mkdir(parents=True, exist_ok=True)
    with output.open("w", encoding="utf-8") as handle:
        json.dump(data, handle, ensure_ascii=False, indent=2)
        handle.write("\n")

    print(f"Generated {output} with {len(data['skills'])} ENEM CN skill summaries.")


if __name__ == "__main__":
    main()
