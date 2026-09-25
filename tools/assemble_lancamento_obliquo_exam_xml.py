#!/usr/bin/env python3
"""Monta um único XML Moodle por turma a partir de 10 XMLs de questão-base.

Cada XML de entrada é gerado pelo R/exams para uma única questão com N réplicas.
O montador remove as categorias locais, renomeia as réplicas para Qxx-Ryyy e
cria exatamente uma categoria Q01,...,Q10 sob o prefixo da turma.

Nenhum dado de estudante é lido ou gravado.
"""
from __future__ import annotations

import argparse
import re
from pathlib import Path

BLOCK = re.compile(r'(<question type="[^"]+">.*?</question>\s*)', re.S)
NAME = re.compile(
    r'<name>\s*<text>\s*R(\d+)\s+Q(\d+)\s*:[^<]*</text>\s*</name>',
    re.S,
)
MAX_BYTES = 10 * 1024 * 1024


def category(prefix: str, q: int) -> str:
    return (
        '<question type="category">\n'
        '<category>\n'
        f'<text>$course$/{prefix}/Q{q:02d}</text>\n'
        '</category>\n'
        '</question>\n\n'
    )


def parse_mapping(value: str) -> tuple[int, Path]:
    try:
        left, right = value.split("=", 1)
        q = int(left)
    except Exception as exc:
        raise argparse.ArgumentTypeError(
            f"mapeamento inválido {value!r}; use N=caminho.xml"
        ) from exc
    if q < 1 or q > 99:
        raise argparse.ArgumentTypeError("número da questão fora do intervalo")
    return q, Path(right)


def strip_embedded_images(block: str) -> str:
    """Remove imagens incorporadas quando a figura é apenas ilustrativa."""
    block = re.sub(r'<img\\b[^>]*?/?>', '', block, flags=re.I)
    block = re.sub(
        r'<file\\b[^>]*>.*?</file>\\s*',
        '',
        block,
        flags=re.I | re.S,
    )
    return block


def variants_from(
    path: Path, q: int, expected: int, strip_images: bool = False
) -> list[str]:
    text = path.read_text(encoding="utf-8")
    out: list[str] = []

    for block in BLOCK.findall(text):
        if '<question type="category">' in block:
            continue
        m = NAME.search(block)
        if not m:
            continue
        r = int(m.group(1))
        replacement = f'<name>\n<text>Q{q:02d}-R{r:03d}</text>\n</name>'
        block = NAME.sub(replacement, block, count=1)
        if strip_images:
            block = strip_embedded_images(block)
        out.append(block)

    if len(out) != expected:
        raise RuntimeError(
            f"{path}: Q{q:02d} tem {len(out)} variantes; esperado {expected}"
        )

    names = []
    for block in out:
        m = re.search(r'<name>\s*<text>(Q\d{2}-R\d{3})</text>', block, re.S)
        if not m:
            raise RuntimeError(f"{path}: nome Qxx-Ryyy não encontrado após reescrita")
        names.append(m.group(1))
    if len(set(names)) != expected:
        raise RuntimeError(f"{path}: nomes de variantes duplicados em Q{q:02d}")

    return out


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--prefix", required=True)
    ap.add_argument("--expected-variants", type=int, default=50)
    ap.add_argument("--output", required=True, type=Path)
    ap.add_argument(
        "--strip-images",
        default="",
        help="lista de questões sem figuras, por exemplo 1,2,5",
    )
    ap.add_argument("mappings", nargs="+", type=parse_mapping)
    args = ap.parse_args()

    strip_images = {
        int(x) for x in args.strip_images.split(",") if x.strip()
    }
    mappings = sorted(args.mappings, key=lambda x: x[0])
    qs = [q for q, _ in mappings]
    if qs != list(range(1, 11)):
        raise SystemExit(f"esperadas as questões 1..10, recebidas {qs}")

    body: list[str] = []
    for q, path in mappings:
        body.append(category(args.prefix, q))
        body.extend(
            variants_from(
                path, q, args.expected_variants, strip_images=q in strip_images
            )
        )

    result = (
        '<?xml version="1.0" encoding="UTF-8"?>\n'
        '<quiz>\n\n'
        + "".join(body)
        + '</quiz>\n'
    )
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(result, encoding="utf-8")

    raw = args.output.read_bytes()
    if len(raw) > MAX_BYTES:
        args.output.unlink(missing_ok=True)
        raise RuntimeError(
            f"XML único excede 10 MiB ({len(raw)/1024**2:.2f} MiB): {args.output}"
        )

    text = raw.decode("utf-8")
    for q in range(1, 11):
        cat = f'<text>$course$/{args.prefix}/Q{q:02d}</text>'
        if text.count(cat) != 1:
            raise RuntimeError(f"categoria Q{q:02d} ausente ou duplicada")
        names = re.findall(
            rf'<name>\s*<text>Q{q:02d}-R\d{{3}}</text>',
            text,
            re.S,
        )
        if len(names) != args.expected_variants:
            raise RuntimeError(
                f"Q{q:02d}: {len(names)} variantes no XML final; "
                f"esperado {args.expected_variants}"
            )

    print(
        f"{args.output}: 10 categorias, "
        f"{10*args.expected_variants} variantes, {len(raw)/1024**2:.2f} MiB"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
