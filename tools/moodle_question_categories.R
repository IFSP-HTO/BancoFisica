## Reorganiza categorias do XML Moodle por questao-base.
##
## O exams2moodle usa \exsection para criar categorias pedagogicas e pode
## agrupar varias questoes-base na mesma categoria. Para os XMLs de Ondas,
## queremos uma estrutura operacional simples no banco de questoes do Moodle:
##
##   <assunto>/Q01
##   <assunto>/Q02
##   ...
##
## sem alterar os metadados \exsection nos arquivos .Rnw. Este pos-processador
## remove somente os blocos de categoria do XML exportado e insere um novo
## bloco sempre que muda o Q presente no nome da variante.
##
## O exams2moodle usa dois formatos de nome:
##   * n = 1:  "Q01 : Nome"
##   * n > 1:  "R001 Q1 : Nome"
## Ambos sao aceitos aqui para que a organizacao por Q seja independente do
## numero de replicas solicitado na exportacao.

moodle_question_category_label <- function(q, width = 2L) {
  width <- max(1L, as.integer(width))
  sprintf(paste0("Q%0", width, "d"), as.integer(q))
}

moodle_question_category_path <- function(category_root, q, width = 2L) {
  if (is.null(category_root) || length(category_root) != 1L || !nzchar(category_root)) {
    stop("category_root must be a non-empty string")
  }
  paste0("$course$/", category_root, "/",
         moodle_question_category_label(q, width = width))
}

moodle_category_block <- function(category_path) {
  c(
    "",
    "<question type=\"category\">",
    "<category>",
    paste0("<text>", category_path, "</text>"),
    "</category>",
    "</question>",
    ""
  )
}

## Extrai a identidade logica da variante a partir do <name> exportado pelo
## exams2moodle. Para n=1 nao existe R no nome; nesse caso r = NA_integer_.
parse_moodle_variant_identity <- function(text) {
  m_replica <- regmatches(
    text,
    regexec(
      "<text>[[:space:]]*R([0-9]+)[[:space:]]+Q0*([0-9]+)[[:space:]]*:",
      text, perl = TRUE
    )
  )[[1]]

  if (length(m_replica) > 0L) {
    return(list(
      r = as.integer(m_replica[2]),
      q = as.integer(m_replica[3])
    ))
  }

  m_single <- regmatches(
    text,
    regexec(
      "<text>[[:space:]]*Q0*([0-9]+)[[:space:]]*:",
      text, perl = TRUE
    )
  )[[1]]

  if (length(m_single) > 0L) {
    return(list(
      r = NA_integer_,
      q = as.integer(m_single[2])
    ))
  }

  NULL
}

## Remove os blocos <question type="category"> existentes. Como esses blocos
## nao contem outros elementos <question>, basta ignorar ate o </question>
## correspondente.
strip_moodle_category_blocks <- function(lines) {
  out <- character()
  skipping <- FALSE

  for (line in lines) {
    if (!skipping && grepl("^[[:space:]]*<question[[:space:]]+type=\"category\"",
                           line, perl = TRUE)) {
      skipping <- TRUE
      next
    }

    if (skipping) {
      if (grepl("^[[:space:]]*</question>[[:space:]]*$", line, perl = TRUE)) {
        skipping <- FALSE
      }
      next
    }

    out <- c(out, line)
  }

  if (skipping) stop("Malformed Moodle XML: unterminated category block")
  out
}

## Reescreve um XML ja gerado. Cada questao-base recebe categoria propria,
## independente do \exsection original. Replicas consecutivas do mesmo Q ficam
## juntas; se uma mesma Q for repartida em mais de um XML, cada parte recebe o
## bloco de categoria necessario para ser importada isoladamente.
rewrite_moodle_question_categories <- function(xml_file, category_root,
                                               width = 2L) {
  lines <- readLines(xml_file, warn = FALSE, encoding = "UTF-8")
  lines <- strip_moodle_category_blocks(lines)

  out <- character()
  i <- 1L
  last_q <- NA_integer_

  while (i <= length(lines)) {
    line <- lines[[i]]

    if (grepl("^[[:space:]]*<question[[:space:]]+type=\"[^\"]+\"",
              line, perl = TRUE)) {
      j <- i
      while (j <= length(lines) &&
             !grepl("^[[:space:]]*</question>[[:space:]]*$", lines[[j]], perl = TRUE)) {
        j <- j + 1L
      }
      if (j > length(lines)) {
        stop("Malformed Moodle XML: unterminated question block in ", xml_file)
      }

      block <- lines[i:j]
      identity <- parse_moodle_variant_identity(paste(block, collapse = "\n"))

      if (!is.null(identity)) {
        q <- identity$q
        if (is.na(last_q) || q != last_q) {
          out <- c(
            out,
            moodle_category_block(
              moodle_question_category_path(category_root, q, width = width)
            )
          )
          last_q <- q
        }
      }

      out <- c(out, block)
      i <- j + 1L
      next
    }

    out <- c(out, line)
    i <- i + 1L
  }

  writeLines(out, xml_file, useBytes = TRUE)
  invisible(xml_file)
}

## Valida a propriedade de organizacao esperada apos a reescrita: toda
## variante ("Qnn" para n=1 ou "Rxxx Qn" para n>1) deve estar sob a categoria
## <category_root>/Qnn correspondente. Tambem confere cobertura de Q, total de
## variantes e ausencia de identidades duplicadas.
validate_moodle_question_categories <- function(xml_files, category_root,
                                                total_questions = NULL,
                                                variants = NULL,
                                                width = 2L) {
  lines <- unlist(
    lapply(xml_files, readLines, warn = FALSE, encoding = "UTF-8"),
    use.names = FALSE
  )

  current_category <- NA_character_
  questions <- integer()
  replicas <- integer()
  occurrence <- 0L
  keys <- character()

  for (line in lines) {
    m_cat <- regmatches(
      line,
      regexec("<text>(\\$course\\$/[^<]+)</text>", line, perl = TRUE)
    )[[1]]
    if (length(m_cat) > 0L) {
      current_category <- m_cat[2]
      next
    }

    identity <- parse_moodle_variant_identity(line)
    if (is.null(identity)) next

    occurrence <- occurrence + 1L
    q <- identity$q
    r <- identity$r
    expected <- moodle_question_category_path(category_root, q, width = width)

    if (is.na(current_category) || !identical(current_category, expected)) {
      id_text <- if (is.na(r)) paste0("Q", q) else paste0("R", r, " Q", q)
      stop("Moodle question category error: ", id_text,
           " is under '", current_category, "', expected '", expected, "'")
    }

    questions <- c(questions, q)
    replicas <- c(replicas, r)
    ## Com n=1 o exams2moodle nao fornece R; a identidade Q e suficiente.
    ## Com replicas, usa o par (Q,R), preservando a checagem historica.
    keys <- c(keys, if (is.na(r)) paste0(q, ":single") else paste(q, r, sep = ":"))
  }

  if (!is.null(total_questions)) {
    expected_q <- seq_len(as.integer(total_questions))
    observed_q <- sort(unique(questions))
    if (!identical(observed_q, expected_q)) {
      stop("Moodle question category error: Q coverage is not 1..",
           total_questions, " (observed: ", paste(observed_q, collapse = ", "), ")")
    }
  }

  if (!is.null(total_questions) && !is.null(variants)) {
    expected_n <- as.integer(total_questions) * as.integer(variants)
    if (length(questions) != expected_n) {
      stop("Moodle question category error: expected ", expected_n,
           " variants, found ", length(questions))
    }
  }

  if (anyDuplicated(keys)) {
    stop("Moodle question category error: duplicate variant identity")
  }

  invisible(TRUE)
}
