# Provas impressas e OMR no BancoFisica

Esta pasta define o padrão oficial para provas impressas geradas a partir do BancoFisica. O objetivo é tornar reprodutível o fluxo completo:

`BancoDeQuestoes -> seleção/adaptação -> 10 versões -> PDF -> folha OMR -> escaneamento -> correção -> análise de itens`.

O perfil de referência é `provas/profiles/ifsp-omr.yaml` e o template correspondente é `provas/templates/ifsp-omr.tex`.

## Princípios do formato IFSP-OMR

- primeira página exclusiva para identificação e cartão-resposta;
- 10 questões objetivas, sempre com alternativas A--E;
- por padrão, 5 fáceis + 5 médias;
- 10 versões parametrizadas/equivalentes;
- alternativas embaralhadas por versão;
- versão não é exibida como "A/B/C" ao estudante;
- QR code contém somente `exam_id` + código opaco da versão, nunca o gabarito;
- quatro marcadores pretos externos permitem correção de perspectiva;
- cabeçalho das páginas de questões é neutro, sem revelar a versão;
- duas colunas e plano explícito de quebras para evitar páginas quase vazias;
- toda prova deve passar por preflight visual antes de ser usada.

## Instalação

```bash
python -m pip install -r provas/requirements.txt
```

Para questões vindas de `.Rnw`, é necessário também R + pacote `exams`. Para gerar PDF, é necessário `pdflatex`. Para corrigir PDF escaneado, é necessário `pdftoppm` (Poppler).

## Gerar uma prova

Use o exemplo como ponto de partida:

```bash
python tools/generate_printed_exam.py provas/examples/lancamento-obliquo/prova.yaml
```

Saída padrão do exemplo:

```text
build/provas/LO-DEMO/
  prova_01.pdf
  ...
  prova_10.pdf
  answer_key.csv
  manifest.json
  assets/
```

`manifest.json` é a fonte de verdade machine-readable para a correção. Ele relaciona código opaco, ID interno, gabarito e metadados pedagógicos de cada item.

### Questões inline

Questões adaptadas para prova impressa podem ser descritas diretamente no YAML. Isso é especialmente útil para questões `cloze` que precisam virar uma única questão A--E. Use `parameter_sets` ou `variants` para fornecer diferentes versões numéricas.

A substituição usa apenas tokens `{{nome}}`; chaves normais de LaTeX não são interpretadas.

### Questões `schoice` do R/exams

Uma questão simples de escolha única pode apontar diretamente para o banco:

```yaml
- id: LO26L1Q07
  difficulty: easy
  skills: [apice, componentes-da-velocidade]
  source_rnw: BancoDeQuestoes/cinematica/lancamentos/listas2026/lista1/Q07QuizUELVelocidadeApice.Rnw
```

O gerador chama `tools/render_exam_question.R`, avalia a parametrização do `.Rnw`, lê `\\exsolution{...}`, embaralha as alternativas e copia imagens referenciadas para `assets/`.

`cloze` e `mchoice` não são convertidos automaticamente, porque a adaptação para uma única resposta correta é uma decisão pedagógica. Nesses casos, registre a adaptação inline no YAML da prova.

## Corrigir cartões OMR

O desenho do cartão é absoluto e sua geometria está registrada no perfil. Escaneie apenas as folhas de resposta ou gere um PDF contendo uma folha por página.

```bash
python tools/grade_omr.py respostas.pdf \
  --manifest build/provas/LO-DEMO/manifest.json \
  --profile provas/profiles/ifsp-omr.yaml \
  --output build/provas/LO-DEMO/notas.csv
```

Para associar nomes sem OCR, forneça um CSV opcional:

```csv
page,name
1,Ana Silva
2,Bruno Souza
```

```bash
python tools/grade_omr.py respostas.pdf ... --names-csv nomes.csv
```

O corretor é conservador. Marcações em branco, múltiplas, ambíguas, QR ilegível ou falha nos marcadores resultam em `manual_review`; não são adivinhadas.

## Analisar a prova

```bash
python tools/analyze_exam.py build/provas/LO-DEMO/notas.csv \
  --manifest build/provas/LO-DEMO/manifest.json \
  --cohort "1o ano Automação 2026" \
  --output-dir build/provas/LO-DEMO/analysis
```

São produzidos `summary.json` e `item_analysis.csv`. Para acumular apenas estatísticas agregadas (sem nomes de alunos):

```bash
python tools/analyze_exam.py ... --history analytics/item_history.csv
```

Isso permite comparar a dificuldade prevista (`easy`, `medium`) com a proporção de acertos observada em aplicações reais.

## Metadados pedagógicos

Ao selecionar ou adaptar questões, registre pelo menos:

- `id`: identificador estável;
- `difficulty`: `easy`, `medium` ou outro nível explicitamente justificado;
- `skills`: habilidades efetivamente exigidas;
- se útil, termos como `x-para-t-para-y`, `raciocinio-inverso`, `apice`, `conversao-de-unidades`.

Esses metadados devem descrever o que a questão exige, não apenas seu assunto.

## Preflight obrigatório

Antes de imprimir um lote:

1. validar o YAML com `python tools/generate_printed_exam.py prova.yaml --validate-only`;
2. gerar todas as versões;
3. confirmar que todas têm o mesmo número de páginas;
4. renderizar e inspecionar visualmente pelo menos as versões 1, 6 e 10;
5. conferir formulário, figuras, quebras de coluna e alinhamento;
6. conferir `answer_key.csv`/`manifest.json` contra pelo menos uma versão;
7. fazer um teste real do cartão OMR preenchendo uma folha e passando por `grade_omr.py`.

A geração automática não substitui essa revisão visual.
