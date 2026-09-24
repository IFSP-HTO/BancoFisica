# Privacidade de dados de estudantes

O BancoFisica é um repositório de questões, geração de provas e estatísticas pedagógicas agregadas. **Ele não é um repositório de dados acadêmicos individuais.**

## Nunca versionar

Não faça commit de qualquer arquivo ou trecho que contenha:

- nomes de estudantes;
- e-mails, prontuários, matrículas ou outros identificadores;
- notas individuais;
- respostas individuais por questão;
- planilhas de correção aluno a aluno;
- scans, fotografias ou PDFs de provas/folhas de respostas;
- caligrafia ou assinaturas;
- saídas brutas de OCR/OMR ligadas a uma pessoa;
- mapeamentos entre código de prova e estudante;
- QR codes ou manifestos que codifiquem identidade de estudante;
- qualquer combinação que permita reidentificação.

A proibição vale também para exemplos, fixtures, logs, screenshots, issues e descrições de pull request.

## O que pode ser preservado

Somente informação agregada e anônima necessária para calibrar itens, por exemplo:

- identificador opaco da aplicação;
- identificador da questão/família;
- dificuldade prevista;
- número total de respondentes `n`;
- taxa agregada de acerto;
- observações pedagógicas que não mencionem indivíduos.

O arquivo `analytics/item_history.csv` segue esse princípio.

## Onde trabalhar com scans e correções

Use arquivos fora do clone do repositório ou `build/private/`. O diretório `build/` é ignorado pelo Git.

O script de análise aceita CSVs de respostas como entrada local, mas esses arquivos são efêmeros: **não os copie para áreas versionadas do BancoFisica**.

## Checklist antes de commit/PR

1. Revise o diff completo.
2. Procure nomes, e-mails, prontuários, notas e respostas individuais.
3. Confirme que nenhum scan ou planilha de correção foi adicionado.
4. Confirme que estatísticas de aplicação são agregadas e anônimas.
5. Se houver dúvida sobre possibilidade de reidentificação, não versione.

Se dados pessoais forem adicionados acidentalmente, remova-os do branch e do histórico antes do merge; apagar apenas o arquivo em um commit posterior não é suficiente para eliminar o conteúdo do histórico.
