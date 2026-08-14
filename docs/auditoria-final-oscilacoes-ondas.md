# Auditoria final — expansão de Oscilações e Ondas

Este documento consolida a revisão da Epic #94 e da issue #101. O escopo auditado é o conjunto de **75 questões novas** criado nos PRs #102, #105, #108, #112 e #117, além da revisão dos itens legados que permaneceram diretamente em `BancoDeQuestoes/ondas`.

A classificação de dificuldade abaixo é pedagógica e não cria um novo metadado nos `.Rnw`, pois o BancoFisica ainda não possui um campo canônico para dificuldade.

## 1. Resultado quantitativo

A meta da Epic foi atingida exatamente: **75 novas questões**, sendo **32 de Oscilações** e **43 de Ondas/Acústica**.

| Bloco | Novas questões | Fácil | Média | Difícil | Com figura |
|---|---:|---:|---:|---:|---:|
| Oscilações — MHS e massa–mola | 15 | 8 | 7 | 0 | 6 |
| Oscilações — energia | 5 | 1 | 4 | 0 | 3 |
| Oscilações — pêndulos | 5 | 3 | 0 | 2 | 2 |
| Oscilações — amortecimento e ressonância | 7 | 4 | 3 | 0 | 3 |
| Ondas progressivas, energia e equação de onda | 12 | 4 | 6 | 2 | 5 |
| Ondas em cordas | 6 | 2 | 3 | 1 | 1 |
| Interferência e superposição | 5 | 2 | 2 | 1 | 3 |
| Ondas estacionárias e ressonância | 6 | 3 | 3 | 0 | 5 |
| Som, intensidade e nível sonoro | 5 | 3 | 2 | 0 | 2 |
| Tubos, instrumentos e batimentos | 4 | 3 | 1 | 0 | 2 |
| Doppler e ondas de choque | 5 | 2 | 2 | 1 | 1 |
| **Total** | **75** | **35** | **33** | **7** | **33** |

Distribuição global de dificuldade:

- **fáceis:** 35/75 = **46,7%**;
- **médias:** 33/75 = **44,0%**;
- **difíceis:** 7/75 = **9,3%**.

A distribuição fica muito próxima da meta de 45% / 45% / 10%. Os itens difíceis não ficaram concentrados em um único assunto: aparecem em pêndulos, ondas progressivas, cordas, interferência e Doppler.

## 2. Cobertura conceitual

### Oscilações — 32 questões

A cobertura final contempla:

- período, frequência, frequência angular, posição, velocidade, aceleração e fase no MHS;
- leitura de gráficos `x(t)` e `a(x)`;
- relações de massa–mola, lei de Hooke e mola vertical;
- energia cinética, potencial e mecânica no MHS;
- pêndulo simples, dependência com o comprimento, independência da massa e determinação experimental de `g`;
- um item controlado de pêndulo físico com momento de inércia fornecido;
- amortecimento, energia em oscilação amortecida, resposta forçada e ressonância.

Não foi encontrada concentração excessiva que comprometesse o uso didático. O bloco possui quantidade suficiente de itens introdutórios para Ensino Médio e alguns itens de maior integração conceitual para progressão de dificuldade.

### Ondas e Acústica — 43 questões

A cobertura final contempla:

- classificação de ondas, parâmetros, perfil espacial, função de onda e sentido de propagação;
- número de onda, frequência angular e relação `v = lambda f` em contextos não redundantes;
- densidade linear, tração e velocidade em cordas;
- energia e potência transportadas por ondas;
- superposição, diferença de fase e diferença de caminho;
- nós, antinós, harmônicos, modos normais e ressonância;
- natureza do som, intensidade, fonte isotrópica e nível sonoro;
- tubos abertos e fechados, harmônicos permitidos e batimentos;
- casos controlados do efeito Doppler para fonte, detector e ambos em movimento;
- número de Mach e onda de choque.

A divisão planejada na Epic foi mantida: 8 questões de fundamentos/função de onda e 4 de energia/equação foram implementadas juntas em `ondas/progressivas`, totalizando 12 nesse diretório.

## 3. Classificação dos itens difíceis

Os sete itens classificados como difíceis são os que exigem maior integração de relações, interpretação de representação ou encadeamento de etapas:

- `oscilacoes/pendulos/Q04ClozeGraficoPenduloGravidade.Rnw` — extrai `g` da inclinação do gráfico `T^2 x L`;
- `oscilacoes/pendulos/Q05ClozePenduloFisicoBarra.Rnw` — combina momento de inércia, comprimento equivalente e período;
- `ondas/progressivas/Q10QuizEnergiaPerfilOnda.Rnw` — interpretação da distribuição instantânea de energia;
- `ondas/progressivas/Q11PotenciaMediaCorda.Rnw` — potência média em onda senoidal na corda;
- `ondas/cordas/Q06GraficoVelocidadeTensao.Rnw` — determina densidade linear a partir de `v^2 x F_T`;
- `ondas/interferencia/Q05ClozeAmplitudeResultante.Rnw` — amplitude resultante com fase relativa controlada;
- `ondas/doppler/Q04NumFonteDetectorAproximando.Rnw` — fonte e detector em movimento simultâneo.

Os demais itens exigem uma relação direta, comparação conceitual ou encadeamento curto, justificando as classificações fácil/média.

## 4. Solucionários e precisão numérica

O relatório de qualidade gerado após o PR #117 registrou, para os 75 novos arquivos:

- **75/75 com bloco de solução**;
- **75/75 parametrizados/dinâmicos**;
- **nenhum `short_solution`** no relatório estrutural;
- **nenhum alerta em `quality-alerts.csv`** para os diretórios da expansão;
- tipos: **35 `schoice`**, **22 `cloze`** e **18 `num`**.

Na revisão final, duas soluções de acústica que ficavam muito próximas do limiar heurístico de brevidade foram ampliadas:

- `ondas/acustica/Q02NumComprimentoOndaSom.Rnw`;
- `ondas/acustica/Q03NumIntensidadePotenciaArea.Rnw`.

Também foi corrigido o auditor `tools/audit_teaching.R`: questões objetivas que produzem alternativas por `answerlist(...)` dentro de chunks R/Sweave eram marcadas incorretamente como se não possuíssem lista de respostas. O auditor agora reconhece tanto o ambiente LaTeX quanto a chamada R.

## 5. Randomização e robustez

As questões novas usam conjuntos discretos e combinações controladas. Durante os PRs de implementação foram corrigidos casos potenciais de alternativas coincidentes em frequência forçada, razão entre modos normais e fonte isotrópica.

A suíte `tests/tests.R` fornece a verificação de integração da randomização:

- compila **cada `.Rnw` para Moodle XML com as sementes 1, 2 e 3**;
- executa cada compilação em sessão R isolada;
- valida raiz `<quiz>`, presença de questão exportada e referências de imagens;
- compila **cada `.Rnw` também para PDF**;
- executa a validação estrutural antes das compilações.

Nenhuma combinação das sementes padrão da suíte produziu divisão por zero, raiz inválida, chave ambígua, XML inválido ou falha de compilação nos PRs concluídos.

## 6. Figuras

A expansão possui **33 questões com gráfico ou esquema útil**, exatamente dentro da meta de aproximadamente 30–35 itens visuais.

Distribuição:

- Oscilações: **14** figuras;
- Ondas/Acústica: **19** figuras.

Todos os 33 elementos visuais novos são gerados proceduralmente nos próprios `.Rnw` com R. Portanto:

- não existem assets externos novos associados às 75 questões;
- não há recortes do material de referência;
- não há assets órfãos introduzidos pela expansão;
- a validação Moodle verifica que referências de imagem são resolvidas corretamente;
- os gráficos usam informação necessária à resolução, e não apenas decoração.

## 7. Física e consistência

A revisão transversal confirmou as relações e convenções usadas nos cinco lotes:

- MHS: `a=-omega^2 x`, posições especiais, `v_max`, `a_max` e período massa–mola;
- energia: `E=K+U`, `U=kx^2/2` e conservação no MHS ideal;
- pêndulos: regime de pequenos ângulos e `T=2*pi*sqrt(L/g)`; pêndulo físico com `I` explicitamente fornecido;
- ressonância: distinção entre frequência natural, frequência de excitação e resposta em regime permanente;
- ondas progressivas: sinal da fase coerente com o sentido de propagação;
- cordas: `mu=m/L` e `v=sqrt(F_T/mu)`;
- interferência: soma por superposição, fase e diferença de caminho;
- ondas estacionárias: `L=n*lambda/2` para corda fixa e frequências harmônicas correspondentes;
- acústica: `I=P/A`, fonte isotrópica `I=P/(4*pi*r^2)` e escala de decibéis;
- tubos: fundamentais de tubo aberto-aberto e fechado-aberto e harmônicos permitidos;
- Doppler: sinais separados para fonte e detector e verificação qualitativa do resultado;
- Mach: `M=v_F/v`, com regime supersônico para `M>1`.

## 8. Revisão dos itens legados em `ondas`

A expansão não tornou necessária a remoção de nenhum item legado. Há sobreposição temática, mas não duplicação semântica exata:

- `Q90ClozeRelacaoFundamentalOnda.Rnw` permanece como exercício elementar direto de `v=lambda f`, enquanto os novos itens usam a relação em funções de onda, cordas ou leitura gráfica;
- `Q91ClozeEcoDistancia.Rnw` permanece um problema específico de eco;
- `Q94QuizNivelSonoro.Rnw` trabalha razão de intensidades a partir de diferença em decibéis, enquanto o novo item calcula nível absoluto;
- os itens recentes `Q96QuizMorcegoDopplerEco.Rnw` e `Q98QuizCavidadeRessonanciaFechada.Rnw` têm contextos diferentes dos casos sistemáticos adicionados pela Epic.

Três itens legados receberam manutenção corretiva nesta revisão:

- `Q01QuizOndas.Rnw`: explicações completas para todas as afirmações e metadados de seção;
- `Q02QuizOndas.Rnw`: explicações completas, correção da definição de comprimento de onda e metadados de seção;
- `Q03Ondas.Rnw`: solucionário completo, arredondamento somente no resultado final, tolerância numérica e `exsection`.

Os dois grandes `mchoice` legados (`Q01` e `Q02`) continuam sendo itens amplos. Eles não foram removidos porque ainda servem como revisão diagnóstica geral e não são equivalentes a uma única questão nova.

## 9. Estrutura e metadados

A organização final da expansão é:

```text
BancoDeQuestoes/
├── oscilacoes/
│   ├── mhs/           # 15
│   ├── energia/       # 5
│   ├── pendulos/      # 5
│   └── ressonancia/   # 7
└── ondas/
    ├── progressivas/  # 12
    ├── cordas/        # 6
    ├── interferencia/ # 5
    ├── estacionarias/ # 6
    ├── acustica/      # 5
    ├── tubos/         # 4
    └── doppler/       # 5
```

A auditoria de qualidade não encontrou `exname` duplicado no banco. Os 75 novos itens têm `exname`, `extype`, solução e seção coerentes com sua pasta. Os dois itens de Óptica inicialmente localizados em `ondas` foram movidos para `optica` no PR #102.

## 10. Validação técnica e PRs

PRs da expansão:

| Etapa | PR | Resultado |
|---|---|---|
| estrutura + MHS/massa–mola | #102 | mesclado |
| energia/pêndulos/ressonância | #105 | mesclado |
| ondas progressivas/cordas | #108 | mesclado |
| interferência/estacionárias | #112 | mesclado |
| acústica/Doppler/Mach | #117 | mesclado |
| auditoria final | PR da #101 | deve ser o último gate da Epic |

Todos os cinco PRs de conteúdo foram mesclados após CI verde. O PR de consolidação da #101 deve repetir a suíte completa sobre o `master` atual; seu merge é o gate final para encerrar a Epic.

## 11. Conclusão

A expansão atende aos critérios da #94:

- **75** novas questões;
- **32** de Oscilações e **43** de Ondas/Acústica;
- dificuldade **46,7% fácil / 44,0% média / 9,3% difícil**;
- **33** questões com figura útil;
- cobertura de todos os blocos conceituais planejados;
- soluções explicativas em todos os itens novos;
- randomização submetida às três sementes padrão do CI;
- estrutura navegável e compatível com PDF/Moodle XML;
- nenhuma reprodução de figuras do material-fonte;
- correções finais em itens legados e no auditor pedagógico.

Não foi identificada pendência pedagógica ou técnica que deva bloquear o encerramento da Epic, condicionado apenas ao CI verde do PR final da #101.
