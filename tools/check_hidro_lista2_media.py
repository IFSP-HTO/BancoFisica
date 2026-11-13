#!/usr/bin/env python3
"""Audita se as figuras realmente chegaram a cada questão do XML Moodle.

Este teste protege contra 'compila mas não mostra imagem'. Ele não substitui
a inspeção visual das figuras, mas falha quando uma mídia esperada não está
embutida em seu respectivo item.
"""
import argparse
import base64
import re
import sys
import xml.etree.ElementTree as ET
from collections import Counter
from pathlib import Path

REQUIRED = {
    "Q05Densidade": "Q05Densidade.png",
    "Q105PascalForca": "Q105PascalForca_Filatte.png",
    "Q106PascalDeslocamento": "Q106PascalDeslocamento_Filatte.png",
    "Q107EmpuxoVolume": "Q107EmpuxoVolume_Filatte.png",
    "Q108PesoAparente": "Q108PesoAparente_Filatte.png",
    "Q109ClozeFracaoSubmersa": "Q109ClozeFracaoSubmersa_Filatte.png",
    "Q02ClozeContinuidadeVazao": None,   # plot do R/exams
    "Q03ClozeBernoulliReservatorio": None,  # plot do R/exams
}
EXPECTED_BASES = set(REQUIRED) | {"Q93QuizDensidadeFlutuacao"}

def inspect(path):
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
            raise ValueError("Nome da questão incompreensível: " + name)
        qid = match.group(1)
        text = q.findtext("questiontext/text", "")
        media = q.findall("questiontext/file")
        names = []
        for node in media:
            filename = node.attrib.get("name", "")
            if not filename or "@@PLUGINFILE@@/" + filename not in text:
                raise ValueError(f"Arquivo {filename!r} não referenciado no enunciado de {qid}")
            if node.attrib.get("encoding") != "base64":
                raise ValueError(f"Arquivo {filename!r} não codificado em base64")
            raw = base64.b64decode(node.text or "", validate=False)
            if len(raw) < 200:
                raise ValueError(f"Arquivo {filename!r} inválido ou vazio")
            names.append(filename)
        if qid in REQUIRED:
            wanted = REQUIRED[qid]
            if not media or (wanted and wanted not in names):
                raise ValueError(f"QUESTÃO SEM FIGURA ESPERADA: {qid} (arquivos={names})")
        ret.append((qid, names))
    return ret

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("directory", type=Path)
    args = ap.parse_args()
    xmls = sorted(args.directory.glob("hidrostatica-lista2-2ano*.xml"))
    if not xmls:
        raise SystemExit("Sem XML da Lista 2 para inspecionar")
    records = [x for f in xmls for x in inspect(f)]
    counter = Counter(qid for qid,_ in records)
    if set(counter) != EXPECTED_BASES:
        raise ValueError("Bases do XML divergentes: " + repr(counter))
    variants = set(counter.values())
    if len(variants)!=1:
        raise ValueError("Número de réplicas irregular: "+repr(counter))
    print("XML media audit passed.")
    print("Bases:",len(counter),"Replicas:",next(iter(variants)))
    for qid in sorted(counter):
        num_with_media = sum(bool(media) for q,media in records if q==qid)
        print(qid, "with_media", num_with_media, "of", counter[qid])
    if any(qid in REQUIRED and sum(bool(m) for q,m in records if q==qid)!=counter[qid] for qid in REQUIRED):
        raise ValueError("Há réplicas sem mídia")
    return 0

if __name__=="__main__":
    sys.exit(main())
