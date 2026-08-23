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

## Observabilidade e progresso em tarefas longas

1. Em tarefas com várias etapas, não permaneça silencioso durante sequências longas de execução. Após uma unidade lógica concluída ou após aproximadamente 5--8 ações de ferramenta sem retorno ao usuário, emita uma atualização curta de progresso e continue automaticamente quando a autorização para prosseguir já tiver sido dada.
2. Em trabalhos questão por questão, informe o status de cada questão concluída e prossiga para a seguinte sem solicitar nova confirmação, salvo quando surgir uma decisão pedagógica ou editorial que não possa ser inferida com segurança.
3. Para lotes, mantenha um contador explícito de progresso, por exemplo `7/35 implementadas`, e informe separadamente o estado das validações relevantes (`PDF`, `Moodle XML`, `R tests`, `Jekyll`).
4. Se surgir uma falha de CI, compilação ou processamento de imagem, informe imediatamente o componente que falhou, a hipótese diagnóstica atual e qual teste será feito a seguir. Não deixe o usuário sem saber se a execução continua.

## Diagnóstico e correção de falhas

1. Diagnostique antes de corrigir. Não altere arquivos por tentativa e erro quando a causa puder ser isolada.
2. Preserve e leia a mensagem original do processo que falhou (`exams2pdf`, `exams2moodle`, LaTeX, R, ferramenta de imagem etc.) antes de escolher a correção.
3. Durante debugging, faça a menor alteração capaz de testar a hipótese, rode a validação correspondente e só então avance para outras mudanças.
4. Evite commits temporários, placeholders e marcadores diagnósticos no branch do PR. Se um commit desse tipo for excepcionalmente necessário, remova-o do histórico efetivo antes do merge.
5. Se a tarefa foi autorizada até o merge, ela só está concluída após implementação, validações pertinentes, CI verde e confirmação de que o PR foi mesclado.

## Preflight para questões com figuras

Antes de considerar uma questão com ativo visual pronta para commit:

1. confirme que o arquivo que será versionado é exatamente o recorte final revisado, e não um intermediário com o mesmo nome;
2. verifique formato, dimensões e legibilidade do arquivo final;
3. confira se o `.Rnw` referencia o mesmo nome de arquivo usado por `include_supplement()`/`includegraphics`;
4. preserve somente a parte gráfica necessária da fonte, removendo texto corrido, enunciados, captions e explicações externas, salvo quando forem parte indispensável da própria figura;
5. mantenha apenas rótulos internos necessários ao entendimento do diagrama;
6. faça pelo menos uma compilação/validação pertinente antes de abrir ou considerar pronto o PR.

Quando for útil para evitar confusão entre arquivos intermediários, registre hash e dimensões do ativo final durante o trabalho.

## Branches e PRs

1. Antes de iniciar um novo lote, confirme que o branch parte do `master` atual ou compare explicitamente a divergência e atualize-o antes de acumular novas alterações.
2. Mantenha PRs pequenos e temáticos quando isso facilitar revisão, diagnóstico e rollback.
3. Não considere um PR finalizado apenas porque está `mergeable`; aguarde os checks exigidos e confirme o merge efetivo.
