# Provas impressas e OMR

Esta pasta define o padrão oficial de provas impressas do BancoFisica. Quando um usuário pedir uma prova **"no padrão BancoFisica"**, agentes e scripts devem reutilizar estes arquivos em vez de recriar o layout.

## Padrão IFSP-OMR

O perfil `profiles/ifsp-omr.yaml` registra as decisões consolidadas nas aplicações de 2026:

- 10 questões de múltipla escolha, sempre A--E;
- por padrão, 5 fáceis + 5 médias;
- 10 versões equivalentes, com parâmetros e alternativas embaralhados;
- folha 1 exclusiva para identificação e cartão-resposta;
- QR code contém **somente o identificador interno da versão**, nunca o gabarito;
- versão não deve aparecer como "A", "B", "1", "2" etc. para o aluno;
- páginas de questões em duas colunas;
- cabeçalho discreto depois da folha de respostas;
- alvo de 4 páginas, sem páginas quase vazias;
- figuras devem caber na coluna e ser verificadas visualmente;
- gabarito-mestre e manifesto machine-readable são obrigatórios.

## Fluxo recomendado

1. Selecionar questões do Banco por conteúdo, nível e habilidades.
2. Evitar repetir a mesma família de questão quando a prova for paralela a outra turma.
3. Parametrizar numericamente usando os mecanismos já presentes nos `.Rnw`.
4. Embaralhar alternativas mantendo o gabarito correspondente.
5. Criar um manifesto no formato de `examples/lancamento-obliquo/manifest.example.json`.
6. Executar `python3 tools/generate_printed_exam.py manifest.json --compile`.
7. Renderizar e inspecionar pelo menos as versões 1, 6 e 10 e também qualquer versão com valores extremos.
8. Antes de imprimir, validar: 10 questões, A--E, QR/código, gabarito, 4 páginas, ausência de overflow, figuras legíveis.
9. Após aplicação, usar o manifesto como fonte de verdade para correção OMR.
10. Registrar em `analytics/item_history.csv` apenas estatísticas agregadas e anônimas quando houver resultados reais. **Nunca** versionar respostas, notas, nomes, scans ou qualquer outro dado de estudante. Veja `PRIVACY.md`.

## Critérios pedagógicos

"Fácil" significa uma aplicação direta ou um conceito fundamental, tipicamente uma etapa principal. "Médio" admite duas ou três etapas, mas não uma cadeia longa de cálculos. A dificuldade deve considerar também a população-alvo.

Metadados recomendados nos `.Rnw`:

```text
%% BF-Difficulty: easy
%% BF-Skills: apice; componentes-da-velocidade
%% BF-Steps: 1
%% BF-Family: LO-velocidade-no-apice
%% BF-Level: 1ano
%% BF-Print: suitable
```

Para problemas integrados:

```text
%% BF-Difficulty: medium
%% BF-Skills: movimento-horizontal; movimento-vertical
%% BF-Steps: 2
%% BF-Reasoning: x-to-t-to-y
```

## Formato do manifesto

O gerador recebe JSON. Cada versão contém um código opaco, um ID interno, o gabarito e as questões já materializadas em LaTeX. Isso separa a seleção/parametrização pedagógica da montagem gráfica.

Veja `examples/lancamento-obliquo/manifest.example.json`.

## Privacidade

Dados de estudantes são sigilosos e não pertencem ao repositório. Arquivos com nomes, matrículas, respostas, notas, folhas OMR ou scans devem ficar fora do Git ou em `build/private/`, que é ignorado. O BancoFisica só preserva resultados agregados e anônimos por item. Consulte `PRIVACY.md` antes de trabalhar com dados de aplicação.

## Correção e análise

O manifesto é a fonte de verdade: `codigo -> gabarito`. Marcações em branco ou múltiplas devem ser sinalizadas para revisão, nunca adivinhadas.

O arquivo `analytics/item_history.csv` pode acumular somente dificuldade empírica **agregada e anônima** por aplicação. Não substitua dificuldade prevista por um único índice observado: registre ambos. Nunca inclua dados que permitam reconstruir o desempenho de um estudante.
