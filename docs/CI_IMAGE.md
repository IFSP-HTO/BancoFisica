# Ambiente pré-construído do CI

O workflow `R tests` usa a imagem `ghcr.io/ifsp-hto/bancofisica-ci:r-4.4.3` para evitar reinstalar R, pacotes R e a toolchain LaTeX em toda execução.

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

`.github/workflows/ci-image.yml` reconstrói e publica a imagem quando muda um dos insumos do ambiente:

- `docker/ci/Dockerfile`;
- `DESCRIPTION`;
- o próprio workflow da imagem.

Também é possível executar o workflow manualmente com `workflow_dispatch`.

Mudanças em questões `.Rnw`, figuras, documentação ou scripts que não alteram o ambiente não reconstroem a imagem.

## Tags

A publicação cria duas tags no GHCR:

- `r-4.4.3`: tag estável consumida pelo workflow de testes;
- `sha-<commit>`: tag imutável associada ao commit que construiu o ambiente, útil para rastreabilidade e diagnóstico.

Ao atualizar a versão do R, altere em conjunto:

1. a imagem base em `docker/ci/Dockerfile`;
2. a validação da versão dentro do Dockerfile;
3. `IMAGE_TAG` em `.github/workflows/ci-image.yml`;
4. `BANK_CI_IMAGE` em `.github/workflows/r-tests.yml`.

## Execução dos testes

O runner continua responsável por checkout, cálculo do escopo incremental e validações Python leves. Quando há questões a processar, o workflow baixa a imagem pré-construída e executa dentro dela:

- testes do BancoFisica;
- auditoria dos blocos de solução;
- relatório de qualidade;
- auditoria pedagógica.

Assim, um PR pequeno deixa de pagar o custo fixo de `apt install`, configuração do R e instalação/restauração das dependências R antes de começar o trabalho útil.

## Diagnóstico

O passo `Verify prebuilt CI environment` falha cedo caso a imagem publicada não contenha a versão esperada do R, os pacotes R essenciais ou as ferramentas LaTeX/Pandoc esperadas.

Para testar uma imagem localmente:

```bash
docker build -f docker/ci/Dockerfile -t bancofisica-ci:test .
docker run --rm bancofisica-ci:test Rscript -e 'packageVersion("exams")'
docker run --rm bancofisica-ci:test latexmk -v
```
