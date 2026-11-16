#!/usr/bin/env python3
"""Corrige mídia local omitida pelo exams2moodle nos XMLs.

Alguns PNGs referenciados em Rnw permanecem como src="arquivo.png" (sem o
@@PLUGINFILE@@ e sem <file>), mesmo que a compilação R/exams tenha sido bem
sucedida. Preserva o XML e todas as questões intactas, exceto as referências
de PNG local ainda não resolvidas. Falha se um PNG não estiver disponível.
"""
import base64
import re
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

SRC_RE=re.compile(r'(?<![A-Za-z])src="([A-Za-z0-9_.-]+\.png)"',re.I)
QUESTION_RE=re.compile(r'<question\b[^>]*>[\s\S]*?</question>',re.I)

def fix_file(xml_path,source_dir):
    original=xml_path.read_text(encoding="utf-8")
    counter={"images_embedded":0,"questions_fixed":0}
    def fix_question(match):
        block=match.group(0)
        m=re.search(r'<questiontext\b[^>]*>[\s\S]*?</questiontext>',block,re.I)
        if m is None:return block
        part=m.group(0)
        files=sorted(set(SRC_RE.findall(part)))
        for fname in files:
            if fname.startswith(".") or ".." in fname:
                raise ValueError("Unsafe image path "+repr(fname))
            path=source_dir/fname
            if not path.is_file():raise FileNotFoundError("Imagem local ausente: "+str(path))
            raw=path.read_bytes()
            if len(raw)<250 or not raw.startswith(b"\x89PNG\r\n\x1a\n"):
                raise ValueError("PNG de origem inválida: "+fname)
            if f'<file name="{fname}"' in part:
                raise ValueError("PNG ja embutido mas src não resolvido: "+fname)
            data=base64.b64encode(raw).decode("ascii")
            part=part.replace(f'src="{fname}"',f'src="@@PLUGINFILE@@/{fname}"')
            part=part.replace("</questiontext>",f'<file name="{fname}" encoding="base64">{data}</file></questiontext>')
            counter["images_embedded"]+=1
        if files:counter["questions_fixed"]+=1
        return block[:m.start()]+part+block[m.end():]
    updated=QUESTION_RE.sub(fix_question,original)
    ET.fromstring(updated)
    xml_path.write_text(updated,encoding="utf-8")
    return counter

def main():
    if len(sys.argv)!=3:
        raise SystemExit("Uso: embed_unresolved_moodle_images.py DIR_XML DIR_STAGE")
    folder=Path(sys.argv[1])
    stage=Path(sys.argv[2])
    if not folder.is_dir() or not stage.is_dir():
        raise SystemExit("Diretório XML ou de figuras ausente")
    total=0
    for p in sorted(folder.glob("*.xml")):
        result=fix_file(p,stage)
        print(p.name,result)
        total+=result["images_embedded"]
    print("Imagens locais incorporadas:",total)
if __name__=="__main__":main()
