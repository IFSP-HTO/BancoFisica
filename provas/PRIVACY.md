# Privacidade em avaliações

O BancoFisica pode gerar e corrigir provas, mas **dados individuais de estudantes não pertencem ao repositório**.

Nunca versione nomes, e-mails, prontuários, respostas individuais, notas, scans, fotos de cartões OMR ou arquivos que permitam reidentificar um estudante.

Arquivos de aplicação e correção devem permanecer fora do checkout ou em `build/private/`, que é ignorado pelo Git. Scripts de correção tratam esses arquivos como entrada local/efêmera.

Podem ser versionados apenas:
- manifestos de prova sem dados de estudante;
- gabaritos;
- configurações e templates;
- estatísticas agregadas e anônimas por item, como N e proporção de acertos.

Antes de qualquer commit ou PR relacionado a uma aplicação real, revise o diff procurando dados pessoais.
