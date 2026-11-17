#!/usr/bin/env python3
"""Audita imagens aprovadas em cada réplica do Moodle Filatte hidro lote 1.

Valida hashes, numeração, links locais e o acoplamento correto entre cada questão
E sua(s) figura(s), inclusive as DUAS do ENEM 2020. Não faz scraping.
"""
import base64
import hashlib
import json
import re
import sys
import xml.etree.ElementTree as ET
from collections import Counter
from pathlib import Path

PAIRS={
 'Q04QuizFamerp2026FluxoGrafico':['Q04Famerp2026GraficoFluxo.png'],
 'Q112NumEEAR2025TuboU':['Q112EEAR2025TuboU.png'],
 'Q113NumENEM2011DensidadeLago':['Q113ENEM2011Dinamometro.png'],
 'Q114ClozeUFRGS2018VolumeDensidade':['Q114UFRGS2018Dinamometros.png'],
 'Q115NumENEM2020DescompressaoGrafico':['Q115ENEM2020Bolsao.png','Q115ENEM2020Grafico.png'],
 'Q116QuizEEAR2020PressaoVasos':['Q116EEAR2020Vasos.png'],
 'Q117QuizENEM2019CapilaridadePapel':['Q117ENEM2019Capilaridade.png'],
 'Q118NumUnicamp2019PressaoTemperatura':['Q118Unicamp2019Temperatura.png'],
}

def validate(directory,manifest_path):
    m=json.loads(manifest_path.read_text('utf-8'))
    hashes={Path(x['repo_path']).name:x['sha256'] for x in m}
    assert len(hashes)==9 and set(hashes)=={y for v in PAIRS.values() for y in v}
    for item in m:
        p=Path(item['repo_path'])
        raw=p.read_bytes()
        assert raw.startswith(b'\x89PNG\r\n\x1a\n')
        assert len(raw)==item['bytes'] and hashlib.sha256(raw).hexdigest()==item['sha256'],p
    counter=Counter()
    xs=sorted(directory.glob('*.xml'))
    assert xs,'Moodle XML ausente'
    for x in xs:
        root=ET.parse(x).getroot()
        assert root.tag=='quiz'
        for q in root.findall('question'):
            if q.get('type')=='category':continue
            name=q.findtext('name/text','')
            base=next((id for id in PAIRS if id in name),None)
            assert base is not None,(name,x)
            counter[base]+=1
            content=q.findtext('questiontext/text','')
            fs=q.findall('questiontext/file')
            names=[]
            for f in fs:
                fname=f.get('name')
                assert f.get('encoding')=='base64' and fname in hashes
                assert '@@PLUGINFILE@@/'+fname in content,(base,fname)
                raw=base64.b64decode(f.text or '',validate=False)
                assert hashlib.sha256(raw).hexdigest()==hashes[fname],(base,fname)
                names.append(fname)
            assert sorted(names)==sorted(PAIRS[base]),(base,names,PAIRS[base])
            assert not re.search(r'src="(?:Q[0-9A-Za-z_]+\.png)"',content),base
    assert set(counter)==set(PAIRS),counter
    assert len(set(counter.values()))==1,counter
    print('Auditoria de mídia aprovada:',len(counter),'bases x',next(iter(counter.values())),'réplicas')
    print('9 PNGs verificados por SHA-256 e referências locais resolvidas.')
    for k,v in sorted(counter.items()):print(k,v)

if __name__=='__main__':
    if len(sys.argv)!=3:raise SystemExit('Uso: check.py DIR_XML MANIFEST')
    validate(Path(sys.argv[1]),Path(sys.argv[2]))
