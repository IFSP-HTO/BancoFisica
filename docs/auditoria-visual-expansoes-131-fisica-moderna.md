# Auditoria visual das expansões recentes — Física Moderna

Refs #131.

## Escopo e procedência

O PR #122 adicionou **18 questões autorais** de Física Moderna. Conforme `docs/expansao-fisica-moderna.md`, o volume 3 de *Compreendendo a Física*, de Alberto Gaspar, foi usado como referência de sequência didática e de seleção temática; situações, parâmetros, alternativas e soluções foram reescritos para o BancoFisica.

Assim, esta auditoria não presume que cada item tenha uma “figura original faltante”. Só se recomenda incorporar uma figura do livro quando ela corresponde diretamente ao raciocínio da questão atual e não conflita com sua parametrização.

## Resultado

| Classificação | Quantidade |
|---|---:|
| **usar original** | **3** |
| adaptar para original | 0 |
| sem figura necessária | 15 |
| manter procedural | 0 |
| **Total** | **18** |

## Auditoria questão por questão

| Questão | Classificação | Referência visual | Justificativa |
|---|---|---|---|
| `Q91ClozeFotonsEnergiaComprimento.Rnw` | sem figura necessária | — | Relação quantitativa entre comprimento de onda, frequência e energia do fóton. |
| `Q92QuizFotoeletricoFrequenciaCorte.Rnw` | sem figura necessária | — | Questão conceitual sobre frequência de corte/intensidade; autossuficiente no texto. |
| `Q93ClozeFotoeletricoEnergiaPotencial.Rnw` | sem figura necessária | — | Cálculo quantitativo de energia do fóton, energia cinética e potencial de corte. |
| `Q94QuizGraficoFotoeletrico.Rnw` | **usar original** | Gaspar v.3, p. 213, gráfico experimental `E_c,max x f` / tensão de corte × frequência | A questão fala explicitamente do gráfico `K_max x f`, mas não o mostra. O gráfico da p. 213 exibe a reta, a inclinação e a frequência de corte e é diretamente compatível com a interpretação pedida. |
| `Q95ClozeBohrTransicao.Rnw` | sem figura necessária | Gaspar v.3, p. 276 contém diagramas de órbitas/transições | A questão sorteia pares de níveis `n_i -> n_f`. As transições desenhadas no livro são casos fixos e não correspondem a todas as variantes; o cálculo já é completamente definido pela fórmula de `E_n`. |
| `Q96QuizBohrAbsorcaoEmissao.Rnw` | sem figura necessária | Gaspar v.3, p. 276 contém exemplos fixos de emissão/absorção | O item sorteia níveis inicial e final. Inserir o exemplo fixo do livro poderia contradizer a variante sorteada. |
| `Q97NumDeBroglieEletron.Rnw` | sem figura necessária | — | Cálculo direto do comprimento de onda de De Broglie. |
| `Q98QuizDeBroglieMacroMicro.Rnw` | sem figura necessária | — | Comparação conceitual de ordens de grandeza; não depende de geometria. |
| `Q99QuizPrincipioIncerteza.Rnw` | sem figura necessária | — | Questão conceitual sobre incerteza; figura seria apenas ilustrativa. |
| `Q100QuizDifracaoEletrons.Rnw` | sem figura necessária | — | O resultado experimental é descrito no enunciado e a pergunta é sobre seu significado físico. Uma imagem de difração seria enriquecimento, não informação necessária. |
| `Q101ClozeRelatividadeDilatacaoTempo.Rnw` | sem figura necessária | — | Problema quantitativo definido por `v` e intervalo próprio. |
| `Q102NumRelatividadeContracaoComprimento.Rnw` | sem figura necessária | — | Problema quantitativo definido por `L_0` e velocidade relativa. |
| `Q103QuizRelatividadeSimultaneidade.Rnw` | **usar original** | Gaspar v.3, p. 233, sequência em quatro quadros trem/plataforma | A situação atual reproduz exatamente o experimento mental do livro: sinais luminosos nas extremidades, observador no meio da plataforma e observador no meio do trem. A sequência original torna visualmente explícita a relatividade da simultaneidade sem introduzir parâmetros incompatíveis. |
| `Q104NumEquivalenciaMassaEnergia.Rnw` | sem figura necessária | — | Aplicação direta de `E=Delta m c^2`. |
| `Q105NumFusaoEnergiaLigacao.Rnw` | sem figura necessária | — | A questão fornece numericamente as energias de ligação necessárias. |
| `Q106QuizFissaoFusaoCurvaLigacao.Rnw` | **usar original** | Gaspar v.3, p. 293, curva de energia de ligação por núcleon e esquema fusão/fissão | O item começa descrevendo uma curva que deveria ser observada. A fonte possui exatamente a curva e a interpretação visual de fusão/fissão em direção a núcleos mais fortemente ligados. |
| `Q107QuizRadiacoesAlphaBetaGamma.Rnw` | sem figura necessária | — | As propriedades cobradas são explicitamente textuais; nenhum diagrama é necessário para distinguir carga/penetração. |
| `Q108ClozeDatacaoMeiaVida.Rnw` | sem figura necessária | — | Problema quantitativo de decaimento/meia-vida. |

## Observações

A triagem antiga superestimava o número de figuras “omitidas” neste lote. Em particular, diagramas de Bohr existentes no livro não devem ser inseridos em Q95/Q96 sem alterar a parametrização, pois eles representam transições específicas, enquanto as questões sorteiam vários pares de níveis.

Os três casos classificados como **usar original** são diferentes: neles o visual da fonte representa exatamente a estrutura conceitual que o texto atual já pressupõe e não conflita com variantes aleatórias.
