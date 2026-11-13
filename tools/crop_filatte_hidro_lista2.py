#!/usr/bin/env python3
"""Extrai SOMENTE os desenhos originais verificados do Filatte para Lista 2.

Fonte PNG conferida por SHA-256; nunca faz OCR, inventa diagramas ou copia
enunciados completos. Em uma figura da UFRGS, dois rótulos numéricos fixos
são ocultados (áreas brancas de fundo), pois as instâncias R/exams sorteiam
novas massas e volumes. O manifesto registra esses ajustes.
"""
import hashlib
import json
from io import BytesIO
from pathlib import Path
from urllib.parse import urlparse

import requests
from PIL import Image, ImageDraw

ROOT=Path(__file__).resolve().parents[1]
MANIFEST=ROOT/"data/filatte-hidrostatica-lista2-crops.json"
DEST=ROOT/"BancoDeQuestoes/hidrostatica"
manifest=json.loads(MANIFEST.read_text(encoding="utf-8"))
session=requests.Session()
session.headers["User-Agent"]="BancoFisica educational importer/1.0"
source_images={}
source_hashes={}
for src in manifest["source_images"]:
    url=src["url"]
    if urlparse(url).hostname!="wdlpxyudndyrkigvupfy.supabase.co":
        raise ValueError("Host de fonte não permitido")
    response=session.get(url,timeout=40)
    response.raise_for_status()
    raw=response.content
    actual=hashlib.sha256(raw).hexdigest()
    if actual!=src["sha256"]:
        raise ValueError(f"SHA-256 diferente da imagem original {src['source_id']}")
    with Image.open(BytesIO(raw)) as check:
        check.verify()
    with Image.open(BytesIO(raw)) as im:
        if im.format!="PNG":
            raise ValueError("Fonte não é PNG")
        source_images[src["source_id"]]=im.convert("RGB").copy()
    source_hashes[src["source_id"]]=actual

DEST.mkdir(parents=True,exist_ok=True)
audit=[]
for cfg in manifest["figures"]:
    src=source_images[cfg["source_id"]].copy()
    width,height=src.size
    left,top,right,bottom=cfg["crop"]
    if not (0<=left<right<=width and 0<=top<bottom<=height):
        raise ValueError("Recorte inválido "+cfg["name"])
    if cfg.get("redactions"):
        draw=ImageDraw.Draw(src)
        for red in cfg["redactions"]:
            x1,y1,x2,y2=red["box"]
            if not (0<=x1<x2<=width and 0<=y1<y2<=height):
                raise ValueError("Máscara fora de fonte")
            # Máscaras somente nas anotações numéricas; não na montagem física.
            draw.rectangle((x1,y1,x2,y2),fill="white")
    crop=src.crop(tuple(cfg["crop"]))
    target=DEST/cfg["name"]
    if target.exists():
        raise FileExistsError("Figura já existe; não sobrescreve: "+str(target))
    crop.save(target,format="PNG")
    audit.append({"figure":cfg["name"],"source_id":cfg["source_id"],
        "source_sha256":source_hashes[cfg["source_id"]],
        "crop":cfg["crop"],"redactions":cfg.get("redactions",[]),
        "output_sha256":hashlib.sha256(target.read_bytes()).hexdigest(),
        "output_size":list(crop.size),
        "source_visual":"original-crop-redacted-labels" if cfg.get("redactions") else "original-crop"})
output=ROOT/"data/filatte-hidrostatica-lista2-audit.json"
output.write_text(json.dumps(audit,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
print(json.dumps({"sources_verified":len(source_images),"figures_saved":len(audit)},ensure_ascii=False))
