# Listas Moodle fiéis às provas de lançamento oblíquo — 2026

Este fluxo reproduz no Moodle as três avaliações impressas de lançamento
oblíquo **como os estudantes as viram**, sem substituir questões, figuras ou
alternativas por versões equivalentes do BancoFisica.

Associação dos lotes impressos:

- **Mecânica**: `LO-2609`;
- **Informática**: `LO2-2609` (T2);
- **Automação**: `LO3-2609` (T3).

## Fonte de verdade

As fontes ficam em:

```text
BancoDeQuestoes/cinematica/lancamentos/provas2026_fieis/
  mecanica/
    Q01.Rnw ... Q10.Rnw
    assets/
  informatica/
    Q01.Rnw ... Q10.Rnw
    assets/
  automacao/
    Q01.Rnw ... Q10.Rnw
    assets/
```

Cada questão possui **10 recortes visuais**, um para cada versão realmente
impressa da prova. Os recortes foram obtidos diretamente dos PDFs limpos
pré-aplicação. Eles preservam o enunciado, a figura, os valores numéricos e a
ordem das alternativas A--E da prova impressa.

Não são usados scans de estudantes, folhas respondidas, nomes, matrículas,
notas ou qualquer outro dado individual.

## Como a questão aparece no Moodle

O bloco completo da questão impressa é mostrado como uma imagem fiel. Logo
abaixo, o Moodle apresenta apenas o seletor A, B, C, D, E. O estudante marca
a letra correspondente à alternativa já visível no recorte.

O seletor **não é embaralhado**, pois a ordem A--E já está congelada na imagem
da prova.

Cada `.Rnw` sorteia uma das 10 versões efetivamente impressas para aquela
posição. Ao gerar 25 réplicas, as variantes são amostras do conjunto real de
10 versões; repetições são esperadas e deliberadas.

## Estrutura no Moodle

Cada turma é exportada em um único XML:

```text
BancoFisica/Listas 2026/Lancamento Obliquo/<Turma>/
  Q01/ -> Q01-R001 ... Q01-R025
  Q02/ -> Q02-R001 ... Q02-R025
  ...
  Q10/ -> Q10-R001 ... Q10-R025
```

São 10 categorias e 250 itens por turma.

## Geração

```bash
Rscript tools/generate_lancamento_obliquo_provas_2026.R 25
```

Saída:

```text
build/lancamento-obliquo-provas-2026/
  lancamento-obliquo-automacao.xml
  lancamento-obliquo-informatica.xml
  lancamento-obliquo-mecanica.xml
```

O CI verifica para cada turma:

- 10 fontes `.Rnw`;
- 100 recortes fiéis (10 versões × 10 questões);
- categorias Q01--Q10;
- 25 réplicas em cada categoria;
- 250 imagens `@@PLUGINFILE@@` e 250 arquivos base64 incorporados ao XML;
- tamanho inferior a 10 MiB.

Este fluxo substitui o mapeamento anterior para questões canônicas
“equivalentes” do Banco. Para listas que pretendem reproduzir uma avaliação
aplicada, **equivalência conceitual não é suficiente: a fonte impressa é a
referência**.


## REGRA DE FIDELIDADE À PROVA IMPRESSA

Para estas três avaliações, **não é permitido substituir uma questão por uma
questão canônica equivalente do BancoFisica**.

Os arquivos em `provas2026/fieis/<turma>/QxxProvaFiel.Rnw` foram criados
especificamente para reproduzir o que foi efetivamente impresso. Cada réplica
seleciona uma das dez versões reais aplicadas (`V01`--`V10`) e inclui a
imagem exata do bloco da questão daquela versão, contendo o mesmo enunciado,
a mesma figura, os mesmos valores numéricos e as mesmas alternativas A--E.

As opções do Moodle são apenas as letras A--E e **não são embaralhadas**; o
gabarito é o da versão impressa selecionada.

As imagens exatas não podem ser substituídas pelas figuras históricas/canônicas
do Banco. O diretório delas é fornecido ao gerador por
`BF_PROVA_FIEL_ASSET_DIR`.
