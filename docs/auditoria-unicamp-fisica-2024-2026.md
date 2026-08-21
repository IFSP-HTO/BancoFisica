# Auditoria Unicamp/Comvest — Física 2024–2026

> Subauditoria da issue #178.  
> Base de comparação: `master` após o merge do PR #179.  
> Escopo: núcleo explicitamente de Física das provas regulares de 2024, 2025 e 2026.

## Objetivo

Resolver a primeira etapa da deduplicação do inventário Unicamp/Comvest, começando pelas três edições mais recentes. O critério é o mesmo usado na auditoria ENEM: uma questão só conta como **presente** quando o contexto/item original tiver sido efetivamente incorporado ou adaptado no BancoFisica. Uma questão genérica sobre o mesmo conceito não conta como cobertura.

## Fontes oficiais

Foram usadas as provas comentadas oficiais da Comvest:

- 2024 — 1ª fase e 2ª fase, Ciências Exatas e Tecnológicas;
- 2025 — 1ª fase e 2ª fase, Ciências Exatas e Tecnológicas;
- 2026 — 1ª fase e 2ª fase, Ciências Exatas e Tecnológicas.

Arquivo oficial: <https://www.comvest.unicamp.br/vestibulares-anteriores/1a-fase-2a-fase-comentadas/>

A Comvest autoriza reprodução parcial e não exclusiva das questões, com citação da fonte. Para os itens incorporados, usar a atribuição padronizada `Comvest / Vestibular Unicamp AAAA (ano)`.

## Método de deduplicação

Cada questão foi lida na prova comentada e buscada no `master` com combinações de termos distintivos do contexto, dados numéricos e conceitos. Exemplos: `ZnW2O8 dilatação térmica negativa`, `DUNE neutrinos argônio líquido 128 nm 350 nm`, `Baltimore Londres vento 250 km/h avião`, `Planeta 9 objeto trans-netuniano`, `bend guitarra tensão corda 196 N` e `cápsula espacial atmosfera 7000`.

A busca foi feita pelo contexto da questão, e não apenas pelo tema físico. Nenhuma das 38 questões abaixo apresentou correspondência contextual/textual no `master`.

**Cautela:** adaptações antigas muito reescritas podem escapar de busca textual. Portanto, antes de criar cada novo `.Rnw`, deve-se fazer a última conferência visual/contextual contra os candidatos temáticos do diretório correspondente. O status abaixo significa “ausente após auditoria contextual do `master`”, não uma prova formal de inexistência de toda adaptação possível.

## Resultado consolidado

| Ano | 1ª fase | 2ª fase | Auditadas | Correspondências encontradas | Candidatas novas |
|---:|---:|---:|---:|---:|---:|
| 2024 | 7 | 6 | 13 | 0 | 13 |
| 2025 | 7 | 6 | 13 | 0 | 13 |
| 2026 | 7 | 5 | 12 | 0 | 12 |
| **Total** | **21** | **17** | **38** | **0** | **38** |

### Partição operacional

- **12 questões de 1ª fase sem dependência visual relevante** — primeiro lote recomendado;
- **9 questões de 1ª fase com gráfico/esquema/circuito relevante** — lote visual;
- **17 questões de 2ª fase** — lote discursivo próprio; muitas têm figuras, gráficos, tabelas ou construção gráfica.

Essa partição evita misturar a conversão direta de questões objetivas com o trabalho mais cuidadoso de preservação de ativos e de adaptação de respostas discursivas.

## 2024 — 1ª fase

| Q | Conceito dominante | Visual relevante | Status | Dificuldade/ID observados na Comvest |
|---:|---|---|---|---|
| 34 | MUV — reentrada de cápsula espacial | não | ⬜ ausente | Médio / Excelente |
| 35 | trabalho e teorema da energia cinética | não | ⬜ ausente | Difícil / Bom |
| 36 | equação de estado do gás ideal | não | ⬜ ausente | Fácil / Excelente |
| 37 | ondas eletromagnéticas, frequência e comprimento de onda | **sim — gráfico** | ⬜ ausente | Médio / Excelente |
| 38 | velocidade terminal, arrasto e equilíbrio de forças | não | ⬜ ausente | Médio / ótimo desempenho discriminativo |
| 39 | lei de Ohm e leitura de gráfico corrente × tensão | **sim — gráfico** | ⬜ ausente | Médio / Excelente |
| 40 | lei de Hooke e elasticidade em neurônio | **sim — esquema** | ⬜ ausente | Médio; comentário estatístico da edição deve ser preservado com cautela porque a prova comentada contém inconsistência de numeração nesse trecho |

### Contextos distintivos usados na busca

- Q34–35 — cápsula espacial/reentrada, 7000 m/s;
- Q36 — alta atmosfera, gás perfeito, 180 K;
- Q37 — apagão de rádio, cápsula e frequência limite;
- Q38 — velocidade terminal e objeto de 200 g;
- Q39 — sinapses elétricas, neurônios e resistência;
- Q40 — neurônio, força elástica e deformações nanométricas.

## 2024 — 2ª fase

| Q | Conceito dominante | Visual relevante | Status | Dificuldade/ID observados na Comvest |
|---:|---|---|---|---|
| 9 | empuxo + elasticidade/Young | **sim — figuras** | ⬜ ausente | Difícil / Excelente |
| 10 | movimento relativo + pressão, força e trabalho | **sim — figuras** | ⬜ ausente | Médio / Excelente |
| 11 | calorimetria + energia de fótons | **sim — gráfico de potência do pulso** | ⬜ ausente | Médio / Excelente |
| 12 | frequência/período, movimento e refração | **sim — figuras ópticas** | ⬜ ausente | Médio / Excelente |
| 13 | capacitância + rede de difração | **sim — esquemas/tabela** | ⬜ ausente | Difícil / Ótimo |
| 14 | Torricelli + impulso/quantidade de movimento | **sim — gráfico** | ⬜ ausente | Médio / Excelente |

Contextos: `O velho e o mar`/Santiago, barco e peixe; barco/tubarão/vela; litografia EUV e gota de estanho; fabricação de chips e gotas a 50 kHz; capacitor/rede de difração; superfície hidrofóbica e coeficiente de restituição.

## 2025 — 1ª fase

| Q | Conceito dominante | Visual relevante | Status | Dificuldade/ID observados na Comvest |
|---:|---|---|---|---|
| 8 | velocidade relativa e tempo de voo | **sim — diagrama de rota/vento** | ⬜ ausente | Médio / Excelente |
| 9 | movimento circular/orbital | não | ⬜ ausente | Médio / Ótimo |
| 10 | gravitação Terra–Lua e aceleração resultante | **sim — gráfico** | ⬜ ausente | Difícil / Bom |
| 11 | ondas eletromagnéticas no DUNE | não | ⬜ ausente | Médio / Ótimo |
| 12 | dilatação térmica negativa | **sim — gráfico** | ⬜ ausente | Difícil / Bom |
| 13 | corrente/potência em painel solar e bateria | **sim — esquema elétrico** | ⬜ ausente | Fácil / Bom |
| 14 | eficiência, irradiância e potência solar | não | ⬜ ausente | Médio / Bom |

Contextos distintivos: Baltimore–Londres e vento de 250 km/h; sonda em órbita lunar; ponto de cancelamento gravitacional Terra–Lua; DUNE e argônio líquido 128/350 nm; `ZnW2O8`; painel de 462 W/42 V e bateria; painel de 2,5 m² e irradiância de 924 W/m².

## 2025 — 2ª fase

| Q | Conceito dominante | Visual relevante | Status | Dificuldade/ID observados na Comvest |
|---:|---|---|---|---|
| 9 | gás ideal e trabalho no efeito Föhn | **sim — gráfico P×V** | ⬜ ausente | Médio / Excelente |
| 10 | efeito Hall, força elétrica/magnética e fluxômetro | **sim — figuras e sinal temporal** | ⬜ ausente | Difícil / Excelente |
| 11 | lançamento horizontal + sustentação/pressão em Marte | não essencial | ⬜ ausente | Médio / Excelente |
| 12 | equilíbrio no plano inclinado + intensidade sonora | não essencial | ⬜ ausente | Difícil / Excelente |
| 13 | energia mecânica + Brewster/Snell | **sim — gráfico e esquema** | ⬜ ausente | Médio / Excelente |
| 14 | lentes, Gauss e aumento transversal | **sim — construção óptica** | ⬜ ausente | Difícil / Excelente |

A Q14 foi classificada pelas bancas como média, mas o desempenho observado a colocou como difícil, com discriminação excelente; esse é um bom exemplo de por que vale preservar metadados empíricos da Comvest.

## 2026 — 1ª fase

| Q | Conceito dominante | Visual relevante | Status | Dificuldade/ID observados na Comvest |
|---:|---|---|---|---|
| 8 | condução, convecção e radiação térmica | não | ⬜ ausente | Fácil / Bom |
| 9 | corrente elétrica, carga e tempo | não | ⬜ ausente | Médio / Bom |
| 10 | resistência interna, circuito e lei de Ohm | **sim — circuito** | ⬜ ausente | Médio / Ótimo |
| 11 | energia de bateria × energia potencial gravitacional | não | ⬜ ausente | Difícil / Bom |
| 12 | lente convergente e formação de imagem | não | ⬜ ausente | Difícil / Bom |
| 13 | cinemática e escolha de gráfico posição × tempo | **sim — alternativas gráficas** | ⬜ ausente | Médio / Excelente |
| 14 | desaceleração e 2ª lei de Newton | não | ⬜ ausente | Médio / Bom |

Contextos: ar-condicionado e mecanismos de transferência de calor; bateria de 4000 mA durante 1 h; bateria de 3,6 V com resistência interna; bateria de 15 Wh e equivalente gravitacional; miniatura do Cristo Redentor/CTI Renato Archer; motociclista na faixa azul de São Paulo.

## 2026 — 2ª fase

| Q | Conceito dominante | Visual relevante | Status | Dificuldade/ID observados na Comvest |
|---:|---|---|---|---|
| 9 | cinemática + impulso/quantidade de movimento em carro elétrico | **sim — tabela e construção de gráfico** | ⬜ ausente | Médio / Excelente |
| 10 | gravitação + 3ª lei de Kepler/Planeta 9 | **sim — diagrama orbital** | ⬜ ausente | Médio / Excelente |
| 11 | calor sensível/latente, potência e PCM | **sim — gráfico térmico** | ⬜ ausente | Fácil / Excelente |
| 12 | ondas em corda + equilíbrio de forças/tensão em guitarra | **sim — figuras A/B** | ⬜ ausente | Médio (IF 0,53) / Excelente (ID 0,68) |
| 13 | LED/física moderna + refração em prisma | **sim — prisma e construção de raios** | ⬜ ausente | Médio (IF 0,53) / Excelente (ID 0,76) |

Na Q12, a Comvest destaca explicitamente a integração entre ondulatória e mecânica; na Q13, entre relação energia–frequência e óptica geométrica. São candidatas fortes para o futuro lote discursivo justamente por articularem conteúdos que costumam ficar separados no banco.

## Primeiro lote recomendado — 1ª fase sem visual

As 12 questões abaixo são o caminho mais rápido para começar a incorporar a Unicamp com fidelidade e baixo custo de ativos:

### 2024

- Q34 — reentrada/MUV;
- Q35 — trabalho e energia cinética;
- Q36 — gás ideal;
- Q38 — velocidade terminal/arrasto.

### 2025

- Q9 — órbita lunar;
- Q11 — DUNE/ondas eletromagnéticas;
- Q14 — eficiência de painel solar.

### 2026

- Q8 — mecanismos de transferência de calor;
- Q9 — carga elétrica;
- Q11 — energia da bateria;
- Q12 — lente convergente/formação de imagem;
- Q14 — desaceleração e força resultante.

Antes de criar cada `.Rnw`, fazer uma última busca temática no diretório de destino para evitar equivalentes muito reescritos. Preservar o conceito e a chave oficial; produzir solução própria em LaTeX; citar `Comvest / Vestibular Unicamp AAAA (ano)`.

## Lote visual de 1ª fase

As 9 questões abaixo exigem revisão do PDF oficial e preservação do elemento visual relevante:

- 2024 Q37 — gráfico frequência limite × temperatura;
- 2024 Q39 — gráfico corrente × tensão;
- 2024 Q40 — esquema de elasticidade do neurônio;
- 2025 Q8 — diagrama da rota e vento;
- 2025 Q10 — gráfico da aceleração gravitacional entre Terra e Lua;
- 2025 Q12 — gráfico de expansão térmica negativa;
- 2025 Q13 — esquema painel/controlador/bateria;
- 2026 Q10 — circuito com resistência interna;
- 2026 Q13 — alternativas gráficas posição × tempo.

Usar `tools/pdf_assets.py` conforme `AGENTS.md` e `docs/PDF_SOURCE_WORKFLOW.md`. Se o elemento for composição vetorial/textual, usar `crop`; se for raster independente, preferir `extract`.

## Lote de 2ª fase

As 17 questões discursivas (2024 Q9–14, 2025 Q9–14 e 2026 Q9–13) devem formar uma frente própria. A adaptação deve preservar a estrutura dos itens `(a)`, `(b)`, etc., e usar as respostas esperadas da Comvest apenas como referência de validação para um solucionário próprio.

Esse lote pode exigir uma decisão de modelo no BancoFisica: algumas questões cabem naturalmente em `cloze` com múltiplos campos numéricos; outras envolvem desenho de gráfico, construção geométrica ou resposta aberta e talvez sejam mais úteis inicialmente como material para PDF/listas do que para exportação automática ao Moodle.

## Próximas ações

- [x] auditar 2024–2026 contra o `master`;
- [x] separar questões de 1ª fase em sem-visual e visuais;
- [x] isolar a 2ª fase como frente discursiva;
- [ ] abrir issue do primeiro lote de 12 questões objetivas sem visual;
- [ ] abrir issue do lote visual de 9 questões objetivas;
- [ ] abrir issue da frente de 17 questões discursivas;
- [ ] incorporar o primeiro lote em PRs pequenos e validar no CI;
- [ ] depois continuar a deduplicação com 2021–2023.
