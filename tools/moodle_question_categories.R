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
## bloco sempre que muda o Q presente no nome da variante (Rxxx Qn : ...).

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
      block_text <- paste(block, collapse = "\n")
      m_name <- regmatches(
        block_text,
        regexec("<text>[[:space:]]*R([0-9]+)[[:space:]]+Q([0-9]+)[[:space:]]*:",
                block_text, perl = TRUE)
      )[[1]]

      if (length(m_name) > 0L) {
        q <- as.integer(m_name[3])
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
## variante Rxxx Qn deve estar imediatamente sob a categoria logica
## <category_root>/Qnn correspondente. Tambem confere cobertura de Q e total de
## variantes quando esses valores sao fornecidos.
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

  for (line in lines) {
    m_cat <- regmatches(
      line,
      regexec("<text>(\\$course\\$/[^<]+)</text>", line, perl = TRUE)
    )[[1]]
    if (length(m_cat) > 0L) {
      current_category <- m_cat[2]
      next
    }

    m_name <- regmatches(
      line,
      regexec("<text>[[:space:]]*R([0-9]+)[[:space:]]+Q([0-9]+)[[:space:]]*:",
              line, perl = TRUE)
    )[[1]]
    if (length(m_name) == 0L) next

    r <- as.integer(m_name[2])
    q <- as.integer(m_name[3])
    expected <- moodle_question_category_path(category_root, q, width = width)

    if (is.na(current_category) || !identical(current_category, expected)) {
      stop("Moodle question category error: R", r, " Q", q,
           " is under '", current_category, "', expected '", expected, "'")
    }

    questions <- c(questions, q)
    replicas <- c(replicas, r)
  }

  if (!is.null(total_questions)) {
    expected_q <- seq_len(as.integer(total_questions))
    if (!identical(sort(unique(questions)), expected_q)) {
      stop("Moodle question category error: Q coverage is not 1..",
           total_questions)
    }
  }

  if (!is.null(total_questions) && !is.null(variants)) {
    expected_n <- as.integer(total_questions) * as.integer(variants)
    if (length(questions) != expected_n) {
      stop("Moodle question category error: expected ", expected_n,
           " variants, found ", length(questions))
    }
  }

  keys <- paste(questions, replicas, sep = ":")
  if (anyDuplicated(keys)) {
    stop("Moodle question category error: duplicate (Q,R) identity")
  }

  invisible(TRUE)
}
