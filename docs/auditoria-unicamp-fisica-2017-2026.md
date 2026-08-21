# Auditoria Unicamp/Comvest — Física 2017–2026

> Status: inventário-fonte inicial e preparação da auditoria de cobertura.  
> Issue de acompanhamento: #178.

## Objetivo

Mapear sistematicamente as questões de Física dos Vestibulares Unicamp de 2017 a 2026, cruzá-las com o `master` atual do BancoFisica e organizar a incorporação apenas das questões efetivamente ausentes.

A auditoria segue o mesmo princípio adotado para o ENEM: uma questão só deve ser considerada **presente** quando o contexto/item original da Unicamp tiver sido efetivamente incorporado ou adaptado. A existência de outra questão sobre o mesmo conceito físico não conta como cobertura.

## Fontes oficiais

- Arquivo de vestibulares anteriores da Comvest: <https://www.comvest.unicamp.br/vestibulares-anteriores/>
- Provas comentadas de 1ª e 2ª fases: <https://www.comvest.unicamp.br/vestibulares-anteriores/1a-fase-2a-fase-comentadas/>

As provas comentadas são particularmente úteis porque apresentam respostas esperadas, comentários da banca e exemplos de resolução. Em várias edições também aparecem informações de objetivo da questão, desempenho dos candidatos, Índice de Facilidade (IF) e Índice de Discriminação (ID).

### Regra de reprodução e atribuição

A Comvest informa que autoriza a reprodução de questões de vestibulares anteriores desde que a reprodução seja **parcial e não exclusiva**, com citação da fonte, e não corresponda à reprodução da prova inteira.

Para novos itens derivados dessas provas, usar como atribuição padronizada:

`Comvest / Vestibular Unicamp AAAA (ano)`

A solução no BancoFisica deve ser própria, usando o material comentado da Comvest como referência de validação.

## Inventário inicial do núcleo explicitamente de Física

A triagem das provas comentadas oficiais encontrou o seguinte núcleo de questões identificadas como Física.

| Vestibular | 1ª fase | Qtde. | 2ª fase | Qtde. | Total |
|---|---:|---:|---:|---:|---:|
| 2017 | Q57–65 | 9 | Q13–18 | 6 | 15 |
| 2018 | Q40–48 | 9 | Q7–12 | 6 | 15 |
| 2019 | Q57–65 | 9 | Q7–12 | 6 | 15 |
| 2020 | Q70–78 | 9 | Q11–16 | 6 | 15 |
| 2021 | Q33–40 (E/G) + Q49–56 (Q/Z) | 16 | Q11–16 | 6 | 22 |
| 2022 | Q57–64 | 8 | Q11–16 | 6 | 14 |
| 2023 | Q30–36 | 7 | Q9–14 | 6 | 13 |
| 2024 | Q34–40 | 7 | Q9–14 | 6 | 13 |
| 2025 | Q8–14 | 7 | Q9–14 | 6 | 13 |
| 2026 | Q8–14 | 7 | Q9–13 | 5 | 12 |
| **Total** |  | **85** |  | **62** | **147** |

O vestibular 2021 é excepcional: a 1ª fase teve versões diferentes para grupos de cursos, por isso aparecem dois blocos de oito questões de Física.

**Importante:** 147 é o tamanho do inventário-fonte principal, e **não** a quantidade de questões ausentes do BancoFisica. A deduplicação contra o repositório ainda precisa ser feita item a item.

## Questões interdisciplinares com componente de Física

Além do núcleo acima, há questões oficialmente interdisciplinares em que Física participa de forma substantiva.

### 2017

- Q32 — História + Física: física nuclear/fissão no contexto de Hiroshima;
- Q35 — Português + Física: empuxo;
- Q38 — Geografia + Física: energia eólica.

### 2018

- Q38 — Inglês + Física: 2ª lei de Newton;
- Q39 — Matemática + Física: equilíbrio de torques;
- Q60 — Química + Física: corrente/carga elétrica e conversão de energia.

### 2019

- Q10 — História + Física: leis de Kepler;
- Q55 — Geografia + Física: ondas sísmicas;
- Q80 — Português + Física: pêndulo simples.

### 2020

- Q9 — Inglês + Física: fusão nuclear e conversão massa–energia;
- Q79 — Biologia + Física: associação de resistores.

Há, portanto, **ao menos 11 questões interdisciplinares adicionais** confirmadas entre 2017 e 2020. As interdisciplinares de 2021–2026 devem ser enumeradas separadamente antes de fechar a contagem global.

## Primeiro mapa temático — edições recentes

O objetivo desta seção é registrar o conceito físico dominante antes da checagem de presença no banco. A classificação poderá ser refinada quando cada item for revisado individualmente.

### 2022 — 1ª fase

- Q57 — movimento circular/velocidade, sonda Parker;
- Q58 — gravitação universal e aceleração gravitacional;
- Q59 — movimento circular/centrípeto em órbita lunar;
- Q60 — energia potencial gravitacional na Lua;
- Q61 — energia, potência, aquecimento e mudança de fase;
- Q62 — pressão e temperatura em autoclave/mudança de fase;
- Q63 — eletrostática: campo e potencial elétrico;
- Q64 — refração e lei de Snell em atmosfera marciana.

### 2022 — 2ª fase

Q11–Q16 cobrem, entre outros pontos: quantidade de movimento, impulso e energia; equilíbrio/torque, atrito e trabalho; hidrostática; cinemática; potência térmica e calor latente; oscilações/movimento e energia mecânica.

### 2023 — 1ª fase

- Q30 — MUV em balão;
- Q31 — trabalho da força peso;
- Q32 — gás ideal;
- Q33 — atrito estático, mola e equilíbrio;
- Q34 — 3ª lei de Kepler/Ceres;
- Q35 — equipotenciais, corrente e lei de Ohm;
- Q36 — refração/lei de Snell e refratometria.

### 2023 — 2ª fase

- Q9 — movimento orbital/centrípeto e quantidade de movimento;
- Q10 — espelhos/óptica e lei de Hubble/redshift;
- Q11 — pressão e torque em biomecânica/escala;
- Q12 — calor latente e condução térmica;
- Q13 — lançamento, atrito e trabalho–energia;
- Q14 — sensores em fibra e circuitos/lei de Ohm.

### 2024 — 1ª fase

- Q34 — MUV/reentrada;
- Q35 — trabalho e energia cinética;
- Q36 — gás ideal;
- Q37 — ondas eletromagnéticas: frequência e comprimento de onda;
- Q38 — velocidade terminal e equilíbrio de forças/arrasto;
- Q39 — lei de Ohm e interpretação de gráfico I–V;
- Q40 — lei de Hooke/elasticidade.

### 2024 — 2ª fase

- Q9 — empuxo e elasticidade;
- Q10 — movimento relativo e pressão/força/trabalho;
- Q11 — calorimetria e energia de fótons;
- Q12 — frequência/período, movimento e refração;
- Q13 — capacitância e rede de difração;
- Q14 — escoamento/Torricelli, impulso e quantidade de movimento.

### 2025 — 1ª fase

- Q8 — cinemática e velocidade relativa;
- Q9 — movimento circular em órbita lunar;
- Q10 — interação gravitacional Terra–Lua e aceleração;
- Q11 — ondas eletromagnéticas/óptica no contexto do DUNE;
- Q12 — dilatação térmica anômala/interpretação de gráfico;
- Q13 — circuitos e potência em painéis solares;
- Q14 — eficiência, intensidade, potência e energia solar.

### 2025 — 2ª fase

- Q9 — gás ideal, trabalho e termodinâmica no efeito Föhn;
- Q10 — efeito Hall, movimento de portadores e força elétrica/magnética;
- Q11 — cinemática/dinâmica e pressão no contexto de helicóptero em Marte;
- Q12 — equilíbrio em plano inclinado e intensidade sonora/decibéis;
- Q13 — energia mecânica e óptica (Brewster/Snell);
- Q14 — lentes, equação de Gauss e aumento.

### 2026 — 1ª fase

- Q8 — condução, convecção e radiação térmica;
- Q9 — corrente elétrica, carga e tempo;
- Q10 — circuito em série, resistência interna e lei de Ohm;
- Q11 — energia elétrica de bateria e energia potencial gravitacional;
- Q12 — lente convergente e formação de imagem;
- Q13 — cinemática a partir de gráfico posição × tempo;
- Q14 — cinemática e 2ª lei de Newton/desaceleração.

### 2026 — 2ª fase

- Q9 — cinemática, quantidade de movimento e impulso em carro elétrico;
- Q10 — gravitação e 3ª lei de Kepler no contexto do Planeta 9;
- Q11 — propriedades térmicas, potência e mudança de fase;
- Q12 — equilíbrio de forças e ondas em cordas de guitarra;
- Q13 — LEDs/física moderna e óptica com prisma.

## Presença prévia no BancoFisica

Uma busca literal por `UNICAMP` no `master` atual já encontra itens antigos associados à instituição. Esses resultados são **candidatos a correspondência**, mas não devem ser usados automaticamente para declarar uma questão de 2017–2026 como coberta, pois vários arquivos não registram o ano original.

Candidatos encontrados na primeira varredura:

- `BancoDeQuestoes/estatica/Q12estce.Rnw` — escada em equilíbrio, marcado como `UNICAMP-adapt.`;
- `BancoDeQuestoes/estatica/Q03estce.Rnw` — alavanca, marcado como `UNICAMP`;
- `BancoDeQuestoes/estatica/Q13estce.Rnw` — bíceps/alavanca, explicitamente `UNICAMP-99-adapt.`;
- `BancoDeQuestoes/cinematica/MU/Q13MU.Rnw` — movimento de bola fotografada, fonte `Unicamp (Adaptada)`;
- `BancoDeQuestoes/estatica/Q06estce.Rnw`;
- `BancoDeQuestoes/trabalhopotencia/Q18Trab.Rnw`;
- `BancoDeQuestoes/trabalhopotencia/Q16Trab.Rnw`;
- `BancoDeQuestoes/trabalhopotencia/Q06Trab.Rnw`;
- `BancoDeQuestoes/hidrostatica/Q07LeiStevin.Rnw`;
- `BancoDeQuestoes/movcircular/Q19GloboMorte.Rnw`;
- `BancoDeQuestoes/qtdmov_impulso/Q03testImpulso.Rnw`;
- `BancoDeQuestoes/hidrostatica/Q07LeiStevin2.Rnw`.

A busca por texto é apenas uma primeira aproximação: adaptações antigas podem ter perdido a palavra `UNICAMP`, e uma mesma questão original pode ter sido parametrizada ou renomeada. A deduplicação final deve comparar contexto, dados físicos, figura e resposta.

## Campos da auditoria item a item

Para cada questão do inventário, registrar:

| Campo | Descrição |
|---|---|
| Ano | edição do vestibular |
| Fase | 1ª ou 2ª fase |
| Questão | numeração original |
| Tipo | disciplinar ou interdisciplinar |
| Macroárea | mecânica, termologia, eletromagnetismo etc. |
| Conceito dominante | conceito usado para classificação no banco |
| Status | presente / ausente / híbrida para decisão |
| Arquivo | caminho `.Rnw`, quando presente |
| Visual | figura, gráfico, esquema, circuito, tabela ou fotografia relevante |
| IF/ID | índices oficiais quando disponíveis |
| Dificuldade | classificação oficial ou derivada do IF, quando possível |
| Prioridade | ordem sugerida de incorporação |

## Regra para elementos visuais

Deve prevalecer a política atual do repositório descrita em `AGENTS.md` e `docs/PDF_SOURCE_WORKFLOW.md`:

1. se a figura, gráfico, esquema, circuito ou fotografia fizer parte do raciocínio, preservá-lo;
2. quando o PDF oficial estiver disponível, extrair/cortar o ativo diretamente do PDF com `tools/pdf_assets.py`;
3. não substituir um visual necessário por uma descrição textual apenas para simplificar a implementação;
4. somente criar uma versão procedural/autoral quando a parametrização exigir que o próprio visual varie;
5. revisar visualmente o ativo antes de concluir o item.

## Estratégia de incorporação

A incorporação deve ocorrer somente depois da deduplicação e em lotes pequenos:

### Fase 1 — auditoria do núcleo principal

- [x] inventariar as faixas de Física de 2017–2026;
- [x] registrar o total inicial de 147 itens;
- [x] identificar candidatos antigos do BancoFisica por busca de `UNICAMP`;
- [ ] comparar as 147 questões item a item com o `master`;
- [ ] produzir a tabela consolidada presente/ausente por ano e macroárea.

### Fase 2 — interdisciplinares

- [x] registrar as interdisciplinares já confirmadas de 2017–2020;
- [ ] enumerar 2021–2026;
- [ ] decidir individualmente quais têm componente de Física suficiente para o banco.

### Fase 3 — ausentes sem dependência visual

Priorizar lacunas conceituais reais e itens que possam ser incorporados com fidelidade sem ativos externos.

### Fase 4 — ausentes visuais

Preservar os ativos relevantes dos PDFs oficiais seguindo `tools/pdf_assets.py`.

### Fase 5 — 2ª fase/discursivas

Tratar separadamente as questões discursivas/contextualizadas, aproveitando as soluções e comentários oficiais para validação. Essa coleção é particularmente valiosa para listas, avaliações discursivas e futuras extensões do BancoFisica além do formato de múltipla escolha.

### Fase 6 — expansão histórica

Depois de estabilizar 2017–2026, retroceder progressivamente de 2016 até 1987.

## Critério de conclusão

Como nos lotes ENEM recentes, um lote de incorporação só deve ser considerado concluído quando:

1. o PR correspondente estiver aberto;
2. os checks obrigatórios terminarem verdes;
3. eventuais falhas forem corrigidas e retestadas no próprio branch;
4. o PR for efetivamente mesclado.

## Próximo passo operacional

A próxima ação desta auditoria é resolver a correspondência das 147 questões do núcleo principal contra o `master`. Nenhuma contagem de “questões ausentes da Unicamp” deve ser publicada antes dessa deduplicação.