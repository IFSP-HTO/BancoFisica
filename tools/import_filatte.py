#!/usr/bin/env python3
"""Importa uma questao do Filatte para revisao no BancoFisica.

Nao altera questoes existentes. Exige a imagem original valida; falhas abortam
sem deixar um .Rnw incompleto. Uso:
python tools/import_filatte.py --url https://provas.professorfilatte.com.br/santa-casa-2027-fisica-questao-66
"""
import argparse
import hashlib
import json
import re
from io import BytesIO
from pathlib import Path
from urllib.parse import urljoin, urlparse

import requests
from bs4 import BeautifulSoup
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SITE = "provas.professorfilatte.com.br"
IMAGE_HOST = "wdlpxyudndyrkigvupfy.supabase.co"
QUESTION_DIR = ROOT / "BancoDeQuestoes" / "optica"
FIGURE_DIR = ROOT / "BancoDeQuestoes" / "figuras"
HEADERS = {"User-Agent": "BancoFisica educational importer/1.0"}


def tex_escape(value):
    # Preservar a escrita da fonte; escapar apenas caracteres especiais LaTeX.
    mapping = {"\\": r"\textbackslash{}", "&": r"\&", "%": r"\%", "$": r"\$",
               "#": r"\#", "_": r"\_", "{": r"\{", "}": r"\}",
               "~": r"\textasciitilde{}", "^": r"\textasciicircum{}"}
    return "".join(mapping.get(ch, ch) for ch in value)


def download(session, url):
    response = session.get(url, timeout=40)
    response.raise_for_status()
    return response.content


def parse_page(html, url):
    soup = BeautifulSoup(html, "html.parser")
    title = soup.find("h1")
    if not title:
        raise ValueError("Titulo h1 ausente")
    name = title.get_text(" ", strip=True)
    match = re.search(r"Santa Casa\s+(\d{4}).*quest[aã]o\s+(\d+)", name, re.I)
    if not match:
        raise ValueError("Pagina fora do piloto Santa Casa; nao importar automaticamente")
    year, number = match.groups()
    h2 = next((h for h in soup.find_all("h2")
               if "Enunciado em texto" in h.get_text(" ", strip=True)), None)
    if not h2:
        raise ValueError("Secao 'Enunciado em texto' ausente")
    parts = []
    for element in h2.next_elements:
        if getattr(element, "name", None) == "h2" and element is not h2:
            break
        if getattr(element, "name", None) in {"p", "li"}:
            text = element.get_text(" ", strip=True)
            if text:
                parts.append(text)
    # Alguns sites colocam cada alternativa num paragrafo; outros num bloco.
    block = "\n".join(parts)
    matches = list(re.finditer(r"(?m)(?:^|\n)\s*\(([A-E])\)\s*", block))
    if len(matches) != 5 or [m.group(1) for m in matches] != list("ABCDE"):
        raise ValueError("Nao foi possivel recuperar exatamente cinco alternativas A-E")
    intro = block[:matches[0].start()].strip()
    intro = re.sub(r"\[Figura:.*?\]", "", intro, flags=re.S).strip()
    if not intro:
        raise ValueError("Enunciado nao identificado")
    alternatives = []
    for i, m in enumerate(matches):
        end = matches[i + 1].start() if i + 1 < 5 else len(block)
        alternatives.append(block[m.end():end].strip())
    alternatives[-1] = re.split(r"\n\(Enunciado e figura:|\nTranscri[cç][aã]o", alternatives[-1])[0].strip()
    if not all(alternatives):
        raise ValueError("Alternativa vazia")
    visual = soup.find("img", alt=re.compile(r"Enunciado da quest[aã]o", re.I))
    if not visual:
        raise ValueError("Imagem original do enunciado nao encontrada")
    image_url = urljoin(url, visual.get("src", ""))
    if urlparse(image_url).hostname != IMAGE_HOST:
        raise ValueError("Dominio da imagem nao autorizado: " + image_url)
    # O piloto tem gabarito revisado; outros itens precisam de cadastro dedicado.
    if (year, number) != ("2027", "66"):
        raise ValueError("Piloto aceita somente Santa Casa 2027 Q66")
    if not re.search(r"Gabarito\s+D", soup.get_text(" ", strip=True)):
        raise ValueError("Gabarito D nao confirmado na pagina")
    return intro, alternatives, image_url, year, number


def build_rnw(intro, alternatives, image_name, source):
    items = "\n".join("  \\item " + tex_escape(a) for a in alternatives)
    return (r'''<<echo=FALSE, results=hide>>=
include_supplement("''' + image_name + r'''", dir="../figuras")
@
\usepackage[utf8]{inputenc}
\usepackage{graphicx}

\begin{question}
''' + tex_escape(intro) + r'''

\begin{center}
\includegraphics[width=0.56\linewidth,keepaspectratio]{''' + image_name + r'''}
\end{center}

\begin{answerlist}
''' + items + r'''
\end{answerlist}
\end{question}

\begin{solution}
Ao passar do ar para a agua, o raio se aproxima da normal: pela lei de
Snell, o indice de refracao da agua e maior. A frequencia permanece
constante; a velocidade diminui e, como $v=\lambda f$, o comprimento
de onda tambem diminui. Logo, a alternativa correta e \textbf{D}.
\end{solution}

%% META-INFORMATION
%% \extype{schoice}
%% \exsolution{00010}
%% \exname{QSCSantaCasa2027Q66Refracao}
%% \exsection{Optica; Refracao; Lei de Snell; Comprimento de onda; Santa Casa 2027}
%% SOURCE-VISUAL: original-extract
%% SOURCE: ''' + source + "\n")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--url", default="https://provas.professorfilatte.com.br/santa-casa-2027-fisica-questao-66")
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()
    if urlparse(args.url).hostname != SITE:
        parser.error("A URL precisa pertencer ao dominio do catalogo")
    with requests.Session() as session:
        session.headers.update(HEADERS)
        html = download(session, args.url).decode("utf-8")
        intro, alternatives, image_url, year, number = parse_page(html, args.url)
        content = download(session, image_url)
    if not content.startswith(b"\x89PNG\r\n\x1a\n"):
        raise ValueError("A origem nao retornou um PNG autentico")
    with Image.open(BytesIO(content)) as im:
        im.verify()
    with Image.open(BytesIO(content)) as im:
        width, height = im.size
    if width < 200 or height < 150 or len(content) < 1000:
        raise ValueError("Imagem suspeita: dimensoes ou tamanho insuficientes")
    fname = f"SantaCasa{year}Q{number}Original.png"
    stem = f"QSCSantaCasa{year}Q{number}Refracao"
    rnw = build_rnw(intro, alternatives, fname, args.url)
    report = {"source": args.url, "image_url": image_url, "image_name": fname,
              "sha256": hashlib.sha256(content).hexdigest(), "width": width,
              "height": height, "bytes": len(content), "source_visual": "original-extract",
              "status": "pending-visual-review"}
    print(json.dumps(report, ensure_ascii=False, indent=2))
    if args.dry_run:
        return
    QUESTION_DIR.mkdir(parents=True, exist_ok=True)
    FIGURE_DIR.mkdir(parents=True, exist_ok=True)
    question_path = QUESTION_DIR / (stem + ".Rnw")
    image_path = FIGURE_DIR / fname
    if question_path.exists() or image_path.exists():
        raise FileExistsError("Questao/imagem ja existente; nao sobrescrever")
    image_path.write_bytes(content)
    question_path.write_text(rnw, encoding="utf-8")
    (ROOT / "import-filatte-report.json").write_text(
        json.dumps(report, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print("Arquivos de revisao criados:", question_path, image_path)


if __name__ == "__main__":
    main()
