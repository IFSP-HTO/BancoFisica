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

O fluxo local deve usar o ZIP oficial do Inep ou a pasta extraída desse ZIP. Não é necessário ler nem versionar os microdados de participantes.

## Base canônica

`metadata/enem/banco_enem_itens.csv` contém uma linha por relação entre um arquivo do BancoFisica e um item-fonte do ENEM.

Campos principais:

- `bank_path`: arquivo `.Rnw` do BancoFisica;
- `relation`: `direct` ou `inspired`;
- `adaptation_kind`: natureza da adaptação; inicialmente `pending_review`;
- `source_year`, `source_application`, `source_caderno`, `source_color`, `source_position`: referência editorial do item-fonte;
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

## Integração futura nos .Rnw e no site

Depois que `CO_ITEM` e os campos oficiais estiverem auditados, cada `.Rnw` poderá receber apenas uma referência curta, por exemplo:

```text
%% ENEM-SOURCE: 2024; CO_ITEM=...; metadata=metadata/enem/banco_enem_itens.csv
```

A tabela continuará sendo a fonte canônica. O site poderá então apresentar habilidade e CCI do item-fonte, além de oferecer filtros por ano, habilidade e parâmetros TRI.

## Privacidade

Esta integração usa apenas metadados públicos de itens. Nenhum registro individual de participante deve ser baixado para o repositório ou versionado.
