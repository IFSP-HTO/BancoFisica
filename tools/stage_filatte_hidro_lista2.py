#!/usr/bin/env python3
"""Estagio auditavel dos PNGs ORIGINAIS das provas via catalogo Filatte.

Sem OCR, sem substituir fonte, sem alterar pixels neste estagio.
As figuras da prova tem copyright dos respectivos organizadores.
O uso de cada recorte exige revisao de compatibilidade com os itens do banco.
"""
import hashlib, json, sys
from pathlib import Path
from io import BytesIO
from urllib.parse import urlparse
import requests
from PIL import Image

ROOT=Path(__file__).resolve().parents[1]
MANIFEST=ROOT/"data/filatte-hidrostática-lista2-originais.json"
OUT=ROOT/"build/filatte-hidrostática-lista2-originais"
data=json.loads(MANIFEST.read_text(encoding="utf-8"))
OUT.mkdir(parents=True,exist_ok=True)
s=requests.Session()
s.headers["User-Agent"]="BancoFisica educational visual provenance checker/1.0"
results=[]
for item in data["images"]:
    u=item["url"]
    if urlparse(u).hostname!="wdlpxyudndyrkigvupfy.supabase.co":
        raise ValueError("Unexpected source host")
    try:
        response=s.get(u,timeout=45);response.raise_for_status()
        payload=response.content
        with Image.open(BytesIO(payload)) as im:
            im.verify()
        with Image.open(BytesIO(payload)) as im:
            if im.format!="PNG":raise ValueError("Image is not PNG")
            w,h=im.size
        if w<180 or h<150:raise ValueError("Invalid dimensions")
        target=OUT/(item["id"]+".png")
        target.write_bytes(payload)
        results.append({"id":item["id"],"source_page":item["page"],
                        "source_image_url":u,"path":str(target.relative_to(ROOT)),
                        "width":w,"height":h,"sha256":hashlib.sha256(payload).hexdigest(),
                        "bytes":len(payload),"status":"source-verified"})
    except Exception as err:
        results.append({"id":item["id"],"source_page":item["page"],
                        "source_image_url":u,"error":repr(err),"status":"blocked"})
(OUT/"sources-audit.json").write_text(json.dumps(results,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
print(json.dumps(results,ensure_ascii=False,indent=2))
if any(it["status"]!="source-verified" for it in results):sys.exit(2)
