# Expansão de lançamentos — PDF 007

Fonte de trabalho: `007_fisica_lancamento_horizontal_obliquo.pdf` (Projeto Medicina / Futuro Militar).

Este diretório documenta a triagem das questões e, em particular, a política de tratamento das figuras antes da incorporação dos novos itens ao BancoFisica.

## Princípio para as figuras

1. Preservar a figura original sempre que possível.
2. Extrair o objeto de imagem embutido no PDF, em vez de usar captura de tela da página.
3. Quando números estiverem gravados na figura, manter uma imagem-base original. Há duas estratégias aceitas: (a) substituir somente a pequena região numérica em tempo de geração com `png` + `grid`; ou (b) produzir uma única versão simbólica da própria figura original, trocando apenas os números por letras como `h`, `d` e `theta`.
4. Não alterar permanentemente a imagem-base original. As versões derivadas ficam identificadas separadamente.
5. Redesenhar por código somente quando a geometria/gráfico em si precisar variar, ou quando a figura-fonte tiver qualidade insuficiente para uso em prova.

## Inventário das figuras

### A. Original direta, sem alteração

| Questão | Conteúdo da figura | Procedimento |
|---|---|---|
| Q01 | três trajetórias horizontais, T1/T2/T3 | extrair e usar original |
| Q09 | duas partículas em alturas h1/h2 chegando a P | extrair e usar original |
| Q10 | painel quadriculado com A–E | extrair e usar original; item fixo |
| Q13 | plano inclinado, mesa, cesta, d e y | extrair e usar original |
| Q25 | moto/rampa com H, D e 45 graus | extrair e usar original |
| Q27 | trajetória com theta e h | extrair e usar original |
| Q28 | trajetória com pontos A e B | extrair e usar original |
| Q35 | cinco jatos numerados | extrair e usar original; item conceitual |
| Q46 | catapulta e trajetória | extrair e usar original |

### B. Original como base + rótulos substituídos por código

| Questão | Rótulos presentes na fonte | Tratamento |
|---|---|---|
| Q03 | 78,4 m | substituir a altura por valor sorteado |
| Q06 | 5,0 m e 7,5 m | substituir altura e alcance por valores sorteados |
| Q08 | 1,25 m e 2,5 m | substituir altura e alcance por valores sorteados |
| Q12 | 0,80 m | substituir a altura por valor sorteado |
| Q19 | 4800 m, 300 m e 45 graus | substituir alturas e ângulo por valores sorteados |
| Q38 | 30 graus e 10 m | substituir ângulo e altura do alvo por valores sorteados |
| Q43 | 2,5 m | substituir o desnível por valor sorteado |

Quando a região do rótulo permite uma sobreposição robusta, os valores podem ser escritos programaticamente. Quando isso fragiliza a figura, usa-se uma versão simbólica única (`h`, `d`, `theta` etc.) e os valores sorteados ficam no enunciado. Em ambos os casos, a geometria e a arte da figura original são preservadas.

### C. Figura gerada por código

| Questão | Motivo |
|---|---|
| Q11 | os próprios gráficos x(t) e y(x) definem os dados; variar somente os rótulos não é suficiente |
| Q19 | a figura-fonte é muito pequena e contém artefatos de digitalização; o esquema é regenerado preservando os elementos físicos essenciais |

Para Q11, a figura deverá ser gerada a partir dos mesmos parâmetros usados na solução, mantendo o estilo simples de eixos e grade da fonte.

### D. Reaproveitamento / sem nova figura

| Questão | Decisão |
|---|---|
| Q41 | a família já existe no Banco e possui figura simbólica revisada (`LO26_Panosso18_receptor_simbolica.png`) |

### E. Figura original recortada especificamente para o item

| Questão | Procedimento |
|---|---|
| Q49 | preservar a malha e os pontos P e Q da figura original; usar recorte monocromático sem redesenhar a geometria |

## Nomes propostos para imagens-base

As imagens extraídas da fonte devem ficar em `BancoDeQuestoes/figuras/` com nomes:

- `PM007_Q01_base.png`
- `PM007_Q03_base.png`
- `PM007_Q06_base.png`
- `PM007_Q08_base.png`
- `PM007_Q09_base.png`
- `PM007_Q10_base.png`
- `PM007_Q11_base.jpg` (somente referência visual; a versão usada será gerada por código)
- `PM007_Q12_base.png`
- `PM007_Q13_base.png`
- `PM007_Q19_base.jpg`
- `PM007_Q25_base.png`
- `PM007_Q27_base.png`
- `PM007_Q28_base.png`
- `PM007_Q35_base.png`
- `PM007_Q38_base.png`
- `PM007_Q43_base.jpg`
- `PM007_Q46_base.png`
- `PM007_Q49_base.b64`

Q41 reutiliza o ativo já existente.

## Próxima etapa

1. validar no CI todas as questões da frente;
2. revisar visualmente as variantes com figuras;
3. auditar consistência física, gabaritos e tolerâncias;
4. separar o que pertence ao acervo geral do que deve entrar nas três provas substitutivas.


## Estado da implementação

Questões já implementadas nesta frente:

| Questão | Figura | Parametrização |
|---|---|---|
| Q03 | original + sobreposição do rótulo de altura | altura e velocidade horizontal |
| Q06 | original preservada + versão simbólica h/d | altura, alcance, velocidade inicial e velocidade de impacto |
| Q08 | original preservada + versão simbólica h/d | altura, alcance e velocidade inicial |
| Q11 | gráficos gerados por código | velocidade horizontal e gravidade do planeta |
| Q12 | original + sobreposição do rótulo de altura | altura, velocidade horizontal, tempo e separação |
| Q19 | esquema gerado por código | velocidade do míssil, alturas e instante de encontro |
| Q38 | original preservada + versão simbólica theta/h | ângulo, velocidade, altura do alvo, distância e altura máxima |
| Q43 | original + substituição local de 2,5 m por h | altura inicial, velocidade, ângulo e alcance |

### Armazenamento dos recortes

Alguns recortes são mantidos em `.b64` dentro de `BancoDeQuestoes/figuras/` e
reconstruídos como PNG temporário no bloco R da questão com
`base64enc::base64decode()`. Esse padrão já existe no BancoFisica e permite
preservar exatamente os pixels do recorte-fonte mesmo quando o arquivo precisa
ser transportado como texto.

Os arquivos com sufixo `_base.b64` representam o recorte-fonte; os arquivos
`_symbolic.b64` representam uma derivação manual mínima, em que apenas os
rótulos numéricos foram substituídos por símbolos.

### Observação sobre as figuras diretas

Q01, Q09, Q10, Q13, Q25, Q27, Q28, Q35 e Q46 usam recortes originais sem
alteração de conteúdo. A Q49 usa um recorte monocromático da própria figura
original, preservando coordenadas, malha, curva e pontos P e Q.


## Lote atual — 45 questões implementadas

A frente já contém 45 arquivos `.Rnw`.

Cobertura principal:

- lançamento horizontal e independência dos movimentos: Q01, Q03, Q04, Q05, Q06, Q07, Q08, Q09, Q10, Q12, Q13, Q25, Q30 e Q31;
- referenciais e composição de velocidades: Q02 e Q34;
- lançamento oblíquo / problemas inversos: Q15, Q16, Q21, Q22, Q23, Q24, Q27, Q36, Q37, Q38, Q39, Q40, Q42, Q43, Q44, Q45, Q46 e Q48;
- aplicações diferenciadas: Q18 (vazão), Q19 (interceptação) e Q35 (comparação gráfica de tempos);
- força, velocidade e energia: Q28;
- conceitos em formato somatório: Q17 e Q48;
- cinemática vetorial e tópicos avançados: Q14 e Q26 (raio de curvatura), Q20 (aceleração horizontal ativa), Q49 (velocidade média vetorial) e Q50 (aceleração horizontal dependente do tempo);
- leitura de gráficos: Q11 e Q49.

Os números preservam a numeração da lista-fonte. As únicas questões não
incorporadas nesta frente são:

- Q29: família já representada no Banco;
- Q32, Q33 e Q47: duplicatas internas da própria lista-fonte;
- Q41: família já implementada no Banco com figura revisada.

### Correções e adaptações documentadas

- Q20: o gabarito-fonte informa 354,3 m no item (b), mas as equações com os
  dados impressos fornecem aproximadamente 354,9 m; o Banco usa o valor
  recalculado.
- Q22: a fonte fornece a velocidade e a inclinação do plano, mas não explicita
  o valor de `g`; foi adotado `g=10 m/s2`, registrado no arquivo.
- Q26: a fonte não explicita `g`; foi adotado `g=9,8 m/s2`, que reproduz o
  gabarito de aproximadamente 305 m.
- Q50: o gabarito-fonte registra `0,4 s` para a queda de 80 m, mas com
  `g=10 m/s2` o valor correto é `4,0 s`; a implementação corrige o erro
  tipográfico e mantém os demais resultados compatíveis (`51,2 m/s` e
  `42,7 m`).


## Revisão visual manual das figuras — 08/10/2026

Após inspeção questão a questão, foram substituídas pelas artes revistas e
aprovadas manualmente as figuras de Q06, Q08, Q09, Q10, Q12, Q13, Q19, Q25,
Q27, Q28, Q35, Q38, Q43, Q46 e Q49. As novas artes são mantidas como PNGs
independentes com sufixo `_revisada`.

Permaneceram sem alteração nesta rodada:

- Q01: figura já aprovada;
- Q03: o valor mostrado na figura é gerado a partir da própria parametrização;
- Q11: gráficos gerados por código já aprovados.

Critério consolidado: quando a figura é simbólica, os valores numéricos ficam
no enunciado e os símbolos da figura devem representar exatamente as mesmas
grandezas e os mesmos intervalos geométricos. Quando a figura é gerada por
código, enunciado, figura e solução devem compartilhar as mesmas variáveis.

A Q46 passou a usar a letra `D` também no enunciado e na solução, de modo a
coincidir com a arte revisada. A Q28 mantém no Banco a soma fisicamente
consistente 4 e registra a divergência com o gabarito da lista-fonte.
