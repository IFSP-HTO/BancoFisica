## Pacotes necessários
library(magrittr, quietly = T)
library(stringr, quietly = T)
library(exams, quietly = T)
library(purrr, quietly = T)

## Checa o encoding
check_encoding <- function() {
  
  ## Pega todos os arquivos de questões
  arquivos <- as.data.frame(dir(pattern = '*.Rnw',recursive = T))
  
  ## Para cada arquivo descobre o encoding
  for (i in 1:nrow(arquivos)) {
    comando <- paste('file -ib', arquivos[i,1])
    string <- system(comando, intern = T)
    encoding = str_split(string = string, pattern = ';', simplify = T)[2] %>% 
      str_split(pattern = '=', simplify = T)
    arquivos[i,2] <- encoding[2]
  }
  
  ## Atribuindo nomes corretos nas colunas
  colnames(arquivos) <- c('arquivo', 'encoding')
  
  ## Encontrando as linhas com erros
  ind_n_utf8 <- which(arquivos$encoding != 'utf-8' & arquivos$encoding != 'us-ascii')
  
  ## Erro reportado
  erro <- paste("NOT UTF-8:", arquivos$arquivo[ind_n_utf8], '\n')
  
  ## Testando o encoding
  if (length(ind_n_utf8) > 0 ) stop(erro)
}

## Compila UM arquivo numa sessão R limpa via callr.
##
## O exams2moodle/exams2pdf altera o diretório de trabalho e acumula estado
## ao longo de uma sessão; rodando 200+ compilações no mesmo processo isso
## corrompe o tempdir/cwd e gera falhas intermitentes ("argumento 'path'
## inválido"). Isolar cada compilação num subprocesso elimina esse acúmulo.
## O set.seed deixa a execução reprodutível. Retorna TRUE/FALSE.
compilar_isolado <- function(arquivo, diretorio, formato, ano, seed) {
  tryCatch({
    callr::r(
      function(arquivo, diretorio, formato, ano, seed) {
        ## Mesmos pacotes da sessão principal: alguns chunks .Rnw usam
        ## funções de stringr/magrittr/purrr (ex.: str_split, %>%).
        suppressMessages({
          library(magrittr); library(stringr); library(exams); library(purrr)
        })
        set.seed(seed)
        if (formato == "xml") {
          exams2moodle(arquivo, n = 1, rule = "none",
                       schoice = list(shuffle = TRUE),
                       name = paste0("exemplos-", ano),
                       encoding = "UTF-8", dir = tempdir(), edir = diretorio)
        } else {
          exams2pdf(arquivo, n = 1,
                    name = paste0("exemplos-", ano),
                    encoding = "UTF-8", dir = tempdir(), edir = diretorio,
                    template = "plain8")
        }
        invisible(TRUE)
      },
      args = list(arquivo = arquivo, diretorio = diretorio,
                  formato = formato, ano = ano, seed = seed)
    )
    TRUE
  }, error = function(e) FALSE)
}

## Verifica a geração do gráfico sem exigir artefatos versionados no PR.
check_question_counts <- function() {
  if (file.exists("tools/question_counts.R")) {
    status <- system2(
      "Rscript",
      c("tools/question_counts.R", "--check", "--out-dir", "build/question-counts")
    )
    if (!identical(status, 0L)) stop("Question count generator failed")
  }
}

## Verifica a compilação para XML
generate_xml <- function() {

  ## Pega todos os arquivos de questões
  arquivos <- data.frame(file = dir(pattern = '*.Rnw', recursive = T),
                         stringsAsFactors = FALSE)

  ## Ano corrente
  ano <- 2018

  ## Para cada arquivo, compila para XML numa sessão isolada
  ok <- logical(nrow(arquivos))
  for (i in seq_len(nrow(arquivos))) {
    arquivo   <- normalizePath(arquivos$file[i])
    diretorio <- dirname(arquivo)
    ok[i] <- compilar_isolado(arquivo, diretorio, "xml", ano, seed = i)
  }

  ## Encontrando as linhas com erros
  ind_xml <- which(!ok)

  ## Erro reportado
  erro <- paste("NÃO COMPILA PARA XML:", arquivos$file[ind_xml], '\n')

  ## Testando a compilação
  if (length(ind_xml) > 0 ) stop(erro)
}

## Verifica a compilação para pdf
generate_pdf <- function() {

  ## Pega todos os arquivos de questões
  arquivos <- data.frame(file = dir(pattern = '*.Rnw', recursive = T),
                         stringsAsFactors = FALSE)

  ## Ano
  ano <- 2018

  ## Para cada arquivo, compila para PDF numa sessão isolada
  ok <- logical(nrow(arquivos))
  for (i in seq_len(nrow(arquivos))) {
    arquivo   <- normalizePath(arquivos$file[i])
    diretorio <- dirname(arquivo)
    ok[i] <- compilar_isolado(arquivo, diretorio, "pdf", ano, seed = i)
  }

  ## Encontrando as linhas com erros
  ind_pdf <- which(!ok)

  ## Erro reportado
  erro <- paste("NÃO COMPILA PARA PDF:", arquivos$file[ind_pdf], '\n')

  ## Testando a compilação
  if (length(ind_pdf) > 0 ) stop(erro)
}

## Rodando as funções
check_encoding()
check_question_counts()
generate_xml()
generate_pdf()
