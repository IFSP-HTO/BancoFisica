## grade.R
## Corrige a resposta do usuário contra os gabaritos/tolerâncias extraídos do
## XML. Não depende de shiny: devolve estrutura; o app monta o HTML do feedback.

.para_num <- function(x) {
  if (is.null(x) || length(x) == 0) return(NA_real_)
  suppressWarnings(as.numeric(gsub(",", ".", trimws(as.character(x)))))
}

.num_ok <- function(user, value, tol) {
  if (is.na(user) || is.na(value)) return(FALSE)
  if (is.na(tol)) tol <- 0
  abs(user - value) <= tol + 1e-9
}

.norm_txt <- function(x, usecase = FALSE) {
  x <- trimws(gsub("\\s+", " ", as.character(x)))
  if (!usecase) x <- tolower(x)
  x
}

.text_ok <- function(user, aceitos, usecase = FALSE) {
  if (is.null(user) || !nzchar(trimws(user))) return(FALSE)
  .norm_txt(user, usecase) %in% .norm_txt(aceitos, usecase)
}

## Corrige uma lacuna cloze isolada.
.grade_gap <- function(gap, user) {
  if (gap$type == "num") {
    u <- .para_num(user)
    ok <- any(vapply(gap$answers, function(a) .num_ok(u, a$value, a$tol),
                     logical(1)))
  } else {                                   # text / choice -> comparação textual
    aceitos <- vapply(gap$answers, function(a)
      if (!is.null(a$text)) a$text else "", character(1))
    aceitos <- aceitos[nzchar(aceitos)]
    ok <- .text_ok(user, aceitos, usecase = FALSE)
  }
  list(id = gap$id, type = gap$type, correct = isTRUE(ok))
}

## resp: numerical/shortanswer -> escalar; multichoice -> índices marcados;
##       cloze -> lista nomeada por id de lacuna ("gap_1", ...).
grade_question <- function(q, resp) {
  if (q$type == "numerical") {
    u <- .para_num(resp)
    ok <- any(vapply(q$answers, function(a) .num_ok(u, a$value, a$tol),
                     logical(1)))
    return(list(type = q$type, correct = isTRUE(ok)))

  } else if (q$type == "shortanswer") {
    ok <- .text_ok(resp, q$answers, usecase = isTRUE(q$usecase))
    return(list(type = q$type, correct = isTRUE(ok)))

  } else if (q$type == "multichoice") {
    sel <- as.integer(resp)
    n <- length(q$options)
    corretas <- which(vapply(q$options, function(o) o$fraction > 0, logical(1)))
    detalhe <- lapply(seq_len(n), function(i) {
      list(html = q$options[[i]]$html,
           feedback = q$options[[i]]$feedback,
           is_correct = i %in% corretas,
           selected = i %in% sel)
    })
    ok <- if (isTRUE(q$single)) length(sel) == 1 && sel %in% corretas
          else setequal(sel, corretas)
    return(list(type = q$type, single = q$single, options = detalhe,
                correct = isTRUE(ok)))

  } else if (q$type == "cloze") {
    res <- lapply(q$gaps, function(g)
      .grade_gap(g, resp[[paste0("gap_", g$id)]]))
    nok <- sum(vapply(res, function(r) r$correct, logical(1)))
    return(list(type = q$type, gaps = res, n_correct = nok,
                n_total = length(res), correct = nok == length(res)))
  }
  list(type = q$type, correct = NA)
}
