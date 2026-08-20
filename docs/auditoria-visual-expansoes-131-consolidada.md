# Auditoria visual consolidada das expansões recentes

Refs #131.

## Objetivo

Consolidar a auditoria de procedência e necessidade visual das **103 questões autorais** adicionadas nos lotes recentes de Mecânica, Física Moderna, Eletromagnetismo, Gravitação/Astronomia e Óptica geométrica.

A auditoria corrige a premissa da triagem preliminar de 55 casos: esses lotes foram documentados desde a criação como **questões autorais**, usando *Compreendendo a Física*, de Alberto Gaspar, como referência pedagógica e de progressão de conteúdo, e não como adaptações 1:1 de exercícios específicos.

Por isso, não se deve inserir uma figura do livro apenas por semelhança temática. O critério é a correspondência efetiva entre a figura original e a questão atual, sem conflito de parâmetros e sem transformar a figura em resposta explícita do item.

## Resultado consolidado

| Lote | Questões | Usar original | Adaptar para original | Sem figura necessária | Manter procedural |
|---|---:|---:|---:|---:|---:|
| MUV, queda livre e Leis de Newton | 31 | 6 | 1 | 24 | 0 |
| Física Moderna | 18 | 3 | 0 | 15 | 0 |
| Eletromagnetismo | 24 | 15 | 0 | 9 | 0 |
| Gravitação/Astronomia | 15 | 2 | 0 | 13 | 0 |
| Óptica geométrica | 15 | 8 | 0 | 7 | 0 |
| **Total** | **103** | **34** | **1** | **68** | **0** |

Portanto, o passivo acionável deste conjunto é de **35 questões**: 34 em que uma figura original pode ser incorporada sem mudança estrutural e 1 em que a questão deve ser adaptada antes de receber a figura original. As outras 68 devem permanecer sem figura.

## Casos `usar original`

### Mecânica — 6

- `cinematica/MUV/Q94QuizGraficoVelocidadeMUV.Rnw` — Gaspar v.1, p. 79, gráfico genérico `v x t` com aceleração positiva;
- `cinematica/MUV/Q99ClozeAreaGraficoVelocidade.Rnw` — Gaspar v.1, p. 79, área sob gráfico `v x t`;
- `leisdenewton/forcas/Q98ClozeDoisBlocosContato.Rnw` — Gaspar v.1, p. 141, dois blocos em contato e força `F`;
- `leisdenewton/forcas/Q99ClozeBlocosCorda.Rnw` — Gaspar v.1, p. 137, dois blocos ligados por fio e força `F`;
- `leisdenewton/forcas/Q101ClozePlanoInclinadoSemAtrito.Rnw` — Gaspar v.1, p. 144, decomposição do peso em plano inclinado;
- `leisdenewton/atrito/Q97QuizCaminharAtrito.Rnw` — Gaspar v.1, p. 154, atrito estático como força motora ao caminhar.

### Física Moderna — 3

- `fisicamoderna/Q94QuizGraficoFotoeletrico.Rnw` — Gaspar v.3, p. 213, gráfico do efeito fotoelétrico;
- `fisicamoderna/Q103QuizRelatividadeSimultaneidade.Rnw` — Gaspar v.3, p. 233, sequência trem/plataforma;
- `fisicamoderna/Q106QuizFissaoFusaoCurvaLigacao.Rnw` — Gaspar v.3, p. 293, curva de energia de ligação por núcleon.

### Eletromagnetismo — 15

- `eletrostatica/Q96QuizLinhasCampo.Rnw` — Gaspar v.3, p. 39, linhas de campo elétrico;
- `eletrostatica/Q99ClozeCampoUniformeDDP.Rnw` — Gaspar v.3, p. 72, capacitor de placas paralelas;
- `magnetismo/Q01QuizPolosImas.Rnw` — Gaspar v.3, p. 152, corte de ímã e novos dipolos;
- `magnetismo/Q02QuizLinhasCampoIma.Rnw` — Gaspar v.3, p. 153, linhas de campo de ímã de barra;
- `magnetismo/Q03ClozeCampoFioRetilineo.Rnw` — Gaspar v.3, p. 169, campo ao redor de fio retilíneo;
- `magnetismo/Q04ClozeCampoEspira.Rnw` — Gaspar v.3, p. 176, espira circular;
- `magnetismo/Q05ClozeCampoSolenoide.Rnw` — Gaspar v.3, p. 175, solenoide;
- `magnetismo/Q06ClozeForcaCargaMagnetica.Rnw` — Gaspar v.3, pp. 155–156, geometria `v`, `B` e `F`;
- `magnetismo/Q08ClozeRaioTrajetoriaCarga.Rnw` — Gaspar v.3, p. 158, trajetória circular de carga;
- `magnetismo/Q09ClozeForcaFioCampo.Rnw` — Gaspar v.3, p. 160, força magnética em fio;
- `magnetismo/Q10QuizMotorEletrico.Rnw` — Gaspar v.3, p. 163, espira em campo magnético — efeito motor;
- `inducao/Q02QuizLeiLenzIma.Rnw` — Gaspar v.3, p. 185, ímã aproximando-se da espira;
- `inducao/Q04QuizGeradorEletromagnetico.Rnw` — Gaspar v.3, pp. 189–191, gerador;
- `inducao/Q05ClozeTransformadorIdeal.Rnw` — Gaspar v.3, p. 193, transformador ideal;
- `inducao/Q06QuizTransformadorCorrenteContinua.Rnw` — Gaspar v.3, pp. 192–193, indução apenas durante variação de corrente/fluxo.

### Gravitação/Astronomia — 2

- `gravitacao/Q03QuizSegundaLeiVelocidade.Rnw` — Gaspar v.1, p. 243, áreas iguais em órbita elíptica;
- `gravitacao/Q05NumCampoGravitacionalAltura.Rnw` — Gaspar v.1, p. 249, distância ao centro `R+h`.

`Q09QuizSateliteGeoestacionario.Rnw` foi retirado da lista acionável após a inspeção visual do recorte da p. 161: a fonte mostra apenas um satélite em órbita circular como exemplo de MCU, não as condições específicas de uma órbita geoestacionária.

### Óptica — 8

- `optica/Q98QuizRetrovisorConvexo.Rnw` — Gaspar v.2, p. 91, espelho convexo e campo de visão;
- `optica/Q102NumAnguloLimite.Rnw` — Gaspar v.2, p. 112, ângulo limite/reflexão total;
- `optica/Q103QuizFibraOptica.Rnw` — Gaspar v.2, p. 127, raio no núcleo de fibra óptica;
- `optica/Q104QuizPrismaDispersao.Rnw` — Gaspar v.2, p. 118, dispersão da luz branca em prisma;
- `optica/Q108ClozeMiopiaCorrecao.Rnw` — Gaspar v.2, p. 150, miopia e correção com lente divergente;
- `optica/Q109ClozeHipermetropiaCorrecao.Rnw` — Gaspar v.2, p. 151, hipermetropia e correção com lente convergente;
- `optica/Q110QuizCameraFotografica.Rnw` — Gaspar v.2, p. 164, esquema de câmera fotográfica;
- `optica/Q111QuizLupa.Rnw` — Gaspar v.2, p. 155, lupa/microscópio simples.

## Caso `adaptar para original`

- `leisdenewton/atrito/Q96ClozePlanoInclinadoComAtrito.Rnw` — Gaspar v.1, pp. 151–152. O original usa plano inclinado a 37°, enquanto a questão atual sorteia 37° ou 53°. Para usar a figura sem incoerência, a questão precisa restringir a geometria visual a 37° (ou ser desdobrada em variantes compatíveis), preservando a randomização do coeficiente de atrito.

## Casos excluídos de propósito

Vários itens têm figuras relacionadas no livro, mas elas não devem ser incorporadas porque entregariam a resposta (por exemplo, lente divergente e imagem real em anteparo), porque trazem valores/casos fixos incompatíveis com a parametrização (transições de Bohr, alguns gráficos e problemas de lentes) ou porque seriam apenas decorativas.

## Próxima etapa

Antes de alterar qualquer `.Rnw`, os **35 casos acionáveis** devem passar por revisão visual usando recortes exatos das páginas/fontes indicadas. Depois da aprovação, as figuras devem ser obtidas pelo pipeline determinístico descrito em `docs/PDF_SOURCE_WORKFLOW.md` / `tools/pdf_assets.py`, registrando a procedência e validando PDF + Moodle XML.

A auditoria de Oscilações/Ondas permanece separada em #140, pois nesse lote já existem figuras procedurais a serem comparadas diretamente com as figuras originais da fonte.
