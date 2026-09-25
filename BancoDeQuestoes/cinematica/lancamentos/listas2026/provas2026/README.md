# Listas Moodle derivadas das três provas de lançamento oblíquo — 2026

Este diretório documenta o mapeamento entre as três avaliações impressas de
lançamento oblíquo e as questões-base parametrizadas do BancoFisica.

O objetivo do gerador dedicado é produzir **um XML por turma**, com a seguinte
estrutura lógica no Moodle:

```text
BancoFisica/Listas 2026/Lancamento Obliquo/<Turma>/
  Q01/  -> 50 réplicas
  Q02/  -> 50 réplicas
  ...
  Q10/  -> 50 réplicas
```

Assim, o professor pode criar um questionário com uma questão aleatória de
cada categoria Q01--Q10.

## Associação das provas

- **Mecânica**: lote impresso `LO-2609`;
- **Informática**: lote impresso `LO2-2609` (T2);
- **Automação**: lote impresso `LO3-2609` (T3).

## Mapeamento para as questões-base

| Q | Mecânica | Informática | Automação |
|---|---|---|---|
| Q01 | `lista1/Q09QuizPanossoEstroboscopica.Rnw` | `lista1/Q13QuizCebolinhaTempoVoo.Rnw` | `lista1/Q01QuizUEPG2011Conceitos.Rnw` |
| Q02 | `lista1/Q05QuizPUCSPConceitualApice.Rnw` | `lista1/Q03ClozeComponentes100ms.Rnw` | `lista2/Q09ClozePele1970.Rnw` |
| Q03 | `lista1/Q07QuizUELVelocidadeApice.Rnw` | `lista1/Q02QuizUFT2010AlturaMaxima.Rnw` | `lista2/Q08ClozeCanhao30e60.Rnw` |
| Q04 | `lista1/Q10QuizSalto45graus10ms.Rnw` | `lista2/Q07ClozeFutebol108kmh60graus.Rnw` | `reserva/Q10ClozeBasqueteApice05s.Rnw` |
| Q05 | `lista1/Q06QuizUERJMassasAlcance.Rnw` | `lista1/Q11ClozeProjetil10msTrig.Rnw` | `reserva/Q09ClozeDebretFlecha45.Rnw` |
| Q06 | `lista2/Q04QuizFESOMesmaAltura.Rnw` | `lista1/Q04ClozeAltura72VelTopo10.Rnw` | `reserva/Q02ClozeUFOP2010EdificioCorrigida.Rnw` |
| Q07 | `lista1/Q15QuizBalisticaTempo6s.Rnw` | `lista2/Q14ClozeGoleiroIntercepta18m.Rnw` | `reserva/Q07QuizObstaculo64m.Rnw` |
| Q08 | `lista1/Q12ClozeFaltaAltura5m.Rnw` | `lista2/Q12ClozeAltura5Alcance40.Rnw` | `reserva/Q03ClozeUFU2010Ronaldinho.Rnw` |
| Q09 | `lista2/Q01QuizUFTM2011Volei.Rnw` | `lista2/Q13ClozeFlechaH80A240.Rnw` | `lista2/Q05ClozeMotocicletaFuscas.Rnw` |
| Q10 | `lista1/Q14ClozePescaria30graus.Rnw` | `lista2/Q10ClozeDaianeGrafico.Rnw` | `reserva/Q06QuizBalistica45Alcance360.Rnw` |

As provas impressas converteram algumas questões-base `cloze`/`mchoice`
em uma única alternativa A--E. Para as listas de estudo no Moodle, o gerador
usa a **versão canônica parametrizada do BancoFisica**, preservando o conteúdo
e a habilidade da questão-base. Em alguns itens, portanto, a versão Moodle é
mais rica que a forma reduzida usada na prova impressa.

## Geração

Por padrão são produzidas 50 réplicas por questão:

```bash
Rscript tools/generate_lancamento_obliquo_provas_2026.R
```

Ou, explicitamente:

```bash
Rscript tools/generate_lancamento_obliquo_provas_2026.R 50
```

Arquivos de saída:

```text
build/lancamento-obliquo-provas-2026/
  lancamento-obliquo-automacao.xml
  lancamento-obliquo-informatica.xml
  lancamento-obliquo-mecanica.xml
```

Cada XML deve conter exatamente 10 categorias e 500 variantes. O gerador
falha se um arquivo único exceder 10 MiB, respeitando o limite operacional
adotado para importação no Moodle institucional.

Nenhum dado de estudante é utilizado ou armazenado neste fluxo.


## Tamanho dos XMLs e figuras

Com 50 réplicas, repetir imagens em base64 em cada variante pode ultrapassar o
limite de aproximadamente 10 MiB do Moodle. Para preservar **um único XML por
turma**, o montador remove imagens apenas quando elas são ilustrativas e todas
as informações necessárias já aparecem no enunciado.

São preservadas as figuras que carregam informação indispensável à resolução,
como a comparação gráfica das trajetórias na Mecânica e o gráfico do salto na
Informática. A remoção não altera parâmetros, respostas nem o número de
réplicas.
