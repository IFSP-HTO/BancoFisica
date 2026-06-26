# Checklist básica de responsividade e acessibilidade do site

Esta checklist registra os critérios manuais usados para a primeira versão pública da vitrine do BancoFisica.

## Escopo

Esta verificação cobre apenas aspectos básicos do MVP do site. Ela não substitui uma auditoria WCAG completa nem testes automatizados de frontend.

## Itens verificados

- Navegação principal presente em todas as páginas públicas do site.
- Link "Pular para o conteúdo" disponível no início do corpo da página.
- Conteúdo principal identificado com `main` e `id="conteudo"`.
- Links, botões, filtros, campos de busca, seletores e `summary` navegáveis por teclado.
- Estado de foco visível para navegação por teclado.
- Layout principal, cards, filtros e preview estilo Moodle empilham em telas menores.
- Textos usam tamanhos relativos e espaçamento suficiente para leitura.
- Cores principais preservam contraste razoável para o MVP.
- Páginas usam elementos semânticos básicos: `header`, `nav`, `main`, `section`, `article` e `footer`.
- A vitrine pública continua sem expor questões reais ou banco avaliativo completo.

## Páginas revisadas

- `site/index.html`
- `site/questoes.html`
- `site/documentacao.html`
- `site/visibilidade.html`

## Observação

Novas páginas públicas do site devem seguir o mesmo padrão: navegação principal, link de pular conteúdo, estrutura semântica e comportamento legível em telas pequenas.
