#!/usr/bin/env python3
"""Padroniza o XML Moodle das listas de lançamento oblíquo de setembro/2026.

Cada questão-base recebe uma categoria própria Q01, Q02, ... e cada variante
fica nomeada Qxx-Ryyy. Assim as novas questões não se misturam entre si nem
com as categorias históricas de lançamento oblíquo do BancoFisica.
"""
from __future__ import annotations
import argparse, re
from pathlib import Path

BLOCK = re.compile(r'(<question type="[^"]+">.*?</question>\s*)', re.S)
NAME = re.compile(r'<name>\s*<text>\s*R(\d+)\s+Q(\d+)\s*:[^<]*</text>\s*</name>', re.S)

def cat(prefix: str, q: int) -> str:
    return (
        '<question type="category">\n<category>\n'
        f'<text>$course$/{prefix}/Q{q:02d}</text>\n'
        '</category>\n</question>\n\n'
    )

def rewrite(path: Path, prefix: str, expected: int | None) -> None:
    text = path.read_text(encoding='utf-8')
    parts = BLOCK.split(text)
    out: list[str] = []
    current_q = None
    counts: dict[int,int] = {}

    for part in parts:
        if not part.startswith('<question type='):
            out.append(part); continue
        if '<question type="category">' in part:
            continue
        m = NAME.search(part)
        if not m:
            out.append(part); continue
        r, q = int(m.group(1)), int(m.group(2))
        if q != current_q:
            out.append(cat(prefix, q)); current_q = q
        counts[q] = counts.get(q,0)+1
        replacement = f'<name>\n<text>Q{q:02d}-R{r:03d}</text>\n</name>'
        part = NAME.sub(replacement, part, count=1)
        out.append(part)

    if not counts:
        raise RuntimeError(f'Nenhuma variante R... Q... encontrada em {path}')
    if expected is not None:
        bad={q:n for q,n in counts.items() if n != expected}
        if bad:
            raise RuntimeError(f'Número inesperado de variantes em {path}: {bad}; esperado {expected}')
    result=''.join(out)
    for q in counts:
        marker=f'<text>$course$/{prefix}/Q{q:02d}</text>'
        if result.count(marker) != 1:
            raise RuntimeError(f'Categoria Q{q:02d} ausente ou duplicada em {path}')
    path.write_text(result,encoding='utf-8')
    print(f'{path}: {len(counts)} questões-base, {sum(counts.values())} variantes')

def main():
    ap=argparse.ArgumentParser()
    ap.add_argument('files', nargs='+', type=Path)
    ap.add_argument('--prefix', required=True)
    ap.add_argument('--expected-variants', type=int)
    a=ap.parse_args()
    for f in a.files: rewrite(f,a.prefix,a.expected_variants)
if __name__=='__main__': main()
