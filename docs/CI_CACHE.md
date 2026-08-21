# Cache de compilação do CI

O BancoFisica usa um cache **endereçado por conteúdo** apenas para reutilizar o
resultado de compilações/validações que já terminaram com sucesso. O cache não
armazena os PDFs/XML grandes como artefatos permanentes; ele armazena pequenos
marcadores RDS contendo o resultado diagnóstico de uma tarefa já validada.

## Regra de segurança

Um `hit` significa somente:

> esta mesma tarefa, com os mesmos insumos lógicos e no mesmo ambiente de CI,
> já compilou e validou com sucesso.

Entradas ausentes, corrompidas ou incompatíveis são tratadas como `miss` e a
compilação é executada normalmente. Resultados com falha nunca são gravados.

## Fingerprint v1

A chave base de cada questão é SHA-256 sobre:

1. versão do esquema (`bancofisica-compile-cache-v1`);
2. fingerprint exato do ambiente de execução;
3. conteúdo do `.Rnw` e seu caminho relativo;
4. arquivos globais que podem afetar compilação/validação:
   - `DESCRIPTION`, `NAMESPACE`, `docker/ci/Dockerfile`;
   - `tests/tests.R`, `tests/run_tests_parallel.R`;
   - `tools/ci_compile_cache.py`;
   - `.github/workflows/r-tests.yml`;
   - conteúdo de `templates/` e `R/`;
   - arquivos `.sty`, `.cls` e `.tex` na raiz;
5. todos os arquivos de suporte não-`.Rnw` sob `BancoDeQuestoes/`.

O item 5 é propositalmente conservador: em vez de tentar adivinhar apenas os
assets efetivamente usados por cada questão, a versão v1 usa um superset seguro.
Isso pode produzir `misses` extras quando uma figura não relacionada muda, mas
não permite um `hit` falso por omissão de dependência visual/auxiliar.

A chave de tarefa acrescenta à chave base:

- formato (`xml` ou `pdf`);
- seed efetivamente usada pela tarefa.

Assim, XML seed 1, XML seed 2 e PDF são entradas independentes.

## Ambiente

No GitHub Actions, `BANK_CACHE_ENV_FINGERPRINT` recebe o **ID exato da imagem
Docker** obtido por `docker image inspect`. Uma imagem diferente invalida as
entradas mesmo que a tag legível permaneça igual.

Fora do CI, quando esse valor não é fornecido, o runner deriva um fingerprint
local a partir das versões de R, pacotes de compilação e ferramentas principais.

## Modos

- `BANK_COMPILE_CACHE=1`: habilita leitura e escrita;
- `BANK_COMPILE_CACHE=0`: ignora o cache;
- `BANK_CACHE_DIR`: muda o diretório (padrão `.cache/bancofisica-ci`);
- `BANK_CACHE_CLEAR=1`: limpa o diretório antes da execução.

O cache local é opt-in; o comportamento histórico permanece disponível com
`BANK_COMPILE_CACHE=0`.

No GitHub Actions:

- PRs/pushes usam cache;
- `schedule` e `workflow_dispatch` executam o full **sem cache**, servindo como
  referência periódica de integridade;
- `actions/cache/restore` recupera marcadores de execuções anteriores;
- `actions/cache/save` salva apenas após a bateria de compilação terminar verde.

## Diagnóstico

Cada execução grava `build/compile-cache/summary.csv` com:

- `hits`;
- `misses`;
- `executed`;
- `writes`;
- `bypassed`;
- ambiente e motivo de habilitação/desabilitação.

O workflow também publica esses números no `GITHUB_STEP_SUMMARY`.

## Benchmark

`.github/workflows/ci-benchmark-cache.yml` executa as mesmas 20 questões duas
vezes:

1. `cold-cache`: cache vazio, 80 tarefas esperadas (60 XML + 20 PDF), todas miss;
2. `warm-cache`: restaura via GitHub Actions o cache salvo pelo job anterior e
   exige 80 hits, 0 misses e 0 compilações.

Esse benchmark verifica simultaneamente a semântica do cache, a persistência
entre jobs e o ganho real de wall time.
