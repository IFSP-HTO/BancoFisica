# Pré-visualizador de questões (app Shiny)

App Shiny **local** para visualizar as questões do BancoFisica exatamente como
o Moodle as exibe — e respondê-las como aluno — sem precisar importar nada num
Moodle real.

## Como rodar

A partir da **raiz do projeto** (`BancoFisica/`):

```r
shiny::runApp("app")
```

> Requer os pacotes `shiny` e `xml2` (além de `exams`, `callr`, `base64enc`,
> já usados pelo projeto). A renderização de fórmulas usa MathJax via CDN, então
> é preciso conexão com a internet.

## O que ele faz

Três fontes de questões:

1. **Compilar .Rnw** — escolha uma questão do banco; o app roda `exams2moodle`
   numa sessão isolada (`callr`), com o mesmo `converter = "pandoc-mathjax"` do
   fluxo de produção, e renderiza o resultado. Sempre reflete o estado atual.
2. **XML existente** — carrega um dos `Moodle/*.xml` já gerados (use o limite de
   questões para arquivos grandes, como `estatica`).
3. **Upload de XML** — envie qualquer `.xml` no formato Moodle.

Para cada questão:

- Enunciado renderizado com **math (MathJax)** e **imagens** (base64 embutido).
- Campos de resposta por tipo: `numerical`, `shortanswer`, `multichoice`
  (single/múltipla) e `cloze` (uma entrada por lacuna ⟦n⟧).
- **Verificar** — corrige usando as respostas e tolerâncias do próprio XML,
  mostrando o feedback por alternativa quando houver.
- **Mostrar solução** — revela o `generalfeedback` da questão.

## Estrutura

```
app/
  app.R                  UI + server
  R/compile_rnw.R        compila .Rnw -> Moodle XML (callr)
  R/parse_moodle_xml.R   XML -> objetos-questão (+ imagens, cloze)
  R/render_question.R    enunciado, campos e feedback
  R/grade.R              correção contra o gabarito do XML
  www/styles.css         estilo aproximando do Moodle
```

## Limitações conhecidas

- As lacunas `cloze` aparecem como campos numerados abaixo do enunciado
  (marcador ⟦n⟧ no texto), não embutidas inline.
- Em questões `multichoice` de múltipla resposta, a correção marca acerto quando
  o conjunto selecionado é exatamente o conjunto de alternativas corretas.
