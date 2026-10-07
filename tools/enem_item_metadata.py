#!/usr/bin/env python3
"""Match BancoFisica ENEM-source questions to INEP ITENS_PROVA metadata.

The script never reads participant microdata. It only consumes ITENS_PROVA_<year>.csv
from an extracted microdata directory or from the official INEP ZIP archive.
"""

from __future__ import annotations

import argparse
import csv
import io
import sys
import zipfile
from pathlib import Path

OUTPUT_FIELDS = [
    "bank_path",
    "relation",
    "adaptation_kind",
    "source_year",
    "source_application",
    "source_caderno",
    "source_color",
    "source_question_number",
    "source_position",
    "source_co_prova",
    "co_item",
    "sg_area",
    "co_habilidade",
    "tx_gabarito",
    "in_item_aban",
    "tx_motivo_aban",
    "nu_param_a",
    "nu_param_b",
    "nu_param_c",
    "match_status",
    "notes",
]

INEP_COPY_FIELDS = {
    "CO_ITEM": "co_item",
    "SG_AREA": "sg_area",
    "CO_HABILIDADE": "co_habilidade",
    "TX_GABARITO": "tx_gabarito",
    "IN_ITEM_ABAN": "in_item_aban",
    "TX_MOTIVO_ABAN": "tx_motivo_aban",
    "NU_PARAM_A": "nu_param_a",
    "NU_PARAM_B": "nu_param_b",
    "NU_PARAM_C": "nu_param_c",
}


def clean(value: object) -> str:
    return "" if value is None else str(value).strip()


def normalize_color(value: object) -> str:
    text = clean(value).upper()
    translations = str.maketrans("ÁÀÂÃÉÊÍÓÔÕÚÇ", "AAAAEEIOOOUC")
    text = text.translate(translations)
    aliases = {
        "AMARELO": "AMARELA",
        "AMARELA": "AMARELA",
        "BRANCO": "BRANCA",
        "BRANCA": "BRANCA",
        "ROXO": "ROXA",
        "ROXA": "ROXA",
    }
    return aliases.get(text, text)


def read_delimited_bytes(data: bytes) -> list[dict[str, str]]:
    last_error: Exception | None = None
    for encoding in ("utf-8-sig", "latin-1"):
        try:
            text = data.decode(encoding)
            first = text.splitlines()[0] if text.splitlines() else ""
            delimiter = ";" if first.count(";") >= first.count(",") else ","
            return list(csv.DictReader(io.StringIO(text), delimiter=delimiter))
        except UnicodeDecodeError as exc:
            last_error = exc
    raise ValueError(f"Could not decode CSV: {last_error}")


def find_item_member(names: list[str], year: int) -> str:
    target = f"ITENS_PROVA_{year}.csv".lower()
    matches = [name for name in names if name.lower().endswith(target)]
    if len(matches) != 1:
        raise ValueError(
            f"Expected exactly one {target} in source; found {len(matches)}: {matches}"
        )
    return matches[0]


def load_inep_items(source: Path, year: int) -> list[dict[str, str]]:
    if source.is_dir():
        matches = [p for p in source.rglob(f"ITENS_PROVA_{year}.csv")]
        if len(matches) != 1:
            raise ValueError(
                f"Expected exactly one ITENS_PROVA_{year}.csv below {source}; "
                f"found {len(matches)}"
            )
        return read_delimited_bytes(matches[0].read_bytes())

    if source.suffix.lower() == ".zip":
        with zipfile.ZipFile(source) as zf:
            member = find_item_member(zf.namelist(), year)
            return read_delimited_bytes(zf.read(member))

    if source.is_file() and source.name.lower() == f"itens_prova_{year}.csv".lower():
        return read_delimited_bytes(source.read_bytes())

    raise ValueError(f"Unsupported source for {year}: {source}")


def load_inventory(path: Path) -> list[dict[str, str]]:
    rows = read_delimited_bytes(path.read_bytes())
    missing = [field for field in OUTPUT_FIELDS if field not in (rows[0] if rows else {})]
    if missing:
        raise ValueError(f"Inventory missing fields: {', '.join(missing)}")
    return rows


def unique_by_item(rows: list[dict[str, str]]) -> list[dict[str, str]]:
    """Collapse repeated appearances of the same calibrated item across booklets.

    The same CO_ITEM may occur in more than one CO_PROVA and at different positions.
    For matching purposes the item identity, not the booklet copy, is what matters.
    """
    seen: set[str] = set()
    out: list[dict[str, str]] = []
    for row in rows:
        key = clean(row.get("CO_ITEM"))
        if key not in seen:
            seen.add(key)
            out.append(row)
    return out


def candidates(inv: dict[str, str], items: list[dict[str, str]]) -> list[dict[str, str]]:
    result = items

    if clean(inv.get("co_item")):
        result = [r for r in result if clean(r.get("CO_ITEM")) == clean(inv["co_item"])]
    else:
        if clean(inv.get("source_co_prova")):
            result = [
                r for r in result
                if clean(r.get("CO_PROVA")) == clean(inv["source_co_prova"])
            ]
        if clean(inv.get("source_position")):
            result = [
                r for r in result
                if clean(r.get("CO_POSICAO")) == clean(inv["source_position"])
            ]
        if clean(inv.get("source_color")):
            wanted = normalize_color(inv["source_color"])
            result = [
                r for r in result
                if normalize_color(r.get("TX_COR")) == wanted
            ]

    if any("SG_AREA" in r for r in result):
        result = [r for r in result if clean(r.get("SG_AREA")).upper() == "CN"]

    return unique_by_item(result)


def merge_match(inv: dict[str, str], item: dict[str, str]) -> dict[str, str]:
    out = {field: clean(inv.get(field)) for field in OUTPUT_FIELDS}
    for inep, dest in INEP_COPY_FIELDS.items():
        value = clean(item.get(inep))
        if value:
            out[dest] = value
    out["match_status"] = "matched"
    return out


def match_inventory(
    inventory: list[dict[str, str]],
    source_by_year: dict[int, Path],
) -> tuple[list[dict[str, str]], list[str]]:
    cache: dict[int, list[dict[str, str]]] = {}
    output: list[dict[str, str]] = []
    messages: list[str] = []

    for inv in inventory:
        year_text = clean(inv.get("source_year"))
        if not year_text:
            row = {field: clean(inv.get(field)) for field in OUTPUT_FIELDS}
            row["match_status"] = row["match_status"] or "missing_year"
            output.append(row)
            continue

        year = int(year_text)
        row = {field: clean(inv.get(field)) for field in OUTPUT_FIELDS}

        if year < 2009:
            row["match_status"] = "pre_tri"
            output.append(row)
            continue

        source = source_by_year.get(year)
        if source is None:
            row["match_status"] = "missing_microdata"
            output.append(row)
            continue

        if year not in cache:
            cache[year] = load_inep_items(source, year)

        found = candidates(row, cache[year])
        if len(found) == 1:
            output.append(merge_match(row, found[0]))
        elif len(found) == 0:
            row["match_status"] = "no_match"
            output.append(row)
            messages.append(f"NO MATCH: {row['bank_path']}")
        else:
            row["match_status"] = "ambiguous"
            output.append(row)
            summary = ", ".join(
                f"CO_ITEM={clean(r.get('CO_ITEM'))}/CO_PROVA={clean(r.get('CO_PROVA'))}"
                f"/COR={clean(r.get('TX_COR'))}/POS={clean(r.get('CO_POSICAO'))}"
                for r in found[:12]
            )
            messages.append(f"AMBIGUOUS: {row['bank_path']}: {summary}")

    return output, messages


def validate_inventory(rows: list[dict[str, str]], repo_root: Path | None = None) -> list[str]:
    errors: list[str] = []
    seen_paths: set[str] = set()

    for idx, row in enumerate(rows, start=2):
        bank_path = clean(row.get("bank_path"))
        if not bank_path:
            errors.append(f"line {idx}: empty bank_path")
        elif bank_path in seen_paths:
            errors.append(f"line {idx}: duplicate bank_path: {bank_path}")
        seen_paths.add(bank_path)

        relation = clean(row.get("relation"))
        if relation not in {"direct", "inspired"}:
            errors.append(f"line {idx}: invalid relation {relation!r}")

        year = clean(row.get("source_year"))
        if year and (not year.isdigit() or not 1998 <= int(year) <= 2100):
            errors.append(f"line {idx}: invalid source_year {year!r}")

        if repo_root is not None and bank_path and not (repo_root / bank_path).is_file():
            errors.append(f"line {idx}: missing bank file: {bank_path}")

        for field in ("nu_param_a", "nu_param_b", "nu_param_c"):
            value = clean(row.get(field))
            if value:
                try:
                    float(value.replace(",", "."))
                except ValueError:
                    errors.append(f"line {idx}: {field} is not numeric: {value!r}")

    return errors


def write_inventory(path: Path, rows: list[dict[str, str]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8", newline="") as fh:
        writer = csv.DictWriter(fh, fieldnames=OUTPUT_FIELDS)
        writer.writeheader()
        writer.writerows({field: clean(row.get(field)) for field in OUTPUT_FIELDS} for row in rows)


def parse_sources(values: list[str]) -> dict[int, Path]:
    result: dict[int, Path] = {}
    for value in values:
        try:
            year_text, path_text = value.split("=", 1)
            result[int(year_text)] = Path(path_text)
        except ValueError as exc:
            raise ValueError(f"Use --source YEAR=PATH, got {value!r}") from exc
    return result


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--inventory",
        type=Path,
        default=Path("metadata/enem/banco_enem_itens.csv"),
    )
    parser.add_argument(
        "--repo-root",
        type=Path,
        default=Path("."),
        help="Repository root used when validating bank_path.",
    )
    sub = parser.add_subparsers(dest="command", required=True)

    sub.add_parser("validate")

    match = sub.add_parser("match")
    match.add_argument(
        "--source",
        action="append",
        default=[],
        metavar="YEAR=PATH",
        help="INEP microdata ZIP, extracted directory, or ITENS_PROVA CSV.",
    )
    match.add_argument("--output", type=Path, required=True)
    return parser


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    rows = load_inventory(args.inventory)

    errors = validate_inventory(rows, args.repo_root)
    if errors:
        print("\n".join(errors), file=sys.stderr)
        return 2

    if args.command == "validate":
        print(f"OK: {len(rows)} inventory rows")
        return 0

    sources = parse_sources(args.source)
    matched, messages = match_inventory(rows, sources)
    write_inventory(args.output, matched)
    for message in messages:
        print(message, file=sys.stderr)

    counts: dict[str, int] = {}
    for row in matched:
        status = row["match_status"]
        counts[status] = counts.get(status, 0) + 1
    print(" ".join(f"{key}={counts[key]}" for key in sorted(counts)))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
