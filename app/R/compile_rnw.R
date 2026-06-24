## compile_rnw.R
## Compila um único arquivo .Rnw para Moodle XML numa sessão R limpa (callr),
## reproduzindo exatamente o fluxo de Moodle/ExerciciosParaMoodle.R e o
## isolamento usado em tests/tests.R. Retorna o caminho do .xml gerado.

compilar_rnw <- function(arquivo, n = 1, seed = 1) {
  arquivo   <- normalizePath(arquivo, mustWork = TRUE)
  diretorio <- dirname(arquivo)
  destino   <- tempfile(pattern = "preview-", fileext = "")
  dir.create(destino)

  callr::r(
    function(arquivo, diretorio, destino, n, seed) {
      suppressMessages({
        library(magrittr); library(stringr); library(exams); library(purrr)
      })
      set.seed(seed)
      ## Passa o basename + edir (como em Moodle/ExerciciosParaMoodle.R) para que
      ## o \exname seja respeitado. converter = "pandoc-mathjax" garante math em
      ## \(...\) e imagens base64, idêntico ao XML de produção.
      exams2moodle(
        basename(arquivo), n = n, rule = "none",
        schoice = list(shuffle = TRUE),
        converter = "pandoc-mathjax",
        name = "preview",
        encoding = "UTF-8",
        dir = destino, edir = diretorio
      )
      invisible(TRUE)
    },
    args = list(arquivo = arquivo, diretorio = diretorio,
                destino = destino, n = n, seed = seed)
  )

  xml <- list.files(destino, pattern = "\\.xml$", full.names = TRUE)
  if (length(xml) == 0)
    stop("A compilação não gerou nenhum arquivo XML.")
  xml[1]
}

## Lista todos os .Rnw do banco, com rótulo legível (assunto/arquivo).
listar_rnw <- function(raiz = "BancoDeQuestoes") {
  arquivos <- list.files(raiz, pattern = "\\.Rnw$", recursive = TRUE,
                         full.names = TRUE)
  arquivos <- sort(normalizePath(arquivos))
  prefixo  <- paste0(normalizePath(raiz), .Platform$file.sep)
  rotulos  <- sub(prefixo, "", arquivos, fixed = TRUE)
  stats::setNames(arquivos, rotulos)
}
