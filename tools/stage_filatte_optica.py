#!/usr/bin/env python3
"""Estagia questoes de Optica em lote, preservando PNGs integrais da fonte.

Nao publica .Rnw neste primeiro passo. Um profissional confere os visuais,
gabaritos e a transcricao antes de aprovar cada crop e solucao comentada.
"""
from __future__ import annotations
import argparse
import hashlib
import json
import re
import time
from pathlib import Path
from urllib.parse import urljoin, urlparse

import requests
from bs4 import BeautifulSoup
from PIL import Image
from io import BytesIO

ROOT = Path(__file__).resolve().parents[1]
ALLOWED_SITE = "provas.professorfilatte.com.br"
ALLOWED_IMAGE_HOST = "wdlpxyudndyrkigvupfy.supabase.co"
HEADERS = {"User-Agent": "BancoFisica educational importer/1.0"}


def read_html(session, url):
    if urlparse(url).hostname != ALLOWED_SITE:
        raise ValueError("Dominio de fonte incorreto")
    response = session.get(url, timeout=35)
    response.raise_for_status()
    return response.text


def parse_html(html, url):
    soup = BeautifulSoup(html, "html.parser")
    h1 = soup.find("h1")
    if not h1:
        raise ValueError("Nao foi encontrado H1")
    title = h1.get_text(" ", strip=True)
    if "Física" not in title:
        raise ValueError("A pagina nao e de Fisica")
    heading = next((h for h in soup.select("h2") if "Enunciado em texto" in h.get_text(" ", strip=True)), None)
    if heading is None:
        raise ValueError("Secao de transcricao nao encontrada")
    blocks = []
    for node in heading.next_elements:
        if getattr(node, "name", None) == "h2" and node is not heading:
            break
        if getattr(node, "name", None) in ("p", "li"):
            # A pagina pode conter duplicatas MathML/TeX que exigem revisao
            blocks.append(node.get_text(" ", strip=True))
    source_text = "\n".join(t for t in blocks if t)
    if len(source_text) < 60:
        raise ValueError("Transcricao suspeita")
    header = soup.get_text(" ", strip=True)
    match = re.search(r"Gabarito\s+([A-E])\b", header, re.I)
    if not match:
        raise ValueError("Gabarito nao encontrado")
    correct = match.group(1).upper()
    patt = re.compile(r"(?m)^\s*\(?([A-E])\)\s*")
    found = list(patt.finditer(source_text))
    alternatives = {}
    if found:
        letters = [m.group(1).upper() for m in found]
        if letters != list("ABCDE") and letters != list("ABCD"):
            raise ValueError("Alternativas fora de sequencia: " + repr(letters))
        for i, m in enumerate(found):
            end = found[i+1].start() if i+1 < len(found) else len(source_text)
            alternatives[m.group(1)] = source_text[m.end():end].strip()
        alternatives[letters[-1]] = re.split(
            r"\n\(Enunciado(?: e figura)?:|\nTranscri[cç][aã]o", alternatives[letters[-1]]
        )[0].strip()
    if alternatives and correct not in alternatives:
        raise ValueError("Gabarito nao consta entre as alternativas")
    visual = soup.find("img", alt=re.compile(r"Enunciado da quest[aã]o", re.I))
    if visual is None:
        raise ValueError("Imagem original da pagina nao localizada")
    img_url = urljoin(url, visual.get("src", ""))
    if urlparse(img_url).hostname != ALLOWED_IMAGE_HOST:
        raise ValueError("Host da imagem nao permitido")
    return dict(url=url, title=title, correct=correct, transcription=source_text,
                alternatives=alternatives, source_image_url=img_url,
                requires_visual=bool(re.search(r"\[(?:Figura|Diagrama|Gr[aá]fico|Tabela)\b", source_text, re.I)))


def stage(session, item, outdir):
    metadata = parse_html(read_html(session, item["url"]), item["url"])
    if item.get("correct") and metadata["correct"] != item["correct"]:
        raise ValueError("Divergencia de gabarito para " + item["id"])
    response = session.get(metadata["source_image_url"], timeout=40)
    response.raise_for_status()
    raw = response.content
    with Image.open(BytesIO(raw)) as image:
        image.verify()
    with Image.open(BytesIO(raw)) as image:
        width, height = image.size
        fmt = image.format
    if width < 150 or height < 100 or len(raw) < 700 or fmt != "PNG":
        raise ValueError("Imagem invalida/pequena para " + item["id"])
    target = outdir / "source"
    target.mkdir(parents=True, exist_ok=True)
    path = target / (item["id"] + ".png")
    path.write_bytes(raw)  # Bytes exatos, sem recompressao.
    metadata.update(id=item["id"], tags=item.get("tags", []), width=width, height=height,
                    sha256=hashlib.sha256(raw).hexdigest(), image_bytes=len(raw),
                    path=str(path.relative_to(outdir)), status="pending_visual_review")
    return metadata


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--manifest", default="data/filatte-optica-piloto.json")
    parser.add_argument("--out-dir", default="build/filatte-stage")
    args = parser.parse_args()
    manifest = json.loads((ROOT / args.manifest).read_text(encoding="utf-8"))
    outdir = ROOT / args.out_dir
    outdir.mkdir(parents=True, exist_ok=True)
    results = []
    session = requests.Session()
    session.headers.update(HEADERS)
    for i, item in enumerate(manifest["questions"], 1):
        print(f"[{i}/{len(manifest['questions'])}] {item['id']}", flush=True)
        try:
            result = stage(session, item, outdir)
            print("  OK", result["width"], result["height"], result["correct"], flush=True)
        except Exception as err:
            result = {"id":item["id"], "url":item["url"], "status":"blocked",
                      "error":type(err).__name__ + ": " + str(err)}
            print("  BLOQUEADA", result["error"], flush=True)
        results.append(result)
        time.sleep(0.4)
    report = {"total":len(results), "staged":sum(r["status"] != "blocked" for r in results),
              "blocked":sum(r["status"] == "blocked" for r in results), "items":results}
    (outdir / "manifest.json").write_text(json.dumps(report, indent=2, ensure_ascii=False), encoding="utf-8")
    print(json.dumps({"total": report["total"],"staged":report["staged"],"blocked":report["blocked"]}))
    if report["blocked"]:
        raise SystemExit(2)


if __name__ == "__main__":
    main()
