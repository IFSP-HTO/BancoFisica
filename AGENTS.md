# Instruções para agentes

Estas regras valem para todo o repositório BancoFisica.

## Questões provenientes de PDFs

Quando uma questão estiver sendo criada ou adaptada a partir de um PDF-fonte e a imagem original precisar ser preservada:

1. Use o arquivo PDF local como fonte binária. Não transporte imagens por `base64`/`blob` quando o sistema de arquivos estiver disponível.
2. Use `tools/pdf_assets.py` e siga `docs/PDF_SOURCE_WORKFLOW.md`.
3. Primeiro verifique se a figura é um objeto raster independente com o comando `images`.
4. Se for independente, prefira `extract`, que copia os bytes incorporados sem reencodificação.
5. Se a figura for composta por vetores, textos ou múltiplos objetos, use `crop` para renderizar somente a região necessária diretamente do PDF.
6. Salve o ativo final em `BancoDeQuestoes/figuras`, seguindo a convenção de nomes já utilizada pelo banco.
7. Não redesenhe nem gere por IA uma figura quando a tarefa pedir a imagem original da fonte, salvo solicitação explícita do responsável pelo banco.
8. Revise visualmente o ativo antes de finalizar a questão e execute as validações/compilação pertinentes do `.Rnw`.

Para várias figuras da mesma prova, prefira o modo `batch` com manifesto CSV. Ele mantém cada PDF aberto durante o processamento de todos os ativos daquele documento.

## Trabalho iniciado antes deste fluxo

Se uma questão ainda não foi finalizada e sua figura veio de screenshot indireto, reconstrução, geração ou outro fluxo intermediário, substitua o ativo pelo resultado de `tools/pdf_assets.py` antes de concluir o PR, desde que o PDF-fonte esteja disponível e a intenção seja preservar a imagem original.
