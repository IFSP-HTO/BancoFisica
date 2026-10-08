# Metadados psicométricos dos itens do ENEM

Esta frente implementa a issue #245.

## Princípio

Os parâmetros psicométricos publicados pelo Inep pertencem ao **item original aplicado no ENEM**. Eles não são uma calibração da versão do BancoFisica quando o enunciado, os números, as alternativas, o estímulo ou a forma de resposta foram alterados.

Assim, o Banco pode exibir:

> Parâmetros TRI do item ENEM original

mas não deve descrever `a`, `b` ou `c` como parâmetros da versão parametrizada/adaptada do Banco sem uma calibração própria.

## Fonte oficial

Fonte primária:

- https://www.gov.br/inep/pt-br/acesso-a-informacao/dados-abertos/microdados/enem

Os pacotes anuais contêm a tabela `ITENS_PROVA_<ANO>.csv`. O Inep descreve essa tabela como a base com informações dos itens das provas. Nas edições do novo ENEM ela inclui posição, área, habilidade, gabarito e parâmetros psicométricos.

O fluxo local deve usar preferencialmente o ZIP oficial do Inep ou a pasta extraída desse ZIP. Não é necessário ler nem versionar os microdados de participantes.

Para a carga inicial desta frente foi usada, **somente como cache de transporte**, a cópia normalizada das tabelas `ITENS_PROVA` mantida em `HenriqueLindemann/analise-enem`. O manifesto desse repositório registra o caminho do arquivo oficial do Inep e os hashes SHA-256 do arquivo-fonte e da cópia normalizada. Os hashes dos anos efetivamente usados nesta carga estão preservados em `metadata/enem/inep_item_sources.csv`. A procedência dos dados continua sendo o Inep; o espelho não é tratado como fonte substantiva independente.

## Base canônica

`metadata/enem/banco_enem_itens.csv` contém uma linha por relação entre um arquivo do BancoFisica e um item-fonte do ENEM.

Campos principais:

- `bank_path`: arquivo `.Rnw` do BancoFisica;
- `relation`: `direct` ou `inspired`;
- `adaptation_kind`: natureza da relação entre a versão do Banco e o item-fonte:
  - `reproduction`: item essencialmente preservado; mudanças apenas de formatação ou ordem de alternativas;
  - `text_adaptation`: enunciado/alternativas reescritos sem parametrização numérica;
  - `fixed_numeric_adaptation`: um ou mais dados numéricos foram alterados de forma fixa;
  - `numeric_parameterization`: dados variam programaticamente entre instâncias;
  - `conceptual_adaptation`: situação/tarefa materialmente reconstruída mantendo o item apenas como base conceitual;
  - `inspired`: não é derivação direta; apenas inspiração temática/conceitual;
- `source_year`, `source_application`, `source_caderno`, `source_color`: identificação editorial da aplicação/caderno;
- `source_question_number`: número impresso da questão no caderno;
- `source_position`: valor oficial de `CO_POSICAO` na tabela de itens — não necessariamente igual ao número impresso;
- `source_co_prova`: código da prova no microdado, quando identificado;
- `co_item`: identificador do item no Inep;
- `sg_area`, `co_habilidade`, `tx_gabarito`: metadados oficiais;
- `in_item_aban`, `tx_motivo_aban`: situação de item abandonado/anulado quando publicada;
- `nu_param_a`, `nu_param_b`, `nu_param_c`: parâmetros do item-fonte;
- `match_status`: estado do cruzamento;
- `notes`: observações de auditoria.

É permitido que duas questões do Banco apontem para o mesmo `CO_ITEM`. Isso ocorre quando há mais de uma versão do Banco derivada do mesmo item-fonte.

## Período pré-TRI

As questões de 1998 e 2001 permanecem no inventário de procedência, mas recebem `match_status=pre_tri`. O ENEM passou à estrutura atual de quatro provas objetivas e TRI em 2009. Os itens anteriores podem ter habilidade e estatísticas clássicas publicadas em relatórios pedagógicos, mas não devem ser tratados como itens 3PL do novo ENEM.

## Fluxo de importação

1. Baixe o pacote oficial do ano no portal do Inep.
2. Mantenha o ZIP fora do Git ou extraia-o em um diretório ignorado.
3. Execute a validação do inventário:

   ```bash
   python tools/enem_item_metadata.py validate
   ```

4. Faça o cruzamento de um ou mais anos:

   ```bash
   python tools/enem_item_metadata.py match \
     --source 2024=/caminho/microdados_enem_2024.zip \
     --source 2025=/caminho/microdados_enem_2025.zip \
     --output build/enem/banco_enem_itens_matched.csv
   ```

O script aceita o ZIP oficial, uma pasta extraída ou o próprio `ITENS_PROVA_<ANO>.csv`.

## Regra de matching

O cruzamento automático é conservador.

1. Se `co_item` já estiver preenchido, ele é a chave principal.
2. Caso contrário, são usados os identificadores disponíveis: `source_co_prova`, `source_position` e `source_color`.
3. A área é restringida a `SG_AREA=CN` quando esse campo existe.
4. Somente um candidato inequívoco é aceito.
5. Mais de um candidato produz `ambiguous`; zero candidatos produz `no_match`.
6. O script nunca escolhe arbitrariamente um item quando faltam dados para distingui-lo.

Depois da revisão manual, os identificadores oficiais confirmados podem ser promovidos para a base canônica.

### Estado da carga inicial

A carga inicial registra 35 relações diretas BancoFisica ↔ ENEM:

- 2 itens pré-TRI (1998 e 2001), mantidos apenas para procedência;
- 33 relações no período 2009–2025 com `CO_ITEM` identificado;
- 32 dessas 33 relações possuem também `CO_PROVA` específico identificado;
- a questão da 2ª aplicação de 2016 (Grand Canyon) possui `CO_ITEM=6781`, mas o item aparece nos códigos de prova 331 e 351 com os mesmos metadados psicométricos; por isso `source_co_prova` permanece vazio até uma auditoria específica do código de caderno;
- o item-fonte do ENEM 2024 Q100 está corretamente marcado como abandonado (`IN_ITEM_ABAN=1`, motivo pedagógico), com gabarito `X` e sem parâmetros `a`, `b` e `c`.

Em 2016 e 2017, `source_question_number` e `source_position` deixam explícita uma diferença de convenção presente nos microdados. Nunca inferir `CO_POSICAO` diretamente do número impresso sem consultar a tabela do respectivo ano.

## Integração futura nos .Rnw e no site

Depois que `CO_ITEM` e os campos oficiais estiverem auditados, cada `.Rnw` poderá receber apenas uma referência curta, por exemplo:

```text
%% ENEM-SOURCE: 2024; CO_ITEM=...; metadata=metadata/enem/banco_enem_itens.csv
```

A tabela continuará sendo a fonte canônica. O site poderá então apresentar habilidade e CCI do item-fonte, além de oferecer filtros por ano, habilidade e parâmetros TRI.

## Privacidade

Esta integração usa apenas metadados públicos de itens. Nenhum registro individual de participante deve ser baixado para o repositório ou versionado.


## Vitrine pública

A vitrine pública suporta um objeto opcional `enemSource` apenas em questões marcadas como `visibility=demo`.

Esse objeto pode apresentar procedência, habilidade e parâmetros TRI do item-fonte e gerar a CCI 3PL no navegador. A exportação pública não consulta nem replica automaticamente `metadata/enem/banco_enem_itens.csv`: os metadados de uma demonstração devem ser selecionados explicitamente.

O site exibe obrigatoriamente o aviso de que os parâmetros pertencem ao item original aplicado pelo Inep e não constituem calibração da versão adaptada do BancoFisica.


### Classificação inicial das 35 relações diretas

Após revisão dos arquivos `.Rnw`, a carga atual ficou:

- 6 `reproduction`;
- 26 `text_adaptation`;
- 2 `numeric_parameterization`;
- 1 `fixed_numeric_adaptation` (ENEM 2024 Q100, cafeteira anulada, com tempo corrigido).

A classificação é conservadora: embaralhamento de alternativas e reconstrução gráfica sem mudança substantiva do item não contam como parametrização. `numeric_parameterization` é reservado a casos em que os dados efetivamente variam entre instâncias.
