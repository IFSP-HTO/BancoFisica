# Auditoria visual das expansões recentes — Óptica geométrica

Refs #131.

## Escopo e procedência

O PR #126 adicionou **15 questões autorais** de Óptica geométrica (`Q98`–`Q112`). O próprio PR registra que o volume 2 de *Compreendendo a Física*, de Alberto Gaspar, foi usado como referência pedagógica, sem transcrição de enunciados.

Esta auditoria inspecionou as questões atuais e as páginas correspondentes do volume 2. Uma figura do livro só é indicada quando é realmente compatível com a situação da questão e não introduz dados numéricos conflitantes nem entrega de maneira inadequada a resposta.

## Resultado

| Classificação | Quantidade |
|---|---:|
| **usar original** | **8** |
| adaptar para original | 0 |
| sem figura necessária | 7 |
| manter procedural | 0 |
| **Total** | **15** |

## Auditoria questão por questão

| Questão | Classificação | Referência visual | Justificativa |
|---|---|---|---|
| `Q98QuizRetrovisorConvexo.Rnw` | **usar original** | Gaspar v.2, p. 91, fotografia de espelho convexo destacando a ampliação do campo de visão | A imagem original ilustra exatamente a vantagem cobrada no item e não contém parâmetros numéricos. |
| `Q99QuizImagemEspelhoConcavo.Rnw` | sem figura necessária | Gaspar v.2, p. 99 contém o traçado específico para objeto entre foco e vértice | Esse traçado já mostra diretamente a configuração que constitui a alternativa correta (imagem virtual, direita e ampliada). Inserir a figura tornaria o item quase uma leitura da resposta. |
| `Q100ClozeEspelhoEsfericoEquacao.Rnw` | sem figura necessária | — | Problema quantitativo parametrizado pela equação dos pontos conjugados; não depende de geometria adicional. |
| `Q101ClozeAumentoEspelhoConcavo.Rnw` | sem figura necessária | — | Cálculo parametrizado de posição e aumento; uma construção de raios fixa poderia não corresponder a todas as razões `p/f` sorteadas. |
| `Q102NumAnguloLimite.Rnw` | **usar original** | Gaspar v.2, p. 112, sequência genérica de refração até o ângulo limite e reflexão total | A figura mostra exatamente a geometria de `theta_L`, com raio refratado rasante no limite, sem valores numéricos fixos que conflitem com `n_1` sorteado. |
| `Q103QuizFibraOptica.Rnw` | **usar original** | Gaspar v.2, p. 127, trajetória de um raio no núcleo de uma fibra óptica | Correspondência direta com o mecanismo cobrado: confinamento da luz por reflexões totais internas na interface núcleo–casca. |
| `Q104QuizPrismaDispersao.Rnw` | **usar original** | Gaspar v.2, p. 118, fotografia da dispersão da luz branca em um prisma | A fotografia original representa diretamente o fenômeno perguntado sem antecipar verbalmente a explicação física. |
| `Q105ClozeLenteConvergente.Rnw` | sem figura necessária | — | A posição do objeto varia com a razão `p/f`; uma construção de raios fixa não representaria de modo fiel todas as variantes. |
| `Q106ClozeAumentoLente.Rnw` | sem figura necessária | — | Mesma razão: a questão é quantitativa e parametrizada; uma figura fixa poderia sugerir uma razão geométrica diferente. |
| `Q107QuizLenteDivergente.Rnw` | sem figura necessária | Gaspar v.2, pp. 134 e 138 apresentam focos e construções para lentes divergentes | As construções que mostram a imagem também exibem justamente as propriedades perguntadas (virtual, direita e menor), funcionando como resposta visual. O esquema genérico de foco não acrescenta informação necessária. |
| `Q108ClozeMiopiaCorrecao.Rnw` | **usar original** | Gaspar v.2, p. 150, olho míope e correção com lente divergente | O diagrama é conceitual e genérico; ajuda a interpretar o sinal negativo da distância focal/vergência sem conflitar com o ponto remoto sorteado. |
| `Q109ClozeHipermetropiaCorrecao.Rnw` | **usar original** | Gaspar v.2, p. 151, olho hipermétrope e correção com lente convergente | A figura mostra a correção conceitual sem fixar o ponto próximo usado numericamente pela questão. |
| `Q110QuizCameraFotografica.Rnw` | **usar original** | Gaspar v.2, p. 164, esquema simplificado de câmera fotográfica com lente e sensor | A figura mostra a geometria real do instrumento e a formação da imagem no sensor, exatamente o contexto da questão. |
| `Q111QuizLupa.Rnw` | **usar original** | Gaspar v.2, p. 155, lupa (microscópio simples) com objeto, lente, olho e imagem virtual ampliada | É o esquema original do instrumento perguntado. A questão permanece conceitual, mas ganha a representação física correta da lupa. |
| `Q112QuizImagemRealAnteparo.Rnw` | sem figura necessária | Gaspar v.2, pp. 146–147, atividade de projeção de imagem real em anteparo | A atividade original mostra explicitamente o procedimento que é a alternativa correta. Inserir esse visual no item de múltipla escolha entregaria a resposta. |

## Correções em relação à triagem preliminar

A triagem anterior usava páginas aproximadas (por exemplo, p. 102 para retrovisor, p. 129 para fibra e p. 166 para câmera). A inspeção da fonte corrigiu os pontos principais para **p. 91**, **p. 127** e **p. 164**, respectivamente. O mesmo critério foi aplicado aos demais itens.

Assim, dos 15 itens de Óptica, **8** devem avançar para revisão visual com figuras originais e **7** devem permanecer sem figura.
