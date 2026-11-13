#!/usr/bin/env python3
"""Recorta regioes originais de PNGs revisados visualmente.
O hash dos arquivos-fontes e validado antes de qualquer recorte.
Nenhuma figura e redesenhada e nenhuma questao e modificada.
"""
import argparse
import hashlib
import json
from pathlib import Path
from PIL import Image


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--manifest", default="data/filatte-optica-crops-2027.json")
    ap.add_argument("--stage-dir", default="build/filatte-stage")
    ap.add_argument("--dest", default="BancoDeQuestoes/figuras")
    args = ap.parse_args()
    plan = json.loads(Path(args.manifest).read_text(encoding="utf-8"))
    dest = Path(args.dest)
    dest.mkdir(parents=True, exist_ok=True)
    audit = []
    for entry in plan["items"]:
        img_path = Path(args.stage_dir) / "source" / (entry["id"] + ".png")
        source_bytes = img_path.read_bytes()
        sha = hashlib.sha256(source_bytes).hexdigest()
        if sha != entry["source_sha256"]:
            raise ValueError(f"Hash da fonte divergente para {entry['id']}")
        with Image.open(img_path) as im:
            im.load()
            w, h = im.size
            for figure in entry["figures"]:
                l, t, r, b = figure["box"]
                if not (0 <= l < r <= w and 0 <= t < b <= h):
                    raise ValueError("Recorte fora da imagem: " + figure["name"])
                target = dest / figure["name"]
                if target.exists():
                    raise FileExistsError(target)
                sub = im.crop((l, t, r, b))
                sub.save(target, format="PNG")
                audit.append({"source":entry["id"], "source_sha256":sha,
                              "image":str(target), "box":[l,t,r,b],
                              "size":[r-l,b-t],
                              "sha256":hashlib.sha256(target.read_bytes()).hexdigest(),
                              "source_visual":"original-crop"})
    output = Path(args.stage_dir) / "crops-audit.json"
    output.write_text(json.dumps(audit,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
    print(json.dumps({"verified_source_images":len(plan["items"]), "cropped_figures":len(audit)}))


if __name__ == "__main__":
    main()
