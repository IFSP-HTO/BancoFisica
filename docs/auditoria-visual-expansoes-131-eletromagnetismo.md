# Auditoria visual das expansões recentes — Eletromagnetismo

Refs #131.

## Escopo e procedência

O PR #123 adicionou **24 questões autorais** de Eletromagnetismo: 8 de eletrostática, 10 de magnetismo e 6 de indução/transformadores. Conforme `docs/expansao-eletromagnetismo-magnetismo.md`, o volume 3 de *Compreendendo a Física*, de Alberto Gaspar, foi usado como referência de progressão didática; os enunciados não são adaptações 1:1 de exercícios do livro.

A auditoria, portanto, só recomenda uma figura original quando ela é diretamente compatível com a geometria e o raciocínio da questão atual, sem introduzir valores ou condições conflitantes.

## Resultado

| Área | Questões | Usar original | Adaptar para original | Sem figura necessária | Manter procedural |
|---|---:|---:|---:|---:|---:|
| Eletrostática | 8 | 2 | 0 | 6 | 0 |
| Magnetismo | 10 | 9 | 0 | 1 | 0 |
| Indução / transformadores | 6 | 4 | 0 | 2 | 0 |
| **Total** | **24** | **15** | **0** | **9** | **0** |

## Auditoria questão por questão

### Eletrostática

| Questão | Classificação | Referência visual | Justificativa |
|---|---|---|---|
| `Q92QuizEletrizacaoAtrito.Rnw` | sem figura necessária | — | A questão cobra transferência de elétrons e conservação da carga; a situação é completamente definida pelo texto. |
| `Q93ClozeLeiCoulomb.Rnw` | sem figura necessária | — | Cálculo escalar de força e lei do inverso do quadrado; nenhuma geometria adicional é necessária. |
| `Q94ClozeSuperposicaoCampoLinha.Rnw` | sem figura necessária | Gaspar v.3, pp. 35–38 contêm exemplos de soma vetorial de campos | Os exemplos do livro usam geometrias e conjuntos de cargas diferentes. Não há um diagrama original genérico com duas cargas positivas desiguais e ponto médio que possa ser inserido sem sugerir outra configuração. |
| `Q95ClozeCampoCargaPuntiforme.Rnw` | sem figura necessária | — | O item pede apenas módulos do campo e da força a uma distância dada. |
| `Q96QuizLinhasCampo.Rnw` | **usar original** | Gaspar v.3, p. 39, exemplos de linhas de força para carga positiva, negativa e pares de cargas | O próprio objeto conceitual cobrado é visual. A página mostra exatamente as propriedades discutidas (origem/sentido das linhas, não cruzamento e configuração para pares) sem depender de parâmetros numéricos. |
| `Q97ClozePotencialCargaPuntiforme.Rnw` | sem figura necessária | — | Cálculo escalar de potencial e energia potencial. |
| `Q98ClozeTrabalhoDDP.Rnw` | sem figura necessária | — | A questão é inteiramente definida pelos potenciais inicial/final e pela carga. |
| `Q99ClozeCampoUniformeDDP.Rnw` | **usar original** | Gaspar v.3, p. 43, esquema de duas placas paralelas e campo elétrico uniforme | O esquema é genérico, sem valores fixos, e representa exatamente a geometria do item: placas paralelas, separação e campo aproximadamente uniforme entre elas. |

### Magnetismo

| Questão | Classificação | Referência visual | Justificativa |
|---|---|---|---|
| `Q01QuizPolosImas.Rnw` | **usar original** | Gaspar v.3, p. 152, sequência de corte de ímã e formação de novos dipolos | A questão cobra simultaneamente interação entre polos e impossibilidade de isolar um polo ao cortar o ímã. A sequência original representa diretamente a segunda ideia sem valores incompatíveis. |
| `Q02QuizLinhasCampoIma.Rnw` | **usar original** | Gaspar v.3, p. 153, linhas de campo de ímã de barra | É correspondência direta: as linhas externas saem do polo norte e entram no sul e completam linhas fechadas. |
| `Q03ClozeCampoFioRetilineo.Rnw` | **usar original** | Gaspar v.3, p. 169, esquema genérico do campo ao redor de um fio retilíneo longo | O diagrama usa apenas `i`, `r` e `B`, sem valores, e é compatível com qualquer variante numérica da questão. |
| `Q04ClozeCampoEspira.Rnw` | **usar original** | Gaspar v.3, p. 176, espira circular com corrente e centro `O` | O desenho da espira é genérico e não fixa raio nem corrente na própria figura; pode acompanhar a parametrização atual. |
| `Q05ClozeCampoSolenoide.Rnw` | **usar original** | Gaspar v.3, p. 175, solenoide e linhas de campo | A figura representa diretamente a geometria e o campo quase uniforme no interior do solenoide, sem valores numéricos. |
| `Q06ClozeForcaCargaMagnetica.Rnw` | **usar original** | Gaspar v.3, pp. 155–156, geometria vetorial de `v`, `B` e `F` / regra da mão direita | A questão depende do ângulo entre `v` e `B`. O esquema vetorial original esclarece essa geometria e continua válido para os ângulos sorteados. |
| `Q07QuizDirecaoForcaMagnetica.Rnw` | sem figura necessária | Gaspar v.3, pp. 155–157 contêm regra da mão direita e exemplos resolvidos | O item foi construído para testar justamente a aplicação da regra a uma orientação verbal específica. Inserir um exemplo resolvido ou a mão com os vetores tornaria a resposta excessivamente guiada; o texto atual define sem ambiguidade `v` e `B`. |
| `Q08ClozeRaioTrajetoriaCarga.Rnw` | **usar original** | Gaspar v.3, p. 158, trajetória circular de carga positiva em campo uniforme | A figura mostra exatamente a força magnética atuando como centrípeta e não fixa os valores de `m`, `q`, `v` ou `B` usados pela questão. |
| `Q09ClozeForcaFioCampo.Rnw` | **usar original** | Gaspar v.3, p. 160, condutor retilíneo de comprimento `l` em campo `B` formando ângulo `theta` | O esquema é genérico e coincide com a expressão `F=Bi l sen(theta)` usada no item; não conflita com os parâmetros sorteados. |
| `Q10QuizMotorEletrico.Rnw` | **usar original** | Gaspar v.3, pp. 164–165, espira entre polos, forças opostas, comutador e rotação | É a representação direta do princípio perguntado: forças magnéticas em lados opostos da espira formam um binário e produzem torque. |

### Indução e transformadores

| Questão | Classificação | Referência visual | Justificativa |
|---|---|---|---|
| `Q01ClozeFluxoMagnetico.Rnw` | sem figura necessária | Gaspar v.3, p. 183 contém casos fixos de orientação de espiras | A questão sorteia o ângulo entre o campo e a **normal** da espira (`0°, 30°, 60°`). As figuras da p. 183 mostram casos específicos e em parte usam o ângulo com o plano; inseri-las sem adaptar a questão poderia introduzir ambiguidade. |
| `Q02QuizLeiLenzIma.Rnw` | **usar original** | Gaspar v.3, p. 185, figura do polo norte aproximando-se de uma espira e resposta induzida de repulsão | A configuração é essencialmente idêntica à descrita no item e torna visualmente explícita a oposição à variação do fluxo. |
| `Q03ClozeFaradayVariacaoFluxo.Rnw` | sem figura necessária | — | Relação quantitativa entre variação do fluxo e intervalo de tempo; não depende de geometria. |
| `Q04QuizGeradorEletromagnetico.Rnw` | **usar original** | Gaspar v.3, pp. 189–191, sequência de rotação de uma espira em campo uniforme e forma de onda gerada | A sequência representa diretamente o princípio do gerador eletromagnético discutido na questão. |
| `Q05ClozeTransformadorIdeal.Rnw` | **usar original** | Gaspar v.3, p. 193, esquema genérico do transformador com núcleo, primário `N1` e secundário `N2` | O diagrama é genérico e compatível com razões de espiras e tensões parametrizadas. |
| `Q06QuizTransformadorCorrenteContinua.Rnw` | **usar original** | Gaspar v.3, pp. 192–193, sequência com bateria/chave mostrando indução apenas durante a variação da corrente | A situação corresponde exatamente ao enunciado: após o transiente em corrente contínua, o fluxo se estabiliza e a fem secundária deixa de existir. |

## Consequência

A triagem preliminar tratava praticamente todo o lote de Eletromagnetismo como visual. A auditoria rigorosa reduz isso para **15 casos diretamente compatíveis com figuras originais**. Nove questões são autossuficientes ou não possuem, no Gaspar, uma figura que represente a mesma situação sem alterar a questão.

Os 15 casos `usar original` devem entrar na revisão visual antes de qualquer alteração dos `.Rnw`.
