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

## Verifica a compilação para XML
generate_xml <- function() {
  
  ## Pega todos os arquivos de questões
  arquivos <- data.frame(file = dir(pattern = '*.Rnw',recursive = T))
  arquivos$status <- rep('', nrow(arquivos))
  
  ## Envelopando a função exams2moodle
  exams2moodle <- possibly(.f = exams2moodle, otherwise = NA)
  
  ## Ano corrente
  ano = 2018
  
  ## Para cada arquivo descobre o encoding
  for (i in 1:nrow(arquivos)) {
    
    ## Rodando a função em cada arquivo
    arquivos$status[i] <- exams2moodle(as.character(arquivos$file[i]), n = 1, rule="none", schoice = list(shuffle = TRUE), name = paste0("exemplos-",ano),
                 encoding = "UTF-8",
                 dir = tempdir(),
                 edir = tempdir())
  }
  
  ## Encontrando as linhas com erros
  ind_xml <- which(is.na(arquivos$status))
  
  ## Erro reportado
  erro <- paste("NÃO COMPILA PARA XML:", arquivos$file[ind_xml], '\n')
  
  ## Testando a compilação
  if (length(ind_xml) > 0 ) stop(erro)
}

## Verifica a compilação para pdf
generate_pdf <- function() {
  
  ## Pega todos os arquivos de questões
  arquivos <- data.frame(file = dir(pattern = '*.Rnw',recursive = T))
  arquivos$status <- rep('', nrow(arquivos))
  
  ## Envelopando a função exams2moodle
  exams2pdf <- possibly(.f = exams2pdf, otherwise = NA)
  
  ## Ano
  ano <- 2018
  
  ## Para cada arquivo roda a compilação para pdf
  for (i in 1:nrow(arquivos)) {
    
    ## Rodando a função em cada arquivo
    arquivos$status[i] <- exams2pdf(as.character(arquivos$file[i]), n = 1, rule="none", schoice = list(shuffle = TRUE), name = paste0("exemplos-",ano),
                                       encoding = "UTF-8",
                                       dir = tempdir(),
                                       edir = tempdir())
  }
  
  ## Encontrando as linhas com erros
  ind_pdf <- which(is.na(arquivos$status))
  
  ## Erro reportado
  erro <- paste("NÃO COMPILA PARA PDF:", arquivos$file[ind_pdf], '\n')
  
  ## Testando a compilação
  if (length(ind_pdf) > 0 ) stop(erro)
}

## Rodando as funções de teste
check_encoding()
generate_xml()
generate_pdf()
