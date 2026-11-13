# Importação de questões de Óptica — Professor Filatte

## Situação do pipeline

O importador trabalha por **manifestos de URLs e gabaritos**, começando com um lote pequeno. O processo não faz merge automático de questões. Foi testado em GitHub Actions para Santa Casa 2027 Q66 (piloto original) e, depois, para três fontes adicionais:
- Humanitas 2027, Física Q38 — E — lente plano-convexa;
- Einstein 2027, Física Q38 — B — fibra óptica (dois desenhos originais);
- Beneficência Portuguesa 2027, Física Q39 — B — sombra e penumbra.

**Fontes e imagens:** o site bloqueou com HTTP 403 as páginas HTML ao tentar buscá-las pelo GitHub Actions em lote. Para essas três questões, as URLs públicas dos PNGs foram conferidas manualmente e fixadas em `data/filatte-optica-piloto.json`. O script `tools/stage_filatte_optica.py` tenta acessar a página; se receber 403 e se o manifesto contiver URL pública da imagem, título e gabarito já revisados, usa esses metadados em modo limitado. Nunca inventa transcrição ou gabarito. O relatório indica `parser_status=source-html-403-verified-by-review`. Qualquer resposta inesperada, hash divergente ou imagem inválida bloqueia o item.

## Fluxo

1. **Estágio**: `python tools/stage_filatte_optica.py --manifest data/filatte-optica-piloto.json` baixa os PNGs originais e guarda hashes SHA-256, dimensões e metadados em `build/filatte-stage/`. O estágio de HTML é opcional somente para itens com metadados públicos previamente revisados.
2. **Recorte fiel**: `python tools/crop_filatte_optica.py` verifica o SHA-256 do PNG completo contra `data/filatte-optica-crops-2027.json` e extrai somente as coordenadas de figura previamente revisadas visualmente. Não redesenha a figura, não faz OCR e não substitui por IA. Cada recorte tem novo SHA-256 em `crops-audit.json`.
3. **Revisão editorial**: reproduzir o enunciado e alternativas que constam na fonte; escrever solução independente; inserir `SOURCE-VISUAL: original-crop` e URL nos metadados `.Rnw`. Validar manualmente cada figura e resposta. Se a imagem estiver sem acesso, bloquear a questão, sem publicar uma imagem substituta.
4. **Commit**: o workflow de estágio da branch de implementação pode criar uma branch separada **somente com os PNGs revisados** para posterior inclusão dos `.Rnw` e abertura de PR. A etapa nunca faz merge automático. Em execuções repetidas, se a branch de imagens já existir, não reescreve os arquivos.
5. **Testes**: R tests, compilação do pacote `exams`, integridade de imagens e Jekyll CI devem ficar verdes antes de um merge.

Workflow: `.github/workflows/import-filatte-optica.yml`, aba Actions. A branch de trabalho é `feat/importador-filatte-optica`; o lote de questões é mantido separadamente em `import/filatte-optica-2027-lote2`.

## Para expandir o banco

- Acrescentar itens ao manifesto com `id`, `url` e `correct` conferido. Se houver bloqueio 403, fornecer também `image_url` e `title` revisados. Não automatizar descoberta de gabaritos pelo nome de arquivo.
- Antes de ativar novos recortes, abrir o PNG original, identificar **todos** os diagramas usados e registrar coordenadas e SHA em manifesto próprio. Não reutilizar coordenadas de outra prova.
- Criar soluções e `.Rnw` com o padrão do repositório; detectar duplicatas por prova+ano+questão e nomes de arquivo. Não misturar questões de áreas diferentes apenas por estar na mesma prova.
- Limitar tamanho dos lotes para identificar falhas de formato; em falha de parser/HTTP/figura, preservar relatório do item bloqueado e continuar nos demais.

A contagem de 736 itens pertence ao catálogo de Óptica do site, **não** a questões já incorporadas ao BancoFisica. O pipeline não incorpora automaticamente todo o catálogo.
