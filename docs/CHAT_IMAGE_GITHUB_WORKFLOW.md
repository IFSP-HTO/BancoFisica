# Transferência de imagens do ChatGPT para o BancoFisica via Git blobs

## Objetivo e alcance

Procedimento quando uma imagem PNG/JPEG **final e aprovada** está acessível como arquivo binário no ambiente de trabalho do ChatGPT, mas este ambiente não compartilha um checkout Git autenticado do repositório. O conector GitHub recebe conteúdo codificado em Base64 pela operação create_blob; **não recebe um caminho local**. O procedimento foi demonstrado com PNGs de 78 bytes e 590.321 bytes, com integridade de SHA comprovada. Ainda é necessário que os bytes do anexo sejam realmente acessíveis como arquivo; não há garantia de tamanho ilimitado.

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

## Ponte automática entre arquivo local e conector GitHub

Quando a imagem está em /mnt/data (ou outro caminho local disponível ao ChatGPT), é possível encaminhá-la **sem upload manual do usuário**, usando uma área temporária na Biblioteca de arquivos do ChatGPT. Essa etapa só se aplica quando não existe checkout Git autenticado no mesmo ambiente.

1. Gerar um arquivo de texto contendo **somente Base64** dos bytes originais, com linhas de **4096 caracteres**, pelo comando de preflight acima (padrão do verificador). O SHA Git calculado localmente é a referência para a checagem de integridade.
2. Usar a ferramenta **Files / manage_library**, operação upload com container_path real e destination_path temporário de nome único, para colocar esse arquivo de staging na **Biblioteca pessoal**. Isso é uma etapa interna executada pelo agente, não uma ação de upload do usuário. Guardar o file_id e library_file_id retornados. Não expor o Base64 no diálogo.
3. Usar **Files / read** com o file_id exato. Para Base64 grande, ler blocos contíguos (ex.: 10 linhas por leitura), usando start_line e max_lines, até cobrir todas as linhas. A ferramenta pode devolver um bloco inteiro como um único elemento de content. Concatenar os trechos **na ordem de start_line** e remover apenas caracteres de espaço/quebra de linha.
4. Validar antes da chamada ao GitHub: segmentos consecutivos, ausência de warnings, nenhuma lacuna nas linhas, comprimento total Base64 esperado, caracteres válidos e ausência de truncamento. Para tamanho N de bytes, o comprimento esperado é **4 × ceil(N/3)**. Se o arquivo não puder ser lido integralmente, **bloquear**, sem commitar.
5. Chamar **GitHub / create_blob**, encoding base64, com a string integral que foi reconstituída **no mesmo ambiente das ferramentas conectadas**. Comparar o SHA Git de retorno com o calculado localmente. Divergência implica falha.
6. Remover o arquivo de staging da Biblioteca ativa com **Files / manage_library**, operação delete pelo **library_file_id** real, inclusive em caso de falha. Essa exclusão **move o arquivo para a lixeira**, não garante apagamento físico imediato. O conteúdo de staging é uma cópia recuperável da imagem; não usar esse caminho para dados sigilosos ou de estudantes.
7. Depois do SHA validado, associar a imagem ao tree/commit e verificar o caminho e o SHA no PR conforme a seção seguinte.

**Teste efetivo (11/11/2026):** imagem PNG local com 512 × 384 pixels, 590.321 bytes, Base64 de 787.096 caracteres em 193 linhas de 4096 (última linha menor). O caminho arquivo local → Files upload temporário → Files read em partes → GitHub create_blob foi concluído sem nenhuma ação manual do usuário. SHA local e remoto: ca683a2bf2f98f7c356e29f21b681ecdc0f5a032. O teste criou apenas um blob não associado a commit; não prova, por si, que todo tipo/tamanho de anexo ou edição gerada no chat estará disponível como arquivo.

## Transferência e commit via conector GitHub

1. Criar branch temática partindo da master atual, ou conferir explicitamente se está atualizada.
2. Obter o Base64 **completo**, sem truncar, preferencialmente pela ponte automática acima, e chamar create_blob com encoding igual a base64 e content igual à string codificada no repositório IFSP-HTO/BancoFisica. A ferramenta GitHub **não lê o arquivo local automaticamente**.
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
- **Base64 grande demais, leitura incompleta do staging, truncamento ou erro do conector:** não insistir em fragmentos no repositório. Remover o arquivo temporário da Biblioteca ativa. Preferir acesso direto via git com autenticação adequada, caso exista; do contrário, usar upload normal de PNG/JPG na interface do GitHub para a branch. Esse fallback **pode exigir participação manual**.
- **SHA divergente:** bloquear antes do tree; confirmar arquivo final, codificação e eventual mudança/reencodificação.
- **PDF original:** seguir o procedimento de extração/crop fiel em docs/PDF_SOURCE_WORKFLOW.md.
- **Branch, permissões ou CI falharam:** preservar original, relatar a falha e não afirmar que o fluxo foi concluído.

## Critério de conclusão e limite conhecido

Os testes de 11/11/2026 comprovaram dois blobs com SHA Git correspondente: um PNG pequeno de 78 bytes vindo do ambiente de arquivos do ChatGPT e um PNG válido de 512 × 384 pixels (590.321 bytes, Base64 com 787.096 caracteres) produzido programaticamente no ambiente do conector. Este PNG maior foi reconstituído independentemente com Python e validado com Pillow. Os PRs #254 e #255 comprovam inclusão de PNG em commits. **Um segundo teste com o PNG real no sistema de arquivos demonstrou também o transporte automático completo de /mnt/data para o conector via staging temporário na Biblioteca, com o mesmo SHA.** Ainda resta validar a anexação ao commit de uma imagem final aprovada e confirmar a acessibilidade de cada novo anexo. **Não está demonstrada uma ponte automática irrestrita entre qualquer anexo do chat e o conector.** O transporte sem intervenção humana depende do arquivo ser acessível e do tamanho caber no canal.

Um ativo visual estará pronto apenas após confirmação dos bytes finais, verificação do SHA retornado, associação ao tree/commit e caminho corretos, compilação/CI pertinente e revisão/merge quando autorizado.