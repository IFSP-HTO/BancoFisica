# BancoFisica — importação auditável por assunto e lote

## Escopo

O método desenvolvido para Óptica no site Professor Filatte passa a atender
qualquer **assunto** do BancoFisica, começando por Hidrostática. A seleção,
auditoria, preservação de figuras e os critérios pedagógicos não dependem
da disciplina ou do assunto. Por enquanto, o **único adaptador web
implementado** continua sendo o Professor Filatte; outras fontes requerem
adaptadores específicos. O código não publica .Rnw nem faz merge sozinho.

A prioridade é incorporar **questões-base diferentes**, e não variantes que
apenas sorteiam outros valores numéricos. Trabalhar em lotes de 4–6 questões
depois de avaliação individual. Preservar algumas boas questões para a prova.

## Fluxo obrigatório

1. **Triagem**. Identificar fonte, instituição, ano, questão, URL, gabarito,
   tópico, habilidade, dificuldade, ganho em relação ao banco e justificativa.
   Rejeitar itens ambíguos, repetitivos ou fora do currículo do segundo ano.
2. **Conferência inicial**. Abrir a questão original e revisar enunciado,
   gabarito e duplicidade. Mudar decisão de candidata para selecionada somente
   depois de validar os dados. Registrar a verificação no manifesto JSON.
3. **Estágio**. Baixar os PNGs integrais, registrar SHA-256, dimensões e
   metadados. Se o HTML da fonte retornar 403, o fallback para imagem pública
   exige enunciado e gabarito previamente conferidos. Não gerar transcrição
   ou resposta a partir de suposições.
4. **Recorte fiel**. Abrir o PNG original, identificar todas as figuras,
   marcar visual_reviewed=true, salvar coordenadas e hash da imagem-fonte.
   Não redesenhar a figura nem substituir por IA; o recorte valida hash,
   limites e nomes de arquivos e não sobrescreve imagens existentes.
5. **Preparação das questões**. Produzir .Rnw com atribuição de fonte,
   solução independente e parâmetros bem definidos. Inspecionar valores
   extremos, condições físicas, precisão dos dados e distratores.
6. **Revisão final e testes**. Rodar R/exams em diferentes variantes,
   conferir respostas/diagramas e direitos de reutilização. Somente depois
   usar decisão aprovada com todas as verificações e notas documentadas.
7. **PR separado por lote**. Integrar apenas após revisão pedagógica e
   aprovação dos testes. Nunca importar tudo o que estiver no catálogo,
   nem fazer merge automático.

## Comandos da camada generalizada

Começar pelo manifesto de Hidrostática, que foi criado **vazio** de propósito
para não simular uma seleção que ainda não aconteceu.

~~~bash
python tools/importar_questoes.py validate \
  --manifest data/lotes/filatte-hidrostatica-001.json
~~~

Depois de selecionar e conferir as fontes, preparar os arquivos de origem:

~~~bash
python -m pip install requests beautifulsoup4 Pillow
python tools/importar_questoes.py stage \
  --manifest data/lotes/filatte-hidrostatica-001.json \
  --out-dir build/questoes-stage
~~~

Depois de abrir e conferir cada PNG integral, criar um arquivo de recortes
em data/lotes/filatte-hidrostatica-001-crops.json. Cada item deve conter:
id, source_sha256, visual_reviewed=true e figures, com name e box em pixels
[esquerda, topo, direita, base].

~~~bash
python tools/importar_questoes.py crop \
  --manifest data/lotes/filatte-hidrostatica-001-crops.json \
  --stage-dir build/questoes-stage \
  --dest BancoDeQuestoes/figuras
~~~

Após gerar, revisar e testar os .Rnw:

~~~bash
python tools/importar_questoes.py validate \
  --manifest data/lotes/filatte-hidrostatica-001.json \
  --require-approved
python -m unittest discover -s tests -p test_importar_questoes.py
~~~

O comando validate verifica também se a URL da questão já aparece em
algum .Rnw existente. A busca por semelhança conceitual continua sendo
tarefa editorial; URLs diferentes podem apontar para a mesma questão-base.

## Ficha pedagógica (um objeto JSON por questão)

Modelo **ilustrativo**, não é uma questão real nem uma fonte conferida:

~~~json
{
  "id": "instituicao-2025-q99",
  "url": "https://provas.professorfilatte.com.br/exemplo-2025-fisica-questao-99",
  "correct": "B",
  "title": "Exemplo sem validade como fonte",
  "image_url": "https://wdlpxyudndyrkigvupfy.supabase.co/storage/v1/object/public/questoes/exemplo.png",
  "pedagogy": {
    "topic": "Empuxo: peso aparente",
    "skill": "Interpretar a leitura do dinamômetro durante a imersão",
    "difficulty": "media",
    "decision": "candidata",
    "justification": "Cobre habilidade insuficientemente representada",
    "reason_for_selection": "Estratégia diferente das questões já existentes",
    "quality": {
      "clareza": 4,
      "correcao_fisica": 5,
      "alinhamento_curricular": 5,
      "raciocinio": 4
    }
  },
  "verification": {
    "enunciado_conferido": false,
    "gabarito_conferido": false,
    "fisica_conferida": false,
    "figura_conferida": false,
    "direitos_revisados": false,
    "duplicidade_conferida": false,
    "parametrizacao_testada": false,
    "exams_testado": false
  }
}
~~~

Decisões válidas: candidata, selecionada, rejeitada, aprovada. Para passar
a selecionada, precisam ser verdadeiros enunciado_conferido e
gabarito_conferido, e o ganho em relação ao banco atual deve ser justificado.
A aprovação final exige TODOS os campos de verification verdadeiros,
rubrica preenchida, correção física igual a 5 e alinhamento curricular
pelo menos 4. A decisão é docente, nunca inferida automaticamente.

### Rubrica de qualidade (1 a 5)

| Critério | 1 | 3 | 5 |
|---|---|---|---|
| Clareza | Ambígua | Precisa de ajustes | Completa e inequívoca |
| Correção física | Erro relevante | Ressalvas | Modelo fisicamente correto |
| Alinhamento curricular | Fora do programa | Parcial | Central ao que foi ensinado |
| Raciocínio | Apenas lembrança | Aplicação orientada | Transferência e interpretação |

Completar qualitativamente a avaliação com: plausibilidade dos
distratores, relevância da figura, precisão numérica, carga de cálculo,
possibilidade de parametrização segura, risco de respostas múltiplas
e utilidade para lista, prova ou desafio. Em particular, uma questão pode
ser excelente em um vestibular e inadequada a uma turma regular do 2º ano.

## Priorização em Hidrostática

Partir das lacunas diagnosticadas no BancoFisica: pressão F/A, pressão
absoluta/manométrica, gráficos pressão-profundidade, manômetros,
tubos em U com líquidos distintos, Pascal com deslocamento de êmbolos,
Arquimedes com peso aparente e fração submersa. Não importar outra
questão de simples comparação de densidades apenas para aumentar a
contagem. O primeiro lote será selecionado após a triagem, não neste PR.

## Proveniência e direitos

Registrar URL original, prova, questão e, se houver figura, metadados
SOURCE-VISUAL: original-crop nos comentários do .Rnw. Os originais e
relatórios de hashes são evidência de auditoria, não autorização automática
de redistribuição.

O fato de PNGs estarem públicos não significa que sua licença permita
copiar a figura. Revisar os direitos antes da publicação. Sem permissão
apropriada, criar representação independente ou não incorporar o item.
Não inventar imagem, transcrição ou gabarito quando houver HTTP 403.

## Compatibilidade

O pipeline anterior de Óptica permanece intacto:
- tools/stage_filatte_optica.py, que fornece o adaptador de estágio;
- tools/crop_filatte_optica.py, que preserva o recorte original;
- .github/workflows/import-filatte-optica.yml, responsável pelo piloto.

A nova camada tools/importar_questoes.py reutiliza esses mecanismos para
diferentes assuntos e exige manifesto editorial por lote. A migração
completa do legado pode ocorrer em PR futuro, depois dos testes.
