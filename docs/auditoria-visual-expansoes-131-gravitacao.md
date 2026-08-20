# Auditoria visual das expansões recentes — Gravitação e Astronomia

Refs #131.

## Escopo e procedência

O PR #124 adicionou **15 questões autorais** em `BancoDeQuestoes/gravitacao/`. Conforme `docs/expansao-gravitacao-astronomia.md`, o volume 1 de *Compreendendo a Física*, de Alberto Gaspar, foi usado como referência de sequência pedagógica; as questões não são transcrições ou adaptações 1:1 dos exercícios do livro.

A triagem visual antiga associou seis itens a páginas do Gaspar, mas a inspeção página a página mostrou que parte dessas associações estava errada: algumas páginas apontadas pertencem a outros tópicos ou apresentam situações distintas. Esta auditoria registra apenas correspondências realmente compatíveis.

## Resultado

| Classificação | Quantidade |
|---|---:|
| **usar original** | **2** |
| adaptar para original | 0 |
| sem figura necessária | 13 |
| manter procedural | 0 |
| **Total** | **15** |

## Auditoria questão por questão

| Questão | Classificação | Referência visual | Justificativa |
|---|---|---|---|
| `Q01QuizLeisKepler.Rnw` | sem figura necessária | Gaspar v.1, p. 243 contém o diagrama da segunda lei | O item compara enunciados das três leis e a alternativa correta é justamente a segunda lei. Mostrar o diagrama de áreas iguais funcionaria quase como pista direta para a alternativa correta; o texto é suficiente. |
| `Q02ClozeTerceiraLeiKepler.Rnw` | sem figura necessária | — | Relação quantitativa entre raios orbitais e períodos; nenhuma geometria adicional é necessária. |
| `Q03QuizSegundaLeiVelocidade.Rnw` | **usar original** | Gaspar v.1, p. 243, órbita elíptica com setores de áreas iguais | O diagrama representa exatamente o raciocínio usado no item: para áreas iguais em tempos iguais, o planeta percorre arco maior quando está mais próximo do Sol e sua velocidade é maior no periastro. |
| `Q04ClozeLeiGravitacaoUniversal.Rnw` | sem figura necessária | — | Aplicação escalar da lei do inverso do quadrado a planeta e sonda. |
| `Q05NumCampoGravitacionalAltura.Rnw` | **usar original** | Gaspar v.1, p. 249, esquema da Terra com `r_T`, altitude `h` e distância `r_T+h` ao centro | O desenho é genérico, sem valores fixos, e corresponde exatamente à geometria necessária para entender por que o campo deve ser calculado na distância ao centro, não apenas na altitude. |
| `Q06QuizPesoAstronautaOrbita.Rnw` | sem figura necessária | Gaspar v.1, p. 251 contém fotografia de estação/satélite | A fotografia é apenas ilustrativa e não explica por si só a queda livre conjunta de astronauta e estação. Não há uma figura original diretamente equivalente à situação conceitual do item. |
| `Q07NumVelocidadeOrbital.Rnw` | sem figura necessária | Gaspar v.1, p. 250 desenvolve a dedução de `v=sqrt(GM/r)` | A questão é quantitativa e já fornece todos os dados. A fonte apresenta a dedução principalmente em texto/equações, não um diagrama indispensável. |
| `Q08ClozePeriodoOrbitalCircular.Rnw` | sem figura necessária | — | Cálculo de velocidade e período de uma órbita circular completamente definido por `M` e `r`. |
| `Q09QuizSateliteGeoestacionario.Rnw` | sem figura necessária | Gaspar v.1, p. 161 mostra uma órbita circular de satélite como exemplo de MCU | A figura é apenas um exemplo geral de satélite em órbita circular e não representa as condições específicas de uma órbita geoestacionária (plano equatorial, período igual ao da rotação e mesmo sentido). Inserí-la seria decorativo e poderia sugerir uma correspondência mais forte do que a fonte oferece. |
| `Q10ClozeGeoestacionarioComparacaoLua.Rnw` | sem figura necessária | Gaspar v.1, p. 167 apresenta um exemplo com altitude geoestacionária de cerca de 36 000 km | Inserir esse esquema revelaria aproximadamente o resultado que a questão pede ao aluno estimar pela terceira lei de Kepler; por isso não deve ser usado como estímulo. |
| `Q11QuizMassaPesoAltitude.Rnw` | sem figura necessária | — | Distinção conceitual entre massa e peso com a altitude; não depende de diagrama. |
| `Q12NumEscalonamentoForcaGravitacional.Rnw` | sem figura necessária | — | Escalonamento algébrico da lei da gravitação; figura seria decorativa. |
| `Q13QuizCampoGravitacionalPontoMedio.Rnw` | sem figura necessária | Gaspar v.1, pp. 247–248 mostram campos gravitacionais de corpos isolados | Não foi localizado no livro um diagrama genérico de duas massas iguais com ponto médio equivalente ao item. As figuras existentes tratam campos de um único corpo ou outras geometrias. |
| `Q14ClozeEnergiaPotencialUniversal.Rnw` | sem figura necessária | — | Cálculo escalar de energia potencial gravitacional. |
| `Q15ClozeVelocidadeEscape.Rnw` | sem figura necessária | — | Aplicação quantitativa de conservação de energia/velocidade de escape; não depende de figura específica. |

## Correções em relação à triagem antiga

As referências preliminares a páginas 253, 256 e 285 como fontes de figuras para satélites/astronautas não se sustentam na inspeção do volume: essas páginas pertencem a atividades posteriores ou a outros capítulos. A p. 161 também foi retirada após a revisão visual do recorte: ela mostra apenas um satélite em órbita circular, não uma representação específica da condição geoestacionária.

Assim, dos 15 itens, apenas **2** devem avançar para a revisão visual com figura original.
