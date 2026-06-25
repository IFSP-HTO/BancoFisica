#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)

get_arg <- function(flag, default) {
  idx <- which(args == flag)
  if (length(idx) == 1 && length(args) >= idx + 1) {
    return(args[idx + 1])
  }
  default
}

questions_dir <- get_arg("--questions-dir", "BancoDeQuestoes")
out_dir <- get_arg("--out-dir", "build/quality-report")

if (!dir.exists(questions_dir)) {
  stop("Questions directory not found: ", questions_dir)
}

if (!dir.exists(out_dir)) {
  dir.create(out_dir, recursive = TRUE)
}

files <- sort(list.files(
  questions_dir,
  pattern = "\\.[Rr]nw$",
  recursive = TRUE,
  full.names = TRUE
))

if (length(files) == 0L) {
  stop("No .Rnw files found in ", questions_dir)
}

extract_block <- function(txt, env) {
  start <- grep(paste0("\\\\begin\\{", env, "\\}"), txt)
  end <- grep(paste0("\\\\end\\{", env, "\\}"), txt)
  if (length(start) == 0L || length(end) == 0L) return(NULL)
  end <- end[end > start[1]]
  if (length(end) == 0L) return(NULL)
  txt[(start[1] + 1):(end[1] - 1)]
}

extract_meta <- function(txt, key) {
  pattern <- paste0("^%%\\s*\\\\", key, "\\{(.*)\\}\\s*$")
  hits <- grep(pattern, txt, value = TRUE)
  if (length(hits) == 0L) return(NA_character_)
  trimws(sub(pattern, "\\1", hits[1]))
}

strip_noise <- function(x) {
  if (is.null(x) || length(x) == 0L) return("")
  x <- gsub("%%.*$", "", x)
  x <- gsub("<<[^>]*>>=", "", x)
  x <- gsub("^@\\s*$", "", x)
  x <- gsub("\\\\Sexpr\\{[^}]+\\}", " Sexpr ", x)
  x <- gsub("\\\\begin\\{answerlist\\}|\\\\end\\{answerlist\\}|\\\\item", " ", x)
  x <- gsub("\\$", " ", x)
  x <- gsub("_", " ", x, fixed = TRUE)
  x <- gsub("[{}]", " ", x)
  x <- gsub("\\\\", " ", x)
  x <- trimws(x)
  paste(x[nzchar(x)], collapse = " ")
}

relative_path <- function(file) {
  sub(paste0("^", normalizePath(questions_dir, winslash = "/", mustWork = TRUE), "/?"),
      "", normalizePath(file, winslash = "/", mustWork = TRUE))
}

has_any_fixed <- function(txt, patterns) {
  if (is.null(txt) || length(txt) == 0L) return(FALSE)
  any(vapply(patterns, function(p) any(grepl(p, txt, fixed = TRUE)), logical(1)))
}

has_visible_math <- function(block) {
  if (is.null(block) || length(block) == 0L) return(FALSE)
  text <- paste(block, collapse = "\n")
  has_any_fixed(block, c("$", "\\(", "\\[", "\\frac", "\\sqrt", "\\times", "\\cdot", "\\Sexpr{")) ||
    grepl("[A-Za-z]\\s*=\\s*[^=]", text, perl = TRUE)
}

rows <- list()
idx <- 0L

add_row <- function(file, subject, exname, severity, problem, priority_score, detail) {
  idx <<- idx + 1L
  rows[[idx]] <<- data.frame(
    file = file,
    subject = subject,
    exname = ifelse(is.na(exname), "", exname),
    severity = severity,
    problem = problem,
    priority_score = priority_score,
    detail = detail,
    stringsAsFactors = FALSE
  )
}

for (file in files) {
  rel <- relative_path(file)
  subject <- dirname(rel)
  if (identical(subject, ".") || !nzchar(subject)) subject <- "Sem assunto"

  txt <- readLines(file, warn = FALSE, encoding = "UTF-8")
  question <- extract_block(txt, "question")
  solution <- extract_block(txt, "solution")
  question_text <- strip_noise(question)
  solution_text <- strip_noise(solution)

  exname <- extract_meta(txt, "exname")
  extype <- extract_meta(txt, "extype")

  question_chars <- nchar(question_text)
  solution_chars <- nchar(solution_text)
  has_solution <- !is.null(solution) && solution_chars > 0L
  objective_question <- !is.na(extype) && extype %in% c("schoice", "mchoice")

  if (has_solution && solution_chars < 80L) {
    add_row(rel, subject, exname, "high", "solution_too_short", 90L,
            paste0("solution_chars=", solution_chars))
  } else if (has_solution && solution_chars < 160L) {
    add_row(rel, subject, exname, "medium", "solution_may_be_too_brief", 60L,
            paste0("solution_chars=", solution_chars))
  }

  if (has_solution && !has_visible_math(solution)) {
    add_row(rel, subject, exname, "medium", "solution_without_visible_math", 55L,
            "no equation or LaTeX marker detected in solution")
  }

  if (question_chars > 0L && question_chars < 120L) {
    add_row(rel, subject, exname, "medium", "question_statement_may_be_too_short", 45L,
            paste0("question_chars=", question_chars))
  }

  if (objective_question && !has_any_fixed(question, c("\\begin{answerlist}"))) {
    add_row(rel, subject, exname, "medium", "choice_question_without_answerlist", 50L,
            "objective question without answerlist marker")
  }
}

report <- if (length(rows) > 0L) {
  out <- do.call(rbind, rows)
  out[order(-out$priority_score, out$file, out$problem), , drop = FALSE]
} else {
  data.frame(file = character(), subject = character(), exname = character(), severity = character(),
             problem = character(), priority_score = integer(), detail = character(), stringsAsFactors = FALSE)
}

write.csv(report, file.path(out_dir, "quality-teaching-audit.csv"), row.names = FALSE, fileEncoding = "UTF-8")

cat("TEACHING_AUDIT_BEGIN\n")
cat("Output:", file.path(out_dir, "quality-teaching-audit.csv"), "\n")
cat("Issues:", nrow(report), "\n")
if (nrow(report) > 0L) {
  print(head(report, 20), row.names = FALSE)
}
cat("TEACHING_AUDIT_END\n")
