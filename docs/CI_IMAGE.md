# Ambiente pré-construído do CI

O workflow `R tests` usa uma imagem pré-construída do GHCR para evitar reinstalar R, pacotes R e a toolchain LaTeX em toda execução.

## Conteúdo da imagem

A imagem é definida em `docker/ci/Dockerfile` e inclui:

- R 4.4.3;
- pacotes R declarados em `DESCRIPTION` (`Imports` e `Suggests`);
- TeX Live necessário às compilações do banco;
- `latexmk`;
- `qpdf`;
- `file`;
- Pandoc;
- Python 3 e ferramentas de sistema necessárias ao pipeline.

O próprio build valida a versão do R, a disponibilidade dos pacotes R principais e os executáveis essenciais antes de publicar a imagem.

## Quando a imagem é reconstruída

`.github/workflows/ci-image.yml` é acionado quando muda um dos insumos do ambiente:

- `docker/ci/Dockerfile`;
- `DESCRIPTION`;
- o próprio workflow da imagem.

Também é possível executar o workflow manualmente com `workflow_dispatch`.

Mudanças em questões `.Rnw`, figuras, documentação ou scripts que não alteram o ambiente não reconstroem a imagem.

## Imagem endereçada pelo conteúdo

O ambiente é identificado por um fingerprint SHA-256 calculado a partir de `docker/ci/Dockerfile` e `DESCRIPTION`. A tag usada pelos testes tem a forma:

```text
ghcr.io/ifsp-hto/bancofisica-ci:env-<fingerprint>
```

Isso garante que duas execuções com o mesmo ambiente lógico reutilizem a mesma imagem, independentemente da branch ou do commit. Se o Dockerfile ou as dependências R mudarem, o fingerprint muda automaticamente e a imagem anterior não pode ser usada por engano.

Em `master`, a mesma imagem também recebe o alias legível `r-4.4.3`. O workflow de testes, porém, usa a tag `env-<fingerprint>` para preservar a reprodutibilidade.

## Publicação e bootstrap

Em pushes que alteram os insumos da imagem, o workflow publica a tag `env-<fingerprint>` no GHCR. Em pull requests, o Dockerfile é construído para validação sem publicar uma nova imagem a partir do contexto do PR.

O `R tests` tenta baixar a imagem exata pelo fingerprint. Se ela ainda não estiver publicada — por exemplo, durante o primeiro bootstrap ou em uma contribuição sem permissão de publicação — o workflow constrói esse ambiente localmente uma única vez para validar a mudança. Esse fallback só é necessário quando a imagem correspondente ao conteúdo ainda não existe.

## Atualização da versão do R

Ao atualizar a versão do R, altere em conjunto:

1. a imagem base em `docker/ci/Dockerfile`;
2. a validação da versão dentro do Dockerfile;
3. `STABLE_TAG` em `.github/workflows/ci-image.yml`;
4. a validação de versão em `.github/workflows/r-tests.yml`.

O fingerprint será alterado automaticamente pela mudança no Dockerfile.

## Execução dos testes

O runner continua responsável por checkout, cálculo do escopo incremental e validações Python leves. Quando há questões a processar, o workflow prepara a imagem pré-construída e executa dentro dela:

- testes do BancoFisica;
- auditoria dos blocos de solução;
- relatório de qualidade;
- auditoria pedagógica.

Assim, um PR pequeno deixa de pagar o custo fixo de `apt install`, configuração do R e instalação/restauração das dependências R antes de começar o trabalho útil.

Mudanças no próprio Dockerfile, no `DESCRIPTION` ou nos workflows de ambiente são tratadas como alterações globais pelo detector de escopo e, portanto, exercitam a suíte completa.

Os pacotes de sistema do apt são escolhidos para cobrir os pré-requisitos de compilação das dependências R. Em particular, `libuv1-dev` é necessário para o pacote CRAN `fs` (usado via `sass`/`bslib`/`shiny`): sem ele, a configuração de `fs` falha com `uv.h: No such file or directory`.

## Diagnóstico

O passo `Verify prebuilt CI environment` falha cedo caso a imagem não contenha a versão esperada do R, os pacotes R essenciais ou as ferramentas LaTeX/Pandoc esperadas.

Para testar uma imagem localmente:

```bash
docker build -f docker/ci/Dockerfile -t bancofisica-ci:test .
docker run --rm bancofisica-ci:test Rscript -e 'packageVersion("exams")'
docker run --rm bancofisica-ci:test latexmk -v
```
