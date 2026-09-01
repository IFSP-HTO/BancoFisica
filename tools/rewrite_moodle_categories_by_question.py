#!/usr/bin/env python3
"""Reescreve categorias de um Moodle XML para uma categoria por questao-base.

Uso principal: pacotes com varias replicas Rxxx de cada fonte Qxx. O script
remove categorias emitidas por exsection e insere uma categoria deterministica
antes de cada grupo Q, evitando que fontes diferentes caiam na mesma categoria
no Moodle.
"""

from __future__ import annotations

import argparse
import re
from pathlib import Path

QUESTION_BLOCK = re.compile(r'(<question type="[^"]+">.*?</question>\s*)', re.S)
NAME_Q = re.compile(r'<name>\s*<text>\s*R\d+\s+Q(\d+)\s*:', re.S)


def category_block(prefix: str, q: int) -> str:
    return (
        '<question type="category">\n'
        '<category>\n'
        f'<text>$course$/{prefix}/Questão {q:02d}</text>\n'
        '</category>\n'
        '</question>\n\n'
    )


def rewrite(path: Path, prefix: str, expected_variants: int | None) -> None:
    text = path.read_text(encoding="utf-8")
    parts = QUESTION_BLOCK.split(text)
    out: list[str] = []
    current_q: int | None = None
    counts: dict[int, int] = {}

    for part in parts:
        if not part.startswith('<question type='):
            out.append(part)
            continue

        if '<question type="category">' in part:
            continue

        match = NAME_Q.search(part)
        if match:
            q = int(match.group(1))
            if q != current_q:
                out.append(category_block(prefix, q))
                current_q = q
            counts[q] = counts.get(q, 0) + 1

        out.append(part)

    if not counts:
        raise RuntimeError(f"Nenhuma variante R... Q... encontrada em {path}")

    if expected_variants is not None:
        bad = {q: n for q, n in counts.items() if n != expected_variants}
        if bad:
            raise RuntimeError(
                f"Quantidade inesperada de variantes em {path}: {bad}; "
                f"esperado {expected_variants} por Q"
            )

    rewritten = ''.join(out)
    for q in counts:
        marker = f'<text>$course$/{prefix}/Questão {q:02d}</text>'
        if rewritten.count(marker) != 1:
            raise RuntimeError(f"Categoria Q{q:02d} ausente ou duplicada em {path}")

    path.write_text(rewritten, encoding="utf-8")
    print(f"{path}: {len(counts)} categorias Q, {sum(counts.values())} variantes")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("files", nargs="+", type=Path)
    parser.add_argument("--prefix", default="MHS Halliday")
    parser.add_argument("--expected-variants", type=int, default=None)
    args = parser.parse_args()

    for path in args.files:
        rewrite(path, args.prefix, args.expected_variants)


if __name__ == "__main__":
    main()
