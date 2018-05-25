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
  ind_n_utf8 <- which(arquivos$encoding != 'utf-8')
  
  ## Erro reportado
  erro <- paste("NOT UTF-8:", arquivos$arquivo[ind_n_utf8], '\n')
  
  ## Testando o encoding
  if (length(ind_n_utf8) > 0 ) stop(erro)
}
