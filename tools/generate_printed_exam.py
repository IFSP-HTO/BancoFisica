#!/usr/bin/env python3
"""Assemble BancoFisica printed exams from a machine-readable manifest.

The pedagogical layer selects/materializes R/exams questions. This script owns
only the stable print/OMR layer: layout, version identifiers, answer keys and
build artifacts.
"""
from __future__ import annotations
import argparse, csv, json, shutil, subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DEFAULT_TEMPLATE = ROOT / "provas/templates/ifsp-omr.tex"

def esc(s: str) -> str:
    return s

def omr_rows(n: int = 10) -> str:
    rows=[]
    for i in range(1,n+1):
        cells=" & ".join(r"\bubble{%s}" % x for x in "ABCDE")
        rows.append(f"{i} & {cells} \\\\[2.2mm]")
    return "\n".join(rows)

def validate(data: dict) -> None:
    versions=data.get("versions",[])
    if not versions:
        raise ValueError("manifest has no versions")
    seen=set()
    for v in versions:
        code=v["public_code"]
        if code in seen:
            raise ValueError(f"duplicate public_code: {code}")
        seen.add(code)
        key=v["answer_key"]
        qs=v["questions_tex"]
        if len(qs)!=10 or len(key)!=10:
            raise ValueError(f"{code}: expected exactly 10 questions/key entries")
        if any(x not in "ABCDE" for x in key):
            raise ValueError(f"{code}: answer key must contain only A-E")
        if v.get("qr_payload","").find("ANSWER") >= 0:
            raise ValueError(f"{code}: QR payload must not expose answer key")

def render(template: str, data: dict, v: dict) -> str:
    replacements={
        "<<TITLE>>": data["title"],
        "<<SUBTITLE>>": data.get("subtitle",""),
        "<<FORMULA_SHEET>>": data.get("formula_sheet_tex",""),
        "<<PUBLIC_CODE>>": v["public_code"],
        "<<QR_PAYLOAD>>": v.get("qr_payload", v["internal_id"]),
        "<<OMR_ROWS>>": omr_rows(10),
        "<<QUESTIONS>>": "\n\n".join(v["questions_tex"]),
    }
    out=template
    for k,val in replacements.items():
        out=out.replace(k,str(val))
    return out

def main() -> int:
    ap=argparse.ArgumentParser()
    ap.add_argument("manifest", type=Path)
    ap.add_argument("--out-dir", type=Path, default=Path("build/printed-exam"))
    ap.add_argument("--template", type=Path, default=DEFAULT_TEMPLATE)
    ap.add_argument("--compile", action="store_true")
    args=ap.parse_args()

    data=json.loads(args.manifest.read_text(encoding="utf-8"))
    validate(data)
    template=args.template.read_text(encoding="utf-8")
    args.out_dir.mkdir(parents=True, exist_ok=True)

    master=[]
    machine={"title":data["title"],"versions":{}}
    for idx,v in enumerate(data["versions"],1):
        stem=f"prova_{idx:02d}"
        tex=args.out_dir/f"{stem}.tex"
        tex.write_text(render(template,data,v),encoding="utf-8")
        master.append([v["public_code"],v["internal_id"],*v["answer_key"]])
        machine["versions"][v["public_code"]]={
            "internal_id":v["internal_id"],
            "answer_key":v["answer_key"],
            "parameters":v.get("parameters",{})
        }
        if args.compile:
            if not shutil.which("pdflatex"):
                raise SystemExit("pdflatex not found")
            subprocess.run(
                ["pdflatex","-interaction=nonstopmode","-halt-on-error",tex.name],
                cwd=args.out_dir, check=True, stdout=subprocess.DEVNULL
            )
    with (args.out_dir/"gabarito_mestre.csv").open("w",newline="",encoding="utf-8") as f:
        w=csv.writer(f); w.writerow(["public_code","internal_id",*map(lambda i:f"Q{i}",range(1,11))]); w.writerows(master)
    (args.out_dir/"manifest.machine.json").write_text(json.dumps(machine,ensure_ascii=False,indent=2),encoding="utf-8")
    print(f"generated {len(data['versions'])} version(s) in {args.out_dir}")
    return 0

if __name__=="__main__":
    raise SystemExit(main())
