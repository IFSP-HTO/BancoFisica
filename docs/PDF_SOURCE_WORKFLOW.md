# Fluxo de imagens provenientes de PDFs

Este documento define o procedimento recomendado para questões extraídas de provas, livros ou outros PDFs-fonte quando a figura original deve ser preservada no BancoFisica.

## Princípio

Quando o PDF-fonte estiver disponível, a imagem da questão deve ser obtida diretamente dele. Não se deve redesenhar, regenerar com IA ou transportar a imagem como uma string `base64`/`blob` quando houver acesso ao arquivo no sistema de arquivos.

O fluxo preferencial é:

1. localizar a questão e a página no PDF;
2. verificar se a figura é um objeto raster independente;
3. se for, extrair o objeto sem reencodificação;
4. se não for, renderizar apenas a região necessária da página;
5. gravar o arquivo diretamente em `BancoDeQuestoes/figuras`;
6. revisar visualmente o arquivo antes de referenciá-lo no `.Rnw`;
7. compilar/validar a questão normalmente.

## Dependência

O utilitário usa PyMuPDF:

```bash
python -m pip install pymupdf
```

## 1. Visualizar uma página

Para gerar uma imagem de inspeção da página sem modificar o PDF:

```bash
python tools/pdf_assets.py page prova.pdf \
  --page 15 \
  --output /tmp/pagina-15.png
```

A numeração de páginas é iniciada em 1.

## 2. Verificar imagens raster incorporadas

Antes de fazer um recorte, verifique se a figura já existe como objeto independente no PDF:

```bash
python tools/pdf_assets.py images prova.pdf --page 15
```

A saída apresenta, entre outros dados, o `xref`, a largura e a altura de cada imagem incorporada.

## 3. Extrair a imagem incorporada

Quando a figura desejada corresponder a um objeto raster independente, prefira a extração por `xref`:

```bash
python tools/pdf_assets.py extract prova.pdf \
  --xref 236 \
  --output BancoDeQuestoes/figuras/QxxQuizAssunto.png
```

Nesse modo os bytes da imagem são copiados do PDF sem reencodificação. Se o nome de saída for fornecido sem extensão, o utilitário usa a extensão original encontrada no PDF.

Use `--provenance` quando for útil gerar um arquivo lateral `.source.json` contendo nome e SHA-256 do PDF-fonte e o `xref` usado.

## 4. Recortar uma região do PDF

Nem toda figura visual é um único objeto do PDF. Diagramas podem ser formados por vetores, textos, linhas e múltiplas imagens. Nesses casos, renderize a região relevante diretamente.

Coordenadas percentuais da página são práticas para inspeção visual:

```bash
python tools/pdf_assets.py crop prova.pdf \
  --page 15 \
  --bbox-percent 3 28 48 48 \
  --dpi 300 \
  --output BancoDeQuestoes/figuras/QxxQuizAssunto.png
```

As quatro coordenadas representam `x0 y0 x1 y1`, em porcentagem da largura/altura da página. Também é possível usar coordenadas em pontos do PDF com `--bbox`.

O padrão de 300 dpi é adequado para a maior parte das questões. Aumente a resolução apenas quando necessário.

### Quando preferir o recorte

Use `crop` em vez de `extract` quando:

- a figura for composta por vários objetos do PDF;
- houver rótulos vetoriais ou texto que devam permanecer junto da figura;
- a referência/fonte impressa fizer parte do material que precisa ser preservado;
- a extração por `xref` produzir apenas uma parte da figura visível.

## 5. Processamento em lote

Quando várias questões vierem do mesmo conjunto de provas, use um manifesto CSV. O modo `batch` agrupa as linhas por PDF e mantém cada documento aberto enquanto processa seus ativos, evitando abrir e fechar o mesmo arquivo para cada questão.

Formato:

```csv
pdf,mode,page,x0,y0,x1,y1,unit,xref,output,dpi
/fontes/prova.pdf,embedded,,,,,,,236,BancoDeQuestoes/figuras/Q20QuizAssunto.png,
/fontes/prova.pdf,crop,15,3,28,48,48,percent,,BancoDeQuestoes/figuras/Q21QuizAssunto.png,300
```

Execução:

```bash
python tools/pdf_assets.py batch assets.csv --root .
```

O campo `mode` aceita:

- `embedded`: exige `xref`;
- `crop`: exige `page`, `x0`, `y0`, `x1`, `y1`; `unit` pode ser `percent` ou `points`.

O parâmetro `--provenance` também pode ser usado no processamento em lote.

## 6. Regras de fidelidade

Para questões baseadas em PDFs-fontes:

- não gerar novamente com IA uma figura que deva ser igual à original;
- não usar OCR para substituir a imagem original;
- não converter uma imagem para `base64` apenas para transferi-la entre etapas quando o arquivo local puder ser usado diretamente;
- preferir extração de objeto incorporado, pois preserva os bytes originais;
- usar recorte renderizado apenas quando a composição do PDF exigir;
- revisar visualmente o resultado antes do commit;
- manter o padrão de nomes já utilizado em `BancoDeQuestoes/figuras`, preferencialmente relacionado ao nome da questão `.Rnw`.

## 7. Questões já iniciadas pelo fluxo antigo

Se uma questão estiver sendo implementada e sua figura tiver sido obtida por screenshot indireto, reconstrução, geração ou transporte intermediário, refaça o ativo com este procedimento antes de considerar o trabalho concluído, desde que o PDF-fonte original esteja disponível.

O texto da questão e a imagem são etapas separadas: o texto pode ser extraído e adaptado conforme as regras pedagógicas do banco, enquanto a figura original deve seguir o fluxo determinístico descrito aqui quando a intenção for preservá-la.
