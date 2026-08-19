# Auditoria visual das expansões recentes — Mecânica

Refs #131.

## Escopo

Este documento audita as **31 questões autorais** adicionadas no PR #120:

- 10 de MUV;
- 6 de queda livre / lançamento vertical;
- 9 de forças e Leis de Newton;
- 6 de atrito.

A auditoria corrige uma premissa da triagem visual anterior: o lote não adapta exercícios específicos de *Compreendendo a Física* de forma 1:1. Conforme `docs/expansao-muv-queda-newton.md`, as questões foram escritas de forma autoral e parametrizada, usando o volume 1 de Alberto Gaspar como referência de sequência didática.

Por isso, uma figura do livro só é indicada abaixo quando ela é realmente compatível com a situação da questão atual e não introduz valores, geometria ou informação incompatíveis.

## Classificação

- **usar original** — existe no Gaspar uma figura diretamente compatível com a situação atual e ela pode substituir a ausência de visual sem alterar a lógica da questão;
- **adaptar para original** — existe figura original muito adequada, mas a parametrização atual precisa ser restringida para permanecer coerente com ela;
- **sem figura necessária** — o item é autossuficiente em texto/equações, ou a figura disponível na referência não corresponde suficientemente ao item atual;
- **manter procedural** — reservado a figuras que precisem acompanhar parâmetros sorteados; não houve caso desse tipo neste lote, pois as 31 questões atuais não contêm figura procedural.

## Resultado

| Área | Questões | Usar original | Adaptar para original | Sem figura necessária | Manter procedural |
|---|---:|---:|---:|---:|---:|
| MUV | 10 | 2 | 0 | 8 | 0 |
| Queda livre / vertical | 6 | 0 | 0 | 6 | 0 |
| Leis de Newton — forças | 9 | 3 | 0 | 6 | 0 |
| Atrito | 6 | 1 | 1 | 4 | 0 |
| **Total** | **31** | **6** | **1** | **24** | **0** |

## Auditoria questão por questão

### MUV

| Questão | Classificação | Referência visual | Justificativa |
|---|---|---|---|
| `Q92ClozeFuncaoHorariaMUV.Rnw` | sem figura necessária | — | Cálculo direto com `v=v_0+at` e deslocamento; nenhum dado depende de representação gráfica. |
| `Q93ClozeTorricelliAceleracao.Rnw` | sem figura necessária | — | A situação é inteiramente definida por velocidade, aceleração e deslocamento. |
| `Q94QuizGraficoVelocidadeMUV.Rnw` | **usar original** | Gaspar v.1, p. 79, gráfico genérico `v x t` de aceleração positiva | O enunciado fala explicitamente de uma reta crescente que não passa pela origem, mas não mostra o gráfico. O gráfico genérico da p. 79 representa exatamente essa geometria e não contém valores numéricos que conflitem com a questão. |
| `Q95ClozeFrenagemTempoDistancia.Rnw` | sem figura necessária | — | Problema quantitativo de frenagem definido pelos parâmetros sorteados. |
| `Q96ClozePartidaRepouso.Rnw` | sem figura necessária | — | Cálculo direto a partir de repouso; figura não acrescenta informação necessária. |
| `Q97QuizSinaisVelocidadeAceleracao.Rnw` | sem figura necessária | — | O item pergunta diretamente sobre sinais de velocidade e aceleração. A antiga associação a um gráfico do livro era incorreta: a questão atual é puramente verbal. |
| `Q98ClozeEncontroMUVMU.Rnw` | sem figura necessária | — | Encontro de dois móveis definido pelas funções/condições do enunciado; não há figura-fonte 1:1 necessária. |
| `Q99ClozeAreaGraficoVelocidade.Rnw` | **usar original** | Gaspar v.1, p. 79, gráfico genérico da área sob `v x t` | A questão pede explicitamente interpretação de um gráfico `v x t`, mas não o apresenta. O esquema da p. 79 usa apenas `v_0`, `v`, `t` e a área `A`, sem valores fixos, portanto continua coerente com os parâmetros sorteados. |
| `Q100QuizFuncaoPosicaoMUV.Rnw` | sem figura necessária | — | Leitura algébrica dos coeficientes de `s(t)`. |
| `Q101ClozeVelocidadeMediaMUV.Rnw` | sem figura necessária | — | Relações quantitativas de MUV sem necessidade visual. |

### Queda livre e lançamento vertical

| Questão | Classificação | Justificativa |
|---|---|---|
| `Q94ClozeQuedaLivrePonte.Rnw` | sem figura necessária | A altura, `g` e as grandezas pedidas definem completamente o problema. |
| `Q95ClozeQuedaLivreTempo.Rnw` | sem figura necessária | Cálculo direto de queda a partir do repouso. |
| `Q96ClozeLancamentoVerticalSubida.Rnw` | sem figura necessária | Tempo de subida e altura máxima são obtidos diretamente dos dados. |
| `Q97ClozeLancamentoVerticalRetorno.Rnw` | sem figura necessária | Simetria temporal/cinemática suficiente no texto. |
| `Q98QuizTopoLancamentoVertical.Rnw` | sem figura necessária | Questão conceitual sobre `v=0` e aceleração gravitacional no topo; desenho não é necessário. |
| `Q99ClozeDistanciasQuedaSucessivas.Rnw` | sem figura necessária | O item trabalha intervalos temporais sucessivos; não depende de uma figura específica da fonte. |

### Leis de Newton — forças

| Questão | Classificação | Referência visual | Justificativa |
|---|---|---|---|
| `Q93ClozeSegundaLeiHorizontal.Rnw` | sem figura necessária | — | Situação elementar de força resultante horizontal. |
| `Q94ClozeForcasOpostas.Rnw` | sem figura necessária | — | O enunciado fornece diretamente os módulos e sentidos. |
| `Q95QuizPrimeiraLeiOnibus.Rnw` | sem figura necessária | — | Questão conceitual de inércia; ilustração seria decorativa. |
| `Q96QuizTerceiraLeiEmpurrao.Rnw` | sem figura necessária | — | Ação e reação são descritas explicitamente; não depende de geometria. |
| `Q97ClozeElevadorNormal.Rnw` | sem figura necessária | — | Peso aparente em elevador pode ser resolvido diretamente; a fonte também trata o caso textualmente. |
| `Q98ClozeDoisBlocosContato.Rnw` | **usar original** | Gaspar v.1, p. 141, exercício 11 | A figura mostra exatamente dois blocos `A` e `B` em contato num plano horizontal sem atrito, com força `F` aplicada a `A`. Não há valores impressos dentro do diagrama, então a randomização de massas e força pode ser preservada. |
| `Q99ClozeBlocosCorda.Rnw` | **usar original** | Gaspar v.1, p. 137, exercício 8 | O diagrama mostra exatamente dois blocos `A` e `B` ligados por fio num plano horizontal sem atrito e força `F` aplicada ao bloco `A`; é compatível com os parâmetros sorteados. |
| `Q100QuizMassaPeso.Rnw` | sem figura necessária | — | Distinção conceitual entre massa e peso. |
| `Q101ClozePlanoInclinadoSemAtrito.Rnw` | **usar original** | Gaspar v.1, p. 144, seção “Forças e movimento em um plano inclinado” | O esquema é genérico, usa ângulo `alpha` e mostra peso, normal e decomposição do peso sem valores numéricos fixos. É compatível com `theta` sorteado em 30°, 37° ou 53°. |

### Atrito

| Questão | Classificação | Referência visual | Justificativa |
|---|---|---|---|
| `Q93ClozeAtritoHorizontal.Rnw` | sem figura necessária | — | Aplicação direta de `f=mu N` e segunda lei. |
| `Q94QuizAtritoEstaticoAdaptativo.Rnw` | sem figura necessária | Gaspar v.1, p. 151 contém um gráfico `F_at x F` | O gráfico é conceitualmente relevante, mas traz escala e valores de um caso específico do livro, enquanto a questão sorteia `m`, `mu` e `F`. Inserir a figura sem alterar a questão criaria duas situações numéricas concorrentes. |
| `Q95ClozeAtritoEstaticoMaximo.Rnw` | sem figura necessária | — | O valor máximo é calculado diretamente a partir de `mu_e N`. |
| `Q96ClozePlanoInclinadoComAtrito.Rnw` | **adaptar para original** | Gaspar v.1, pp. 151–152, exercício resolvido 6 / resolução | O original mostra exatamente um bloco em plano inclinado com atrito a 37° e a resolução contém os vetores relevantes. A questão atual sorteia 37° ou 53°. Para usar a original sem incoerência, a variante visual deve ser restrita a 37° (mantendo a randomização do coeficiente de atrito) ou o item deve ser separado em variantes compatíveis. |
| `Q97QuizCaminharAtrito.Rnw` | **usar original** | Gaspar v.1, p. 154, seção “A força de atrito como força motora” | A sequência original mostra a pessoa empurrando o chão para trás e a força de atrito estático do chão sobre o pé para a frente, exatamente o fenômeno perguntado. |
| `Q98ClozePuxandoCaixaAngulo.Rnw` | sem figura necessária | — | A questão usa força a 37° acima da horizontal. Na seção auditada do Gaspar não foi localizada uma figura original que represente essa geometria de modo direto e sem introduzir outra situação física; portanto não se deve reutilizar uma figura apenas por semelhança temática. |

## Consequência para a triagem anterior

A antiga triagem tratava vários itens como se uma figura do Gaspar tivesse sido omitida durante uma adaptação. Esta auditoria mostra que isso não é verdade para o lote de Mecânica: **24 das 31 questões não precisam receber figura do livro**. Há seis casos em que um visual original encaixa diretamente e um caso em que o uso do original exige adaptar a parametrização.

## Próximo passo

Após concluir a mesma auditoria para Física Moderna, Eletromagnetismo, Gravitação/Astronomia e Óptica, os casos `usar original` e `adaptar para original` devem ser apresentados para revisão visual antes de qualquer alteração das questões.