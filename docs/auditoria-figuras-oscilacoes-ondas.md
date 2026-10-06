# Auditoria visual — Oscilações e Ondas

Refs #140, #94 e #101.

## Regra visual

Quando uma questão adaptada possui figura relevante no material-fonte, o BancoFisica deve preservar a figura original da fonte. Figuras procedurais ficam restritas aos casos em que a leitura quantitativa depende dos parâmetros sorteados e não há equivalente fixo adequado.

## Inventário

A expansão de Oscilações, Ondas e Acústica contém 33 questões com gráfico ou esquema procedural/autoral.

### Etapa 1 — troca direta pela figura original (16)

1. `oscilacoes/energia/Q03QuizGraficoEnergiasPosicao.Rnw` — energias em função da posição; referência: Fig. 15.2.1(b).
2. `oscilacoes/energia/Q04QuizGraficoEnergiasTempo.Rnw` — energias em função do tempo; referência: Fig. 15.2.1(a).
3. `oscilacoes/pendulos/Q05ClozePenduloFisicoBarra.Rnw` — pêndulo físico em forma de barra.
4. `oscilacoes/ressonancia/Q01QuizGraficoOscilacaoAmortecida.Rnw` — oscilação amortecida; referência: Fig. 15.5.2.
5. `oscilacoes/ressonancia/Q05GraficoFrequenciaRessonancia.Rnw` — curva de ressonância; referência: Fig. 15.6.1.
6. `oscilacoes/ressonancia/Q06QuizGraficoAmortecimentoRessonancia.Rnw` — efeito do amortecimento na ressonância; referência: Fig. 15.6.1.
7. `ondas/progressivas/Q01QuizTransversalLongitudinal.Rnw` — ondas transversal e longitudinal; referência: figuras do início do Cap. 16.
8. `ondas/progressivas/Q10QuizEnergiaPerfilOnda.Rnw` — energia instantânea ao longo de uma onda; referência: Fig. 16.3.1.
9. `ondas/interferencia/Q01ClozeSuperposicaoPulsos.Rnw` — superposição de pulsos.
10. `ondas/interferencia/Q04QuizEsquemaCaminhos.Rnw` — diferença de caminho e interferência; referência: figuras da seção de interferência.
11. `ondas/estacionarias/Q04QuizComparacaoHarmonicos.Rnw` — comparação entre modos normais/harmônicos.
12. `ondas/acustica/Q01QuizSomLongitudinal.Rnw` — compressões e rarefações; referência: figura de onda sonora longitudinal do Cap. 17.
13. `ondas/acustica/Q04QuizFonteIsotropicaDistancia.Rnw` — fonte pontual e frentes de onda; referência: Fig. 17.1.2.
14. `ondas/tubos/Q01NumFundamentalTuboAberto.Rnw` — modo fundamental em tubo aberto-aberto.
15. `ondas/tubos/Q02NumFundamentalTuboFechado.Rnw` — modo fundamental em tubo fechado-aberto.
16. `ondas/doppler/Q05NumNumeroMach.Rnw` — cone de Mach/onda de choque.

Nessa etapa, a regra é preservar cálculo, resposta e gabarito sempre que a figura original puder substituir diretamente a procedural.

### Etapa 2 — adaptar a questão antes de usar a original (11)

1. `oscilacoes/mhs/Q03ClozeGraficoMHS.Rnw`.
2. `oscilacoes/mhs/Q06QuizSinaisVelocidadeAceleracao.Rnw`.
3. `oscilacoes/energia/Q05ClozeGraficoEnergiaAmplitude.Rnw`.
4. `ondas/progressivas/Q03ClozeGraficoAmplitudeComprimento.Rnw`.
5. `ondas/progressivas/Q06QuizPerfilEspacial.Rnw`.
6. `ondas/progressivas/Q08QuizComparacaoComprimentos.Rnw`.
7. `ondas/interferencia/Q05ClozeAmplitudeResultante.Rnw`.
8. `ondas/estacionarias/Q01ClozeNosAntinos.Rnw`.
9. `ondas/estacionarias/Q02NumComprimentoOndaPadrao.Rnw`.
10. `ondas/estacionarias/Q05NumRessonanciaPadrao.Rnw`.
11. `ondas/estacionarias/Q06QuizRazaoModosNormais.Rnw`.

Nesses itens, os valores ou o modo representado são sorteados no próprio gráfico. A troca pela figura fixa da fonte exige primeiro alinhar o enunciado e a parametrização ao visual original.

### Manter procedural (6)

- `oscilacoes/mhs/Q04QuizComparacaoMassaMola.Rnw`;
- `oscilacoes/mhs/Q07ClozeGraficoAceleracaoPosicao.Rnw`;
- `oscilacoes/mhs/Q11QuizComparacaoConstanteElastica.Rnw`;
- `oscilacoes/mhs/Q15ClozeGraficoForcaElastica.Rnw`;
- `oscilacoes/pendulos/Q04ClozeGraficoPenduloGravidade.Rnw`;
- `ondas/cordas/Q06GraficoVelocidadeTensao.Rnw`.

Aqui a figura carrega diretamente dados parametrizados da questão (inclinação de reta, valor de constante física ou comparação sorteada), por isso o visual procedural é funcional e deve ser preservado.

## Requisitos para os recortes originais

- recortar somente a área necessária da figura original, evitando texto corrido da página quando não fizer parte da figura;
- não redesenhar, reinterpretar ou gerar por IA;
- manter resolução suficiente para PDF e Moodle;
- registrar no `.Rnw` a figura/seção de origem;
- usar `include_supplement()` e `\includegraphics{...}` para que o arquivo seja incorporado corretamente no Moodle XML;
- validar PDF e Moodle XML antes do merge.
