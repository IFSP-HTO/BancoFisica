# Expansão de lançamentos — PDF 007

Fonte de trabalho: `007_fisica_lancamento_horizontal_obliquo.pdf` (Projeto Medicina / Futuro Militar).

Este diretório documenta a triagem das questões e, em particular, a política de tratamento das figuras antes da incorporação dos novos itens ao BancoFisica.

## Princípio para as figuras

1. Preservar a figura original sempre que possível.
2. Extrair o objeto de imagem embutido no PDF, em vez de usar captura de tela da página.
3. Quando números estiverem gravados na figura, manter uma imagem-base original e substituir somente as pequenas regiões numéricas em tempo de geração, seguindo o padrão já usado nas listas de lançamento oblíquo de 2026 (`render_overlay_png()` com `png` + `grid`).
4. Não alterar permanentemente a imagem-base. Cada variante gera uma imagem derivada temporária.
5. Redesenhar por código somente quando a geometria/gráfico em si precisar variar, e não apenas os rótulos.

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

A preferência é escrever na figura os **valores efetivamente sorteados**, e não apenas trocar os números por letras. Assim, figura e enunciado permanecem autocontidos em cada variante.

### C. Figura gerada por código

| Questão | Motivo |
|---|---|
| Q11 | os próprios gráficos x(t) e y(x) definem os dados; variar somente os rótulos não é suficiente |

Para Q11, a figura deverá ser gerada a partir dos mesmos parâmetros usados na solução, mantendo o estilo simples de eixos e grade da fonte.

### D. Reaproveitamento / não criar nova figura

| Questão | Decisão |
|---|---|
| Q41 | a família já existe no Banco e possui figura simbólica revisada (`LO26_Panosso18_receptor_simbolica.png`) |
| Q49 | não é central para lançamento oblíquo; manter fora desta expansão por enquanto |

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

Q41 reutiliza o ativo já existente e Q49 não entra nesta frente.

## Próxima etapa

1. adicionar as imagens-base originais ao repositório;
2. implementar primeiro as questões com figura direta;
3. implementar o helper de overlay nas questões do grupo B;
4. gerar e validar visualmente várias variantes de cada figura parametrizada;
5. só então fechar a seleção dos itens para as três provas substitutivas.
