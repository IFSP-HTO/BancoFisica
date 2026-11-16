#!/usr/bin/env python3
"""Valida os arquivos de imagem incorporados ao XML da Lista 2.

Testa identidade de cada PNG aprovado (SHA-256) além das referências
@@PLUGINFILE@@. A Lista 2 deve conter exatamente nove questões-base.
"""
import argparse
import base64
import hashlib
import json
import re
import xml.etree.ElementTree as ET
from collections import Counter
from pathlib import Path

APPROVED_MANIFEST = Path("data/lista2-imagens-aprovadas.json")
REQUIRED = {
    "Q05Densidade": "Q05Densidade.png",
    "Q105PascalForca": "Q105PascalForca.png",
    "Q106PascalDeslocamento": "Q106PascalDeslocamento.png",
    "Q109ClozeFracaoSubmersa": "Q109ClozeFracaoSubmersa.png",
    "Q02ClozeContinuidadeVazao": "Q02ClozeContinuidadeVazao.png",
    "Q03ClozeBernoulliReservatorio": "Q03ClozeBernoulliReservatorio.png",
}
TEXT_ONLY = {"Q93QuizDensidadeFlutuacao", "Q107EmpuxoVolume",
             "Q108PesoAparente"}
EXPECTED_BASES = set(REQUIRED) | TEXT_ONLY

def inspect(path, hashes):
    root = ET.parse(path).getroot()
    if root.tag != "quiz":
        raise ValueError("Raiz Moodle inválida: " + str(path))
    ret = []
    for q in root.findall("question"):
        if q.attrib.get("type") == "category":
            continue
        name = q.findtext("name/text", "").strip()
        match = re.search(r":\s*(Q\d+[A-Za-z0-9_]+)", name)
        if not match:
            raise ValueError("Nome de questão incompreensível: " + name)
        qid = match.group(1)
        content = q.findtext("questiontext/text", "")
        media = q.findall("questiontext/file")
        names = []
        for node in media:
            filename = node.attrib.get("name", "")
            if not filename or "@@PLUGINFILE@@/" + filename not in content:
                raise ValueError(f"Imagem {filename!r} não referenciada em {qid}")
            if node.attrib.get("encoding") != "base64":
                raise ValueError(f"Imagem {filename!r} sem codificação base64")
            raw = base64.b64decode(node.text or "", validate=False)
            if len(raw) < 200 or not raw.startswith(b"\x89PNG\r\n\x1a\n"):
                raise ValueError(f"Imagem {filename!r} inválida em {qid}")
            if qid in hashes and filename == REQUIRED[qid]:
                sha = hashlib.sha256(raw).hexdigest()
                if sha != hashes[qid]:
                    raise ValueError(f"Imagem de {qid} não corresponde ao PNG aprovado; SHA={sha}")
            names.append(filename)
        if qid in REQUIRED and REQUIRED[qid] not in names:
            raise ValueError(f"Figura obrigatória ausente em {qid}: {names}")
        if qid in TEXT_ONLY and names:
            raise ValueError(f"Figura inesperada na questão textual {qid}: {names}")
        if re.search(r'src="(?!@@PLUGINFILE@@|https?://)[^"]+\.png"', content):
            raise ValueError(f"Imagem com caminho não incorporado ao Moodle em {qid}")
        ret.append((qid, names))
    return ret

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("directory", type=Path)
    args = ap.parse_args()
    manifest = json.loads(APPROVED_MANIFEST.read_text(encoding="utf-8"))
    hashes = {x["question"]: x["sha256"] for x in manifest["images"]}
    for entry in manifest["images"]:
        raw = Path(entry["path"]).read_bytes()
        if len(raw) != entry["bytes"] or hashlib.sha256(raw).hexdigest() != entry["sha256"]:
            raise ValueError("Imagem do repositório alterada: " + entry["path"])
    xmls = sorted(args.directory.glob("hidrostatica-lista2-2ano*.xml"))
    if not xmls:
        raise SystemExit("XML da Lista 2 não encontrado")
    records = [x for path in xmls for x in inspect(path, hashes)]
    counter = Counter(q for q, _ in records)
    if set(counter) != EXPECTED_BASES:
        raise ValueError("Conjunto de questões inesperado: " + repr(counter))
    if len(set(counter.values())) != 1:
        raise ValueError("Número de réplicas irregular: " + repr(counter))
    print("Validação de imagens da Lista 2: OK")
    print("Questões-base:", len(counter), "Réplicas:", next(iter(counter.values())))
    for qid in sorted(counter):
        print(qid, "imagens:", sum(bool(names) for q, names in records if q == qid))
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
