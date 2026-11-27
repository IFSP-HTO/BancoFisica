# Aulas 14 e 15 — execução das aprovações de 27/11/2026

Fonte de decisões: `aprovacoes_optica_aulas14_15.json` entregue pelo responsável do BancoFisica. A lista autoriza importação/parametrização de itens específicos, mas **não** autoriza transformar uma questão de outro assunto em Óptica, copiar incorretamente uma somatória, nem redesenhar um visual sem controle. Referencial: aula 14 Óptica geométrica; aula 15 Reflexão e espelhos planos.

## Resumo das 77 decisões

- 13 importar estáticas (embaralhar alternativas quando fisicamente seguro);
- 2 parametrizar em TikZ (PUC-Campinas 2010 Q30 e UFRGS 2014 Q11);
- 2 parametrizar sem figura (EEAR CFS2 2025 Q70 e PUC-RS inverno 2013 Q6);
- 20 solicitar figura (não implementar automaticamente; **exceções com instrução explícita**: Univesp 2025-2 Q54 permite recorte fiel sem texto; FAMECA 2019 Q41 pede tentar recorte mantendo imagem fixa e variar somente texto);
- 37 pendentes, não importar;
- 3 já no Banco, não duplicar.

## Conflitos e validações

- ID 6 — EEAR CFS2 2020 Q86: referência do catálogo localizada em `https://provas.professorfilatte.com.br/eear-2020-cfs-2-fisica-questao-86` **não é Óptica**; deixar bloqueada por referência.
- ID 20 — ENEM 2015 Q58: já foi incorporada como `BancoDeQuestoes/optica/Q113QuizEnem2015AlhazenCamaraEscura.Rnw` (caderno azul Q85), portanto não criar duplicata nem alterar sem novo pedido.
- ID 4 — UNEMAT 2008 Q3: a questão requer associação com lentes, fibra óptica, miragem e arco-íris, que extrapola as aulas 14 e 15. Registrar como *fora do recorte didático* apesar da aprovação estática.
- IDs 2 e 9 — UEPG 2024 Q22 e UEM inverno 2016 Q20: a fonte usa formato de **somatória**; manter pesos e `num`, evitando conversão indevida a múltipla escolha simples.
- ID 18 — PUC-SP inverno 2019 Q11: todas as quatro alternativas são **figuras**; preservar em recortes independentes para poder embaralhar sem perda da identificação correta.
- ID 42 — FUVEST 2007 Q15: requer inspecionar figura original antes de converter.
- ID 19 — UFRGS 2014 Q11: figura de câmara escura com raio cruzando o orifício; autorização explícita para reconstrução TikZ, **source-visual: adapted-approved**.
- ID 17 — PUC-Campinas 2010 Q30: a fonte não contém figura, mas o responsável aprovou adicionar TikZ paramétrico, sem alegar que o desenho é o original.
- A questão UNIVESP 2025 Q54 (ID 10) já teve um esquema de câmara escura fornecido pelo responsável em conversa anterior; é admissível somente importar se a figura final corresponder fielmente ao enunciado e se o pipeline efetivamente transportar seus bytes. Não usar imagem substituta.

## Regras de execução

Cada item novo leva referência de fonte, dificuldade, `SOURCE-VISUAL` e explicação própria. Proibir imagens fictícias. R/exams deve validar `.Rnw` e exportação antes de disponibilizar à master. Uma aprovação na planilha não equivale a licença de terceiros para redistribuição pública: manter atribuição de prova e origem; verificar direitos dos materiais antes de publicar reproduções literais ou figuras protegidas.
