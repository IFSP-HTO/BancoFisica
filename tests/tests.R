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
## O set.seed deixa a execução reprodutível. Retorna uma lista diagnóstica.
compilar_isolado <- function(arquivo, diretorio, formato, ano, seed) {
  tryCatch({
    callr::r(
      function(arquivo, diretorio, formato, ano, seed) {
        ## Mesmos pacotes da sessão principal: alguns chunks .Rnw usam
        ## funções de stringr/magrittr/purrr (ex.: str_split, %>%).
        suppressMessages({
          library(magrittr); library(stringr); library(exams); library(purrr)
        })

        count_matches <- function(text, pattern) {
          hits <- gregexpr(pattern, text, perl = TRUE)[[1]]
          if (identical(hits, -1L)) return(0L)
          length(hits)
        }

        # Detecta "sem correspondência" num resultado de gregexpr/gregexpr.
        # gregexpr retorna um int -1 COM atributos (match.length etc.), e
        # identical(x, -1L) é FALSE nesse caso (compara atributos). A forma
        # segura é testar length == 1 && o valor == -1.
        no_match <- function(hits) length(hits) == 1L && !is.na(hits) && as.integer(hits) == -1L

        validate_moodle_xml <- function(xml_file) {
          if (!file.exists(xml_file)) {
            stop("Moodle XML file not found: ", xml_file)
          }

          xml_text <- paste(readLines(xml_file, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
          xml_bytes <- file.info(xml_file)$size

          # Limite de upload do Moodle institucional: ~10 MB por arquivo.
          max_upload <- 10 * 1024 * 1024
          if (xml_bytes > max_upload) {
            stop("Moodle XML exceeds the 10 MB upload limit in ", basename(xml_file))
          }

          if (!grepl("<quiz[[:space:]>]", xml_text, perl = TRUE)) {
            stop("Moodle XML missing <quiz> root in ", basename(xml_file))
          }
          if (!grepl("</quiz>", xml_text, fixed = TRUE)) {
            stop("Moodle XML missing </quiz> closing tag in ", basename(xml_file))
          }
          if (grepl("<parsererror", xml_text, fixed = TRUE)) {
            stop("Moodle XML contains parsererror marker in ", basename(xml_file))
          }

          # Imagens com src quebrado: o padrão %7B...%7D é a codificação URL de
          # chaves literais {arquivo}. Isso acontece quando o .Rnw usa
          # \includegraphics{{arquivo}} (chave dupla): o pandoc mantém as chaves
          # no caminho e o exams2moodle percent-encodea, gerando
          # src="%7Barquivo%7D" em vez de src="@@PLUGINFILE@@/arquivo". A imagem
          # então não é exibida no Moodle. Este teste falha se qualquer <img>
          # referenciar %7B ou se um arquivo embutido não tiver seu pluginfile.
          broken_src <- gregexpr("src=\"%7B[^\"]*%7D\"", xml_text, perl = TRUE)[[1]]
          if (!no_match(broken_src)) {
            stop("Moodle XML has broken image src (percent-encoded braces %7B...%7D) in ",
                 basename(xml_file))
          }
          # Qualquer src de imagem que não aponte para @@PLUGINFILE@@ e não seja
          # um data-URI base64 nem um URL absoluto indica arquivo não anexado.
          img_srcs <- regmatches(
            xml_text,
            gregexpr("src=\"[^\"]*\\.(png|jpe?g|gif|svg)\"", xml_text,
                     ignore.case = TRUE, perl = TRUE)
          )[[1]]
          bad_imgs <- img_srcs[
            !grepl("src=\"@@PLUGINFILE@@/", img_srcs, fixed = TRUE) &
              !grepl("src=\"data:", img_srcs, fixed = TRUE) &
              !grepl("src=\"https?://", img_srcs, perl = TRUE)
          ]
          if (length(bad_imgs) > 0) {
            stop("Moodle XML has image src not resolved to @@PLUGINFILE@@ in ",
                 basename(xml_file), ": ",
                 paste(utils::head(bad_imgs, 5), collapse = " | "))
          }

          question_tags <- regmatches(
            xml_text,
            gregexpr("<question[[:space:]]+type=\"[^\"]+\"", xml_text, perl = TRUE)
          )[[1]]
          if (length(question_tags) == 1L && identical(question_tags, -1L)) {
            question_tags <- character()
          }
          n_questions <- sum(!grepl("type=\"category\"", question_tags, fixed = TRUE))
          if (n_questions < 1L) {
            stop("Moodle XML has no exported question item in ", basename(xml_file))
          }

          list(
            xml_file = basename(xml_file),
            xml_bytes = xml_bytes,
            xml_questions = n_questions,
            quiz_tags = count_matches(xml_text, "<quiz[[:space:]>]"),
            raw_question_tags = length(question_tags)
          )
        }

        set.seed(seed)
        if (formato == "xml") {
          xml_before <- list.files(tempdir(), pattern = "\\.xml$", full.names = TRUE)
          exams2moodle(arquivo, n = 1, rule = "none",
                       schoice = list(shuffle = TRUE),
                       name = paste0("exemplos-", ano),
                       encoding = "UTF-8", dir = tempdir(), edir = diretorio)
          xml_after <- list.files(tempdir(), pattern = "\\.xml$", full.names = TRUE)
          xml_new <- setdiff(xml_after, xml_before)
          if (length(xml_new) == 0L) {
            xml_new <- xml_after
          }
          if (length(xml_new) == 0L) {
            stop("exams2moodle did not generate an XML file")
          }

          xml_new <- xml_new[order(file.info(xml_new)$mtime, decreasing = TRUE)]
          xml_info <- validate_moodle_xml(xml_new[1])
          return(c(list(ok = TRUE, message = ""), xml_info))
        }

        exams2pdf(arquivo, n = 1,
                  name = paste0("exemplos-", ano),
                  encoding = "UTF-8", dir = tempdir(), edir = diretorio,
                  template = "plain8")
        list(ok = TRUE, message = "", xml_file = NA_character_,
             xml_bytes = NA_real_, xml_questions = NA_integer_,
             quiz_tags = NA_integer_, raw_question_tags = NA_integer_)
      },
      args = list(arquivo = arquivo, diretorio = diretorio,
                  formato = formato, ano = ano, seed = seed)
    )
  }, error = function(e) {
    list(ok = FALSE, message = conditionMessage(e), xml_file = NA_character_,
         xml_bytes = NA_real_, xml_questions = NA_integer_,
         quiz_tags = NA_integer_, raw_question_tags = NA_integer_)
  })
}

## Valida a geração do gráfico sem exigir artefatos versionados no PR.
check_question_counts <- function() {
  if (file.exists("tools/question_counts.R")) {
    status <- system2(
      "Rscript",
      c("tools/question_counts.R", "--check", "--out-dir", "build/question-counts")
    )
    if (!identical(status, 0L)) stop("Question count generator failed")
  }
}

## Exercita o particionamento de XML por limite de upload.
##
## Usa um assunto real com figuras (trabalhopotencia) e um limite abaixo do
## tamanho total: o gerador deve produzir >= 2 partes, todas dentro do limite
## (tools/moodle_xml_split.R). Roda em subprocesso (callr) para nao acumular
## estado do exams2moodle na sessao de teste.
check_moodle_split <- function() {
  report <- callr::r(function() {
    source("tools/moodle_xml_split.R")
    suppressMessages({
      library(exams)
      library(magrittr)
      library(stringr)
      library(purrr)
    })
    edir <- "BancoDeQuestoes/trabalhopotencia"
    files <- sort(list.files(edir, pattern = "\\.[Rr]nw$", ignore.case = TRUE))
    out <- tempfile("moodle_split_")
    dir.create(out)
    limit <- floor(1.5 * 1024 * 1024)  # 1.5 MB force a divisao em partes
    parts <- generate_moodle_xml_limited(
      files = files, n = 12L, name = "split-test", seed = 12026,
      edir = edir, dir = out, max_bytes = limit
    )
    sizes <- file.size(parts)
    list(n_parts = length(parts), max = max(sizes), limit = limit)
  })

  if (!isTRUE(report$n_parts >= 2L)) {
    stop("Moodle XML split check did not produce at least 2 parts")
  }
  if (!isTRUE(report$max <= report$limit)) {
    stop("Moodle XML split check produced a part over the limit")
  }
  cat(sprintf("Moodle XML split check: %d part(s), max %.2f MB (limit %.2f MB)\n",
              report$n_parts, report$max / 1024^2, report$limit / 1024^2))
}

## Valida a estrutura mínima das questões antes das compilações pesadas.
check_bank_structure <- function() {
  if (file.exists("tools/validate_bank.R")) {
    status <- system2(
      "Rscript",
      c("tools/validate_bank.R", "--questions-dir", "BancoDeQuestoes")
    )
    if (!identical(status, 0L)) stop("Bank structural validation failed")
  }
}

## Lê a lista de sementes usada nos testes XML.
##
## Por padrão usa 1,2,3. Pode ser sobrescrita com, por exemplo:
## BANK_SEEDS=1,2,3,4,5 Rscript -e 'source("tests/tests.R")'
parse_seed_list <- function(env_var = "BANK_SEEDS", default = c(1L, 2L, 3L)) {
  raw <- Sys.getenv(env_var, unset = "")
  if (!nzchar(raw)) return(default)

  parts <- trimws(unlist(strsplit(raw, ",", fixed = TRUE)))
  parts <- parts[nzchar(parts)]
  seeds <- suppressWarnings(as.integer(parts))

  if (length(seeds) == 0L || anyNA(seeds)) {
    stop("Invalid ", env_var, ": use comma-separated integers, e.g. 1,2,3")
  }

  unique(seeds)
}

## Verifica a compilação para XML
##
## Além de checar se o exams2moodle roda, valida o artefato gerado:
## precisa existir, conter raiz <quiz>...</quiz> e ao menos uma questão Moodle.
## Para questões parametrizadas, testa múltiplas sementes configuráveis via BANK_SEEDS.
generate_xml <- function() {

  ## Pega todos os arquivos de questões
  arquivos <- data.frame(file = dir(pattern = '*.Rnw', recursive = T),
                         stringsAsFactors = FALSE)

  ## Ano corrente
  ano <- 2018

  xml_seeds <- parse_seed_list()
  message("Validating Moodle XML with seeds: ", paste(xml_seeds, collapse = ", "))

  ## Para cada arquivo e cada semente, compila para XML numa sessão isolada
  plano <- expand.grid(
    file_index = seq_len(nrow(arquivos)),
    seed = xml_seeds,
    KEEP.OUT.ATTRS = FALSE
  )

  resultados <- vector("list", nrow(plano))
  for (j in seq_len(nrow(plano))) {
    i <- plano$file_index[j]
    arquivo   <- normalizePath(arquivos$file[i])
    diretorio <- dirname(arquivo)
    resultados[[j]] <- compilar_isolado(arquivo, diretorio, "xml", ano, seed = plano$seed[j])
  }

  xml_report <- do.call(rbind, lapply(seq_along(resultados), function(j) {
    i <- plano$file_index[j]
    res <- resultados[[j]]
    data.frame(
      file = arquivos$file[i],
      seed = plano$seed[j],
      ok = isTRUE(res$ok),
      message = as.character(res$message),
      xml_file = as.character(res$xml_file),
      xml_bytes = as.numeric(res$xml_bytes),
      xml_questions = as.integer(res$xml_questions),
      quiz_tags = as.integer(res$quiz_tags),
      raw_question_tags = as.integer(res$raw_question_tags),
      stringsAsFactors = FALSE
    )
  }))

  if (!dir.exists("build/moodle-xml")) {
    dir.create("build/moodle-xml", recursive = TRUE)
  }
  write.csv(xml_report, "build/moodle-xml/xml-validation.csv",
            row.names = FALSE, fileEncoding = "UTF-8")

  ## Encontrando as linhas com erros
  ind_xml <- which(!xml_report$ok)

  ## Erro reportado
  erro <- paste("NÃO COMPILA OU NÃO VALIDA PARA XML:",
                xml_report$file[ind_xml],
                "seed", xml_report$seed[ind_xml],
                xml_report$message[ind_xml], '\n')

  ## Testando a compilação e validação
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
    ok[i] <- isTRUE(compilar_isolado(arquivo, diretorio, "pdf", ano, seed = i)$ok)
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
check_bank_structure()
check_question_counts()
check_moodle_split()
generate_xml()
generate_pdf()
