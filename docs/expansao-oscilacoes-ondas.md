# Expansão de Oscilações e Ondas

Este documento registra as convenções técnicas e pedagógicas da Epic #94 e serve como referência para as etapas #95–#101.

## Escopo

A expansão tem meta aproximada de 75 novas questões `.Rnw`:

- 32 de Oscilações;
- 43 de Ondas e Acústica.

A referência pedagógica principal é o material de Oscilações e Ondas indicado na Epic, mas os itens do banco devem ser adaptações fortes, generalizações parametrizadas ou questões autorais inspiradas nos conceitos. Não reproduzir literalmente enunciados extensos ou figuras do material de referência.

## Estrutura planejada

A estrutura será criada incrementalmente, conforme os lotes forem implementados:

```text
BancoDeQuestoes/
├── oscilacoes/
│   ├── mhs/
│   ├── energia/
│   ├── pendulos/
│   └── ressonancia/
└── ondas/
    ├── progressivas/
    ├── cordas/
    ├── interferencia/
    ├── estacionarias/
    └── acustica/
```

Não criar diretórios vazios apenas para antecipar a estrutura. A organização do XML estruturado deve acompanhar naturalmente os diretórios-fonte.

## Convenções para novas questões

### Arquivos e identificação

- usar nomes `Qxx[Quiz]Assunto.Rnw` compatíveis com o padrão histórico do banco;
- `Quiz` é reservado a `schoice`/`mchoice`;
- garantir `\exname{}` único e descritivo;
- em subdiretórios novos, a numeração pode recomeçar em `Q01`, desde que `exname` e o restante do nome evitem ambiguidade global;
- usar `\exsection{}` com hierarquia sem acentos para manter consistência com itens recentes, por exemplo:
  - `Mecanica; Oscilacoes; MHS`;
  - `Mecanica; Oscilacoes; Energia`;
  - `Ondulatoria; Ondas progressivas`;
  - `Ondulatoria; Acustica; Doppler`.

### Tipos

- `num`: resultado numérico único;
- `cloze`: dois ou mais resultados naturalmente encadeados;
- `schoice`: uma alternativa correta;
- `mchoice`: somente quando múltiplas afirmações corretas forem pedagogicamente justificadas.

Evitar transformar listas extensas de verdadeiro/falso em uma única questão quando conceitos independentes podem ser avaliados separadamente.

### Solucionário

Toda questão nova deve ter solução explicativa. A solução deve, conforme o caso:

1. identificar a relação física relevante;
2. substituir os dados de forma legível;
3. manter unidades;
4. explicar o resultado ou a escolha conceitual;
5. registrar precisão/tolerância coerente em questões numéricas.

Não usar como padrão solucionários contendo apenas o valor final.

### Parametrização

- preferir conjuntos discretos de valores fisicamente plausíveis;
- escolher valores que gerem contas razoáveis para o nível pretendido;
- validar múltiplas sementes;
- evitar alternativas coincidentes depois de arredondamento;
- evitar combinações que produzam casos degenerados ou mudança involuntária da chave;
- para `schoice`/`mchoice`, embaralhar alternativas preservando a chave.

A dificuldade não possui atualmente um metadado canônico do banco. Durante esta Epic ela será registrada nas issues/PRs e auditada globalmente na #101, com meta aproximada de 45% fácil, 45% média e 10% difícil.

## Política de figuras

A figura deve existir porque contém informação necessária à resolução ou à interpretação; não deve ser meramente decorativa.

Prioridades:

- gráficos de `x(t)`, `v(t)`, `a(t)` e energias no MHS;
- perfil espacial de ondas e gráficos temporais de pontos do meio;
- interferência e superposição;
- nós, antinós e modos normais;
- tubos sonoros;
- geometrias de Doppler/Mach quando necessárias.

Regras técnicas:

- preferir figuras autorais e reprodutíveis;
- gráficos podem ser produzidos proceduralmente em R e esquemas podem ser gerados de forma vetorial antes de serem incorporados ao item;
- quando a questão depender de arquivo suplementar, registrar o asset com `include_supplement()` e incluí-lo com `\includegraphics{...}` conforme o padrão já suportado pelo banco;
- conferir legibilidade em PDF e no Moodle XML;
- usar eixos, unidades e rótulos explícitos;
- não usar fotografias só para contextualização;
- não recortar figuras do material de referência como padrão desta expansão.

Antes de escalar os lotes visuais de #96, #97 e especialmente #99, validar pelo CI ao menos um novo gráfico e um novo esquema produzidos para a expansão.

## Auditoria inicial de `BancoDeQuestoes/ondas`

No início da #95 havia 8 arquivos `.Rnw` diretamente no diretório.

| Arquivo | Assunto dominante | Parametrização | Solução atual | Decisão |
|---|---|---|---|---|
| `Q01QuizOndas.Rnw` | conceitos básicos de ondas e som | embaralhamento de 10 afirmações | explicações muito curtas e algumas vazias | manter por enquanto; não usar como modelo; evitar duplicar o mesmo grande bloco V/F |
| `Q02QuizOndas.Rnw` | conceitos gerais, difração, refração e interferência | embaralhamento de 7 afirmações | explicações curtas/incompletas | manter por enquanto; revisar futuramente se os novos itens tornarem partes redundantes |
| `Q03Ondas.Rnw` | propagação sonora no ar e retorno por fio | frequência, distância e comprimento de onda | apenas resposta numérica | manter; candidato a melhorar solucionário em revisão separada |
| `Q90ClozeRelacaoFundamentalOnda.Rnw` | `v = lambda f` e `T = 1/f` | boa, com conjuntos discretos | explicativa | manter; referência para questão numérica/cloze parametrizada |
| `Q91ClozeEcoDistancia.Rnw` | eco e distância | boa, tempo discretizado | explicativa | manter; classificar conceitualmente como Acústica quando houver reorganização controlada |
| `Q92ClozeRefracaoSnell.Rnw` | óptica, refração e lei de Snell | boa | explicativa | mover para `BancoDeQuestoes/optica/`; o próprio `exsection` já o classifica como Óptica |
| `Q93ClozeEspelhoPlano.Rnw` | óptica geométrica, espelho plano | boa | explicativa | mover para `BancoDeQuestoes/optica/`; o próprio `exsection` já o classifica como Óptica |
| `Q94QuizNivelSonoro.Rnw` | acústica, nível sonoro e decibéis | boa, diferença de nível discretizada | explicativa | manter; referência para `schoice` conceitual-numérico |

Após a movimentação dos dois itens de Óptica, o núcleo efetivo de Ondas/Acústica passa a ter 6 arquivos na raiz de `ondas`. A reorganização dos seis itens restantes em subdiretórios será feita apenas quando trouxer benefício claro e sem misturar refatoração ampla aos lotes de conteúdo.

## Questões de referência para os primeiros lotes

Até que as primeiras questões da #96 sejam mescladas, adotar como referências internas:

- **numérica/cloze parametrizada:** `ondas/Q90ClozeRelacaoFundamentalOnda.Rnw`;
- **múltipla escolha com solução explicativa:** `ondas/Q94QuizNivelSonoro.Rnw`;
- **asset suplementar:** `optica/Q07Optgeo.Rnw` demonstra o mecanismo histórico de `include_supplement()` + `\includegraphics`.

A #96 deverá substituir a terceira referência por uma questão gráfica nova da própria expansão, validada em PDF/XML.

## Fluxo de implementação

Para cada etapa:

1. verificar duplicidade com o banco atual;
2. selecionar conceitos e nível de dificuldade;
3. implementar os `.Rnw` e assets necessários;
4. testar várias sementes das questões parametrizadas;
5. validar PDF e Moodle XML;
6. rodar a validação estrutural do banco e CI;
7. revisar física, redação, unidades e solucionários;
8. abrir PR usando `Refs #94` e `Closes #<issue-da-etapa>` somente quando a etapa estiver completa.

A auditoria global e os desvios em relação às metas quantitativas serão consolidados na #101.