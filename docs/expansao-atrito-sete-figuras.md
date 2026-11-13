# Expansão de atrito: sete figuras e questões parametrizadas (novembro de 2026)

Este lote adiciona sete questões R/exams ao BancoFisica, com imagens fornecidas pelo professor, preservadas sem edição.

| Arquivo | Situação física | Respostas |
|---|---|---|
| AtritoBarcacasRebocadas | Duas barcaças com resistências distintas | aceleração e tração |
| AtritoBlocoRampaForcaHorizontal | Bloco em rampa sob força horizontal | aceleração e atrito |
| AtritoRampaMassaSuspensa | Bloco em rampa rugosa e corpo suspenso | aceleração e tração |
| AtritoCaixaLargadaCaminhao | Caixa descarregada sobre o solo, com velocidade inicial | tempo e distância de frenagem |
| AtritoDoisBlocosForcaObliquaEstatico | Dois blocos ligados sob força oblíqua | força mínima e tração no limiar de movimento |
| AtritoDoisBlocos2M_M | Massas M e 2M com resistências distintas | aceleração e tração |
| AtritoBlocosEmpilhadosMuMin | Bloco superior empurrado obliquamente | aceleração comum e coeficiente estático mínimo |

## Origem e licenças

As sete imagens foram entregues pelo professor e mantidas byte a byte; suas licenças e atribuições de origem devem ser conferidas antes de redistribuição para fora do contexto autorizado. Os enunciados foram parametrizados de forma autoral, com situações inspiradas na literatura de Mecânica (entre elas OpenStax, cap. 6).

## Verificações

- Fórmulas e restrições de movimento revisadas; o movimento deslizante é explicitado quando apenas `mu_k` é fornecido.
- Cada questão inclui `include_supplement(..., dir="../../figuras")` para incorporação de PNG ao XML do Moodle.
- A exportação real deverá ser confirmada pelo CI R/exams do PR.

## Sobreposição com outros lotes

As configurações de rampa + massa suspensa, barcaças e blocos com atrito já aparecem em outros PRs; aqui são mantidas como variantes, com perguntas e parâmetros próprios. Revisar redundância pedagógica antes da mesclagem.
