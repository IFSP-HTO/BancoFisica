# Política de visibilidade da vitrine pública

Esta política define quais conteúdos do BancoFisica podem ser publicados no site público do projeto.

## Objetivo

O site público do BancoFisica é uma vitrine institucional e pedagógica. Ele serve para apresentar o projeto, explicar seu funcionamento, documentar o uso com R/exams e Moodle e mostrar alguns exemplos demonstrativos.

O site não deve expor o banco completo de questões usado em avaliações reais.

## Regra central

Somente conteúdos marcados explicitamente como demonstrativos podem ser publicados no site público.

Questões reais, questões ainda não revisadas, gabaritos completos, arquivos de exportação avaliativa e variações usadas em provas ou questionários reais não devem ser incluídos automaticamente na vitrine pública.

## Níveis de visibilidade

Ao criar metadados para exportação pública, use um dos níveis abaixo.

### `demo`

Pode aparecer no site público.

Use apenas para itens criados com finalidade demonstrativa, exemplos sacrificáveis ou versões adaptadas que não serão usadas como questão avaliativa real.

### `private`

Não pode aparecer no site público.

Use para questões do banco avaliativo, questões que podem ser usadas em Moodle, provas, listas avaliativas, simulados ou qualquer atividade em que a exposição pública prejudique a segurança avaliativa.

### `internal`

Não deve aparecer no site público por padrão.

Use para testes, rascunhos, documentação interna, scripts auxiliares ou itens em revisão. Um item `internal` só pode ser publicado se for revisado e convertido explicitamente para `demo`.

## Política para scripts de exportação

Qualquer script que gere dados para o site deve seguir as regras abaixo:

1. exportar somente itens com `visibility = "demo"`;
2. rejeitar ou ignorar itens sem campo de visibilidade;
3. nunca usar `private` como valor padrão para publicação;
4. registrar no JSON público que os dados são demonstrativos;
5. evitar incluir identificadores, gabaritos ou textos de questões avaliativas reais.

## Política para solucionários

Soluções podem aparecer no site somente quando a questão também for demonstrativa.

Soluções de questões privadas não devem ser expostas na vitrine pública, mesmo quando o enunciado não for publicado.

## Política para Moodle

A vitrine pode mostrar uma simulação visual de como uma questão demonstrativa apareceria em ambiente virtual.

O site público não deve publicar automaticamente XMLs avaliativos completos, bancos de questões completos ou pacotes de importação usados em avaliações reais.

## Exemplo de metadado público

```json
{
  "id": "DEMO-MEC-001",
  "title": "Velocidade média em um trajeto retilíneo",
  "area": "Mecânica",
  "subject": "Cinemática",
  "level": "Ensino Médio",
  "visibility": "demo",
  "tags": ["velocidade média", "unidades", "moodle"]
}
```

## Critério de revisão

Antes de publicar ou automatizar dados para o site, revise se:

- o item foi criado para demonstração;
- o item não será usado em avaliação real;
- a solução pode ser divulgada sem comprometer atividades futuras;
- o conteúdo não revela estrutura, gabarito ou parametrização de questões privadas.

## Relação com o projeto do site

Esta política atende à issue #38 e deve orientar as próximas etapas do projeto do site, especialmente o gerador automático de `site/data/questoes-demo.json`.
