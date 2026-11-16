#!/usr/bin/env python3
"""Auditoria somente de metadados do catálogo Filatte de Hidrostática.

Não baixa PNGs nem copia enunciados, não cria questões e não faz merges.
Erros HTTP (inclusive 403) bloqueiam a auditoria; não são contornados.
Classificações automáticas são provisórias; 'figura confirmada' depende
de inspeção visual humana e aprovação do professor antes de importação.
"""
import argparse
import csv
import json
import re
import time
import unicodedata
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path
from urllib.parse import urljoin, urlparse
from urllib.robotparser import RobotFileParser

import requests
from bs4 import BeautifulSoup

BASE = "https://provas.professorfilatte.com.br"
CATALOG = BASE + "/fisica-hidrostatica"
UA = "BancoFisica educational catalog audit/1.0 (source review, no images)"
HEADERS = {"User-Agent": UA, "Accept": "text/html"}

SUBJECTS = [
    ("Hidrodinâmica — Bernoulli/Venturi", ("bernoulli", "venturi", "carburador", "diferença de pressão no escoamento")),
    ("Hidrodinâmica — viscosidade/Poiseuille", ("viscosidade", "poiseuille", "resistência ao fluxo", "escoamento viscoso")),
    ("Hidrodinâmica — continuidade/vazão", ("hidrodinamica", "continuidade", "vazao", "vazão", "tubulação", "escoamento")),
    ("Hidrostática — capilaridade/tensão superficial", ("capilaridade", "tensao superficial", "gota de piche", "coesao", "adesao", "agulha apoiada")),
    ("Hidrostática — Pascal/prensa", ("pascal", "prensa hidraulica", "elevador hidraulico", "ludiao")),
    ("Hidrostática — manometria/Torricelli", ("manometro", "manometria", "barometro", "torricelli", "mmhg", "coluna de mercurio")),
    ("Hidrostática — vasos comunicantes", ("vasos comunicantes", "tubo em u", "liquidos imisciveis", "liquidos nao misciveis")),
    ("Hidrostática — empuxo/flutuação", ("empuxo", "arquimedes", "flutuacao", "flutua", "submerso", "afund", "peso aparente", "boia")),
    ("Hidrostática — Stevin/pressão em profundidade", ("stevin", "pressao hidrost", "pressao absoluta", "pressao manometrica", "profundidade", "coluna de agua", "diferenca de pressao")),
    ("Hidrostática — pressão/força por área", ("pressao", "pressão", "forca de pressao", "area de contato")),
    ("Hidrostática — densidade", ("densidade", "massa especifica", "densimetro", "volume")),
]
FIGURE_TERMS = ("conforme a figura", "figura a seguir", "figura abaixo", "mostra a figura",
                "esquema", "grafico", "grafica", "representado na figura",
                "ilustracao", "observe a figura", "figuras a seguir", "diagrama",
                "como ilustrado", "na imagem", "de acordo com a figura")
HIGH = ("ita ", "ime ", "olimpiada", "olimpíada", "obf ", "2ª fase", "2a fase")
def norm(s):
    return "".join(c for c in unicodedata.normalize("NFKD", s.casefold()) if not unicodedata.combining(c))
def subject(description):
    s = norm(description)
    for label, needles in SUBJECTS:
        if any(norm(x) in s for x in needles):
            return label
    return "Mista ou não determinada"
def difficulty(description, title, body=""):
    """Triagem NÃO validada item a item."""
    t = norm(description+" "+title)
    if any(norm(x) in t for x in HIGH): return "Difícil (triagem)"
    multistep = sum(k in t for k in [" e ", " + ", "grafic", "moment", "2a lei", "equilibrio", "forca adicional", "composto"])
    advanced = any(k in t for k in ["poiseuille","fluidos nao newtonianos","aceleracao de recipiente","articulada","integrais"])
    if advanced or multistep >= 2: return "Difícil (triagem)"
    if any(k in t for k in ["conversao de unidades","comparacao","principio de pascal","pressao de um corpo","massa e volume"]):
        return "Fácil (triagem)"
    return "Média (triagem)"
def fetch(session, url):
    if urlparse(url).netloc != urlparse(BASE).netloc:
        raise ValueError("Domínio não autorizado: " + url)
    r = session.get(url, timeout=28)
    if r.status_code in (401,403,429):
        raise PermissionError(f"HTTP {r.status_code}: acesso automático indisponível: {url}")
    r.raise_for_status()
    if "text/html" not in r.headers.get("Content-Type","text/html"):
        raise ValueError("Não é HTML: " + url)
    return r.text

def catalog_entries(html):
    soup=BeautifulSoup(html,"html.parser")
    results=[]
    seen=set()
    for a in soup.select("a[href]"):
        href=urljoin(CATALOG,a["href"])
        if not re.search(r"-fisica-questao-\d+(?:/)?$",urlparse(href).path):
            continue
        if href in seen: continue
        seen.add(href)
        label=a.get_text(" ",strip=True)
        exam=a.find_previous(["h2","h3"])
        exam_name=exam.get_text(" ",strip=True) if exam else ""
        # question index must be an actual catalog question, not nav references.
        q=re.search(r"Quest[ãa]o\s+(\d+)",label,re.I)
        if not q: continue
        yr=re.search(r"\b(19\d{2}|20\d{2})\b",exam_name)
        desc=re.sub(r"^Quest[ãa]o\s+\d+\s*","",label).strip()
        results.append(dict(
            id=len(results)+1, institution=exam_name, year=int(yr.group(1)) if yr else None,
            question=q.group(1), description=desc,
            url=href, subject=subject(desc), difficulty=difficulty(desc,exam_name),
            full_statement_verified=False, figure_inside_question="Pendente",
            original_question_image="Pendente", figure_review_required="A verificar",
            educational_quality="Pendente: revisão do enunciado/solução",
            import_status="Não importada — aguardando curadoria",
            notes="Classificação de catálogo, não revisão individual da imagem"
        ))
    return results

def page_audit(row, html):
    soup=BeautifulSoup(html,"html.parser")
    headings=soup.find_all("h2")
    node=next((h for h in headings if "Enunciado em texto" in h.get_text(" ",strip=True)),None)
    if not node: raise ValueError("Sem transcrição")
    blocks=[]
    for other in node.next_siblings:
        if getattr(other,"name",None)=="h2":break
        if hasattr(other,"get_text"):blocks.append(other.get_text(" ",strip=True))
    body=" ".join(blocks)
    if len(body)<50:raise ValueError("Transcrição curta")
    title=soup.find("h1")
    row["full_statement_verified"]=True
    row["title"]=title.get_text(" ",strip=True) if title else ""
    row["statement_characters"]=len(body)
    row["alternative_count"]=len(re.findall(r"(?:^|\s)[(]?[A-E][).]\s",body))
    row["source_image_available"]=bool(soup.find("img",alt=re.compile("Enunciado",re.I)))
    row["original_question_image"]="Sim" if row["source_image_available"] else "Não encontrada"
    row["mentions_figure_in_text"]=any(k in norm(body) for k in FIGURE_TERMS)
    # A screenshot do enunciado NÃO prova que existe uma figura interna.
    row["figure_inside_question"]="Suspeita: conferir imagem" if row["mentions_figure_in_text"] else "A verificar visualmente"
    row["figure_review_required"]="SIM — link para aprovação" if row["mentions_figure_in_text"] else "Conferência antes de decidir"
    row["educational_quality"]="Transcrição acessível; curadoria física e pedagógica pendente"
    row["notes"]="A página traz imagem do enunciado; figura interna não foi comprovada por inspeção visual."
    return row

def main():
    ap=argparse.ArgumentParser()
    ap.add_argument("--outdir",default="build/filatte-hidro-audit")
    ap.add_argument("--limit",type=int,default=411)
    ap.add_argument("--delay",type=float,default=1.25)
    args=ap.parse_args()
    out=Path(args.outdir);out.mkdir(parents=True,exist_ok=True)
    audit={"source":CATALOG,"retrieved_at":datetime.now(timezone.utc).isoformat(),
           "status":"started","notes":[]}
    session=requests.Session();session.headers.update(HEADERS)
    try:
        # Pede robots.txt por cortesia; nunca contorna bloqueio 403.
        robots=RobotFileParser()
        try:
            response=session.get(BASE+"/robots.txt",timeout=12)
            if response.status_code==200:
                robots.parse(response.text.splitlines())
                if not robots.can_fetch(UA,CATALOG):
                    raise PermissionError("robots.txt bloqueia auditoria")
        except requests.RequestException as e:
            audit["notes"].append("robots.txt não acessível: "+str(e))
        content=fetch(session,CATALOG)
        rows=catalog_entries(content)
        audit["catalog_count"]=len(rows)
        if len(rows)!=411:
            audit["notes"].append(f"O site informa 411; parser retornou {len(rows)}; conferir estrutura.")
        for i,row in enumerate(rows[:args.limit],1):
            try:
                page=fetch(session,row["url"])
                page_audit(row,page)
                row["fetch_status"]="OK"
            except PermissionError as e:
                row["fetch_status"]=str(e)
                audit["notes"].append(str(e))
                # Bloqueio: não insistir em requisições em massa.
                for later in rows[i:]:
                    later["fetch_status"]="Não consultado: bloqueio HTTP"
                break
            except (requests.RequestException,ValueError) as e:
                row["fetch_status"]=str(e)
            if i%40==0:print(f"analisadas {i}/{len(rows)}",flush=True)
            time.sleep(max(args.delay,0.6))
        columns=["id","institution","year","question","description","url","subject","difficulty",
                 "full_statement_verified","figure_inside_question","original_question_image",
                 "mentions_figure_in_text","figure_review_required","educational_quality","import_status",
                 "source_image_available","statement_characters","alternative_count","fetch_status","notes"]
        with (out/"catalog.csv").open("w",encoding="utf-8",newline="") as f:
            w=csv.DictWriter(f,fieldnames=columns,extrasaction="ignore")
            w.writeheader();w.writerows(rows)
        audit["status"]="catalog_extracted"
        audit["page_verified"]=sum(r["full_statement_verified"] for r in rows)
        audit["subject_counts"]=dict(Counter(r["subject"] for r in rows))
        audit["difficulty_counts"]=dict(Counter(r["difficulty"] for r in rows))
        audit["figure_suspected"]=sum(r["figure_inside_question"].startswith("Suspeita") for r in rows)
        audit["explicit_figure_confirmed"]=0
        if len(rows)!=411:audit["status"]="incomplete_catalog_count"
        if audit["page_verified"]<len(rows):audit["notes"].append("Auditoria individual incompleta: não tratar figura interna como confirmada.")
    except Exception as e:
        audit["status"]="blocked"
        audit["error"]=type(e).__name__+": "+str(e)
        print("BLOQUEADO: "+audit["error"],flush=True)
    (out/"status.json").write_text(json.dumps(audit,ensure_ascii=False,indent=2),encoding="utf-8")
    print(json.dumps({"status":audit["status"],"count":audit.get("catalog_count"),"verified":audit.get("page_verified"),"error":audit.get("error")},ensure_ascii=False))
    if audit["status"] in ("blocked","incomplete_catalog_count"):raise SystemExit(2)
if __name__=="__main__":
    main()
