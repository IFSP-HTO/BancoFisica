# Lançamento oblíquo — listas de setembro/2026

Expansão isolada das questões históricas de lançamento oblíquo do BancoFisica,
preparada a partir dos três PDFs-fonte fornecidos para as listas de revisão da
prova de 21/09/2026.

- `lista1/`: 15 questões de fixação e fundamentos;
- `lista2/`: 15 questões de aplicação e problemas inversos;
- `reserva/`: 10 questões reservadas para a prova.

## Parametrização

Das 40 questões-base, 35 têm parâmetros sorteados em R e soluções calculadas
dinamicamente. As cinco restantes são conceituais e não possuem dado numérico
útil para variar.

Oito questões possuem dados numéricos escritos na própria figura. Nelas, o
recorte do PDF é preservado como imagem-base em `BancoDeQuestoes/figuras` e
somente a pequena região do rótulo numérico é substituída programaticamente em
cada variante. O gráfico de Daiane dos Santos é mantido integralmente original;
nessa questão varia apenas a distância horizontal informada no texto.

## Moodle

O gerador dedicado cria uma categoria separada para cada questão-base:

- `.../Lista 1 - Setembro 2026/Q01`, `Q02`, ...;
- `.../Lista 2 - Setembro 2026/Q01`, `Q02`, ...;
- `.../Reserva Prova 21-09-2026/Q01`, `Q02`, ... .

As variantes são nomeadas `Qxx-Ryyy`. Isso impede que essas questões se misturem
com as questões históricas de lançamento oblíquo ou entre si.

Para gerar, por exemplo, 20 variantes de cada questão-base:

```bash
Rscript tools/generate_lancamento_obliquo_listas_2026.R 20
```
