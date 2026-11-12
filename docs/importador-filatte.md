# Importador piloto: Professor Filatte — Santa Casa 2027

Workflow manual: **Actions → Importar questao de optica (Filatte) → Run workflow**.

O primeiro piloto suporta **somente a questão 66 da Santa Casa 2027**. Outros itens não são importados automaticamente; exigem cadastro do gabarito, classificação e revisão pedagógica. O script obtém a página publicada e o PNG original, verifica assinatura, decodificação, dimensões, tamanho e SHA-256. Não redesenha, não cria imagem sintética, não remove dados do original. Caso a rede, o HTML ou a imagem falhem, o job aborta.

Os arquivos resultantes são um .Rnw em `BancoDeQuestoes/optica/` e um PNG em `BancoDeQuestoes/figuras/`. O job tenta criar um PR sem merge, para inspeção humana. **A imagem da página pode trazer texto de enunciado além do diagrama**: o PR fica sujeito a revisão visual para decidir o recorte fiel, evitando duplicação. O estado SOURCE-VISUAL indica origem intacta, não validação pedagógica concluída.

Antes do merge: abrir a imagem original, conferir figura/alternativas, ajustar a apresentação sem redesenhar, testar PDF e Moodle via pacote R `exams`, conferir permissões de reuso. Em reexecuções, uma branch já existente ou arquivos existentes causam falha segura (não sobrescreve).

Execucao local: `python -m pip install requests beautifulsoup4 Pillow && python tools/import_filatte.py --dry-run`.
