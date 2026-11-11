# Expansão BancoFisica — 12 questões ilustradas de Mecânica

Questões em R/exams (`.Rnw`) com 12 imagens fornecidas pelo professor.

## Arquivos

- `BancoDeQuestoes/leisdenewton/forcas`: 4 questões (Atwood, mesa e polia, planos inclinados, plano com corpo suspenso).
- `BancoDeQuestoes/leisdenewton/atrito`: 2 questões (empurrar e puxar com força oblíqua).
- `BancoDeQuestoes/estatica`: 4 questões (semáforo, ginasta, escaladora e gastrocnêmio).
- `BancoDeQuestoes/movcircular`: 2 questões (normal em loop com raios de curvatura locais e normal em arco circular).
- `BancoDeQuestoes/figuras`: imagens originais enviadas nesta conversa.

Os ângulos/forças são idealizados e as imagens são esquemáticas, sem correspondência quantitativa obrigatória com o desenho. Nas duas rampas foram fixados 37° e 53° e no plano único 37°, em consonância com o desenho. Em problemas de loop, declararam-se hipóteses explícitas para raio de curvatura e sentido da força normal.

**Atenção**: antes de publicar imagens em repositório aberto, verificar a licença e o crédito específico de cada imagem OpenStax. O material foi preparado para revisão e não enviado ao GitHub. `include_supplement(..., dir="../../figuras")` deve ser conferido no runner do projeto.

## Testes recomendados

1. Compilar cada `.Rnw` com `exams::exams2pdf` usando o diretório de trabalho da questão.
2. Repetir pelo menos 100 sorteios, testar tolerâncias de cloze e inspecionar resultados em Moodle.
3. Verificar referência/atribuição das imagens, sem suprimi-las.
4. Conferir possíveis conflitos de numeradores em `estatica` e `movcircular`; números são apenas rótulos iniciais.
