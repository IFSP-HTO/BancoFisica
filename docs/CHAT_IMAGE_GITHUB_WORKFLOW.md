# Transferência de imagens do ChatGPT para o BancoFisica via Git blobs

## Objetivo e alcance

Procedimento quando uma imagem PNG/JPEG **final e aprovada** está acessível como arquivo binário no ambiente de trabalho do ChatGPT, mas este ambiente não compartilha um checkout Git autenticado do repositório. O conector GitHub recebe conteúdo codificado em Base64 pela operação create_blob; **não recebe um caminho local**. O método foi demonstrado com um PNG pequeno (78 bytes) em 11/11/2026, mas isso não assegura o transporte automático de arquivos grandes nem o acesso aos bytes de todo anexo do chat.

**Precedência:** se o PDF-fonte e o checkout Git estiverem no mesmo sistema de arquivos, utilizar diretamente tools/pdf_assets.py e docs/PDF_SOURCE_WORKFLOW.md. Não transportar por Base64 sem necessidade. Se a fonte pede preservação da figura original, não redesenhar ou editar sem aprovação. Manter os estados SOURCE-VISUAL definidos em AGENTS.md.

## Preflight obrigatório

1. Confirmar que o **arquivo final** (não prévia ou miniatura) está disponível por caminho real. Uma imagem apenas exibida no chat não garante acesso aos bytes; **não inventar caminho**. Sem bytes acessíveis, interromper o envio.
2. Conferir autorização de uso/licença, origem e aprovação de toda adaptação, ausência de dados de estudantes e caminho de destino esperado. Preferir BancoDeQuestoes/figuras, salvo organização existente por questão.
3. Abrir e revisar visualmente formato, dimensões e legibilidade. O script abaixo verifica assinatura/cabeçalhos básicos e **não substitui** inspeção visual ou decodificação completa.
4. Obter SHA de blob Git calculado dos **bytes exatos do arquivo**, ou seja, SHA-1 de uma sequência formada por cabeçalho Git do tipo blob e comprimento, byte nulo e bytes da imagem. Registrar também o SHA-256.
5. Executar (a partir do checkout que contém o script):

~~~bash
python tools/verify_image_blob.py /mnt/data/figura.png \
  --base64-out /tmp/bancofisica/figura.b64
~~~

A saída inclui tamanho, formato, dimensões do PNG, SHA de blob Git e SHA-256. O Base64 deve codificar os bytes exatos da imagem — não codificar o caminho, a visualização nem uma versão reescalada. O .b64 temporário **não deve ser versionado**.

## Transferência e commit via conector GitHub

1. Criar branch temática partindo da master atual, ou conferir explicitamente se está atualizada.
2. Obter o Base64 **completo**, sem truncar, e chamar create_blob com encoding igual a base64, e content igual à string codificada, no repositório IFSP-HTO/BancoFisica. A ferramenta **não lê o arquivo local automaticamente**.
3. Antes de criar tree/commit, comparar o SHA retornado com git_blob_sha1 informado pelo script. Se divergirem, **não commitar**. A verificação posterior pode ser repetida assim:

~~~bash
python tools/verify_image_blob.py /mnt/data/figura.png \
  --remote-sha SHA_RETORNADO
~~~

4. Usar create_tree com base_tree_sha da branch e um elemento por imagem (path correto; mode igual a 100644; type igual a blob; sha igual ao SHA validado).
5. Criar commit com create_commit e parent apontando à ponta atual da branch. Atualizar com update_ref sem force, verificando SHA esperado quando disponível.
6. Confirmar pelo tree/contents ou lista de arquivos do PR que os caminhos e respectivos SHAs existem no commit. A afirmação no corpo de um PR **não é prova**. O leitor do conector pode rejeitar conteúdo binário por exigir UTF-8: nesse caso, consultar metadados e SHA, sem tratar erro de UTF-8 como corrupção.
7. Checar o nome usado pelo .Rnw, caminhos relativos/include_supplement, compilação e testes R/exams para PDF e Moodle, CI e revisão/merge conforme solicitado.

Para lotes, conferir cada blob e preferir um único tree/commit temático. Não substituir o PNG/JPG final por arquivo .b64 no repositório.

## Falhas e fallback

- **Somente imagem exibida no chat, sem arquivo acessível:** bloquear o ativo; não alegar envio concluído. Pedir o arquivo ou usar mecanismo explícito de transferência.
- **Base64 grande demais, truncado ou erro do conector:** não insistir em fragmentos no repositório. Preferir acesso direto via git com autenticação adequada, caso exista; do contrário, usar upload normal de PNG/JPG na interface do GitHub para a branch. Esse fallback **pode exigir participação manual**.
- **SHA divergente:** bloquear antes do tree; confirmar arquivo final, codificação e eventual mudança/reencodificação.
- **PDF original:** seguir o procedimento de extração/crop fiel em docs/PDF_SOURCE_WORKFLOW.md.
- **Branch, permissões ou CI falharam:** preservar original, relatar a falha e não afirmar que o fluxo foi concluído.

## Critério de conclusão e limite conhecido

O teste de 11/11/2026 comprovou criação de blob remoto idêntico a PNG pequeno, com SHA Git coincidente. Os PRs #254 e #255 comprovam inclusão de PNG em commits. **Não está demonstrada uma ponte automática irrestrita entre qualquer anexo do chat e o conector.** O transporte sem intervenção humana depende do arquivo ser acessível e do tamanho caber no canal.

Um ativo visual estará pronto apenas após confirmação dos bytes finais, verificação do SHA retornado, associação ao tree/commit e caminho corretos, compilação/CI pertinente e revisão/merge quando autorizado.