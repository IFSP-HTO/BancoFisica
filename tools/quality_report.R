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

files <- sort(list.files(
  questions_dir,
  pattern = "\\.[Rr]nw$",
  recursive = TRUE,
  full.names = TRUE
))

if (length(files) == 0) {
  stop("No .Rnw question files found in ", questions_dir)
}

if (!dir.exists(out_dir)) {
  dir.create(out_dir, recursive = TRUE)
}

extract_block <- function(txt, env) {
  start <- grep(paste0("\\\\begin\\{", env, "\\}"), txt)
  end <- grep(paste0("\\\\end\\{", env, "\\}"), txt)

  if (length(start) == 0 || length(end) == 0) return(NULL)

  end <- end[end > start[1]]
  if (length(end) == 0) return(NULL)

  txt[(start[1] + 1):(end[1] - 1)]
}

extract_meta <- function(txt, key) {
  pattern <- paste0("^%%\\s*\\\\", key, "\\{(.*)\\}\\s*$")
  hits <- grep(pattern, txt, value = TRUE)
  if (length(hits) == 0) return(NA_character_)
  trimws(sub(pattern, "\\1", hits[1]))
}

strip_noise <- function(x) {
  if (is.null(x) || length(x) == 0) return("")
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
  any(vapply(patterns, function(p) any(grepl(p, txt, fixed = TRUE)), logical(1)))
}

question_rows <- vector("list", length(files))
alert_rows <- list()
alert_index <- 0L

add_alert <- function(file, severity, problem) {
  alert_index <<- alert_index + 1L
  alert_rows[[alert_index]] <<- data.frame(
    file = file,
    severity = severity,
    problem = problem,
    stringsAsFactors = FALSE
  )
}

for (i in seq_along(files)) {
  file <- files[i]
  rel <- relative_path(file)
  txt <- readLines(file, warn = FALSE, encoding = "UTF-8")

  question <- extract_block(txt, "question")
  solution <- extract_block(txt, "solution")
  question_text <- strip_noise(question)
  solution_text <- strip_noise(solution)

  subject <- dirname(rel)
  if (identical(subject, ".") || !nzchar(subject)) subject <- "Sem assunto"

  extype <- extract_meta(txt, "extype")
  exsolution <- extract_meta(txt, "exsolution")
  exname <- extract_meta(txt, "exname")

  has_question <- !is.null(question) && nchar(question_text) > 0
  has_solution <- !is.null(solution) && nchar(solution_text) > 0
  solution_chars <- nchar(solution_text)
  question_chars <- nchar(question_text)
  short_solution <- has_solution && solution_chars < 80
  dynamic <- has_any_fixed(txt, c("\\Sexpr{", "sample(", "runif(", "rnorm(", "sample.int("))

  if (!has_question) add_alert(rel, "error", "missing_or_empty_question_block")
  if (!has_solution) add_alert(rel, "error", "missing_or_empty_solution_block")
  if (is.na(extype) || !nzchar(extype)) add_alert(rel, "error", "missing_extype")
  if (is.na(exsolution) || !nzchar(exsolution)) add_alert(rel, "error", "missing_exsolution")
  if (is.na(exname) || !nzchar(exname)) add_alert(rel, "warning", "missing_exname")
  if (short_solution) add_alert(rel, "warning", "short_solution")

  question_rows[[i]] <- data.frame(
    file = rel,
    subject = subject,
    exname = ifelse(is.na(exname), "", exname),
    extype = ifelse(is.na(extype), "", extype),
    dynamic = dynamic,
    has_question = has_question,
    has_solution = has_solution,
    question_chars = question_chars,
    solution_chars = solution_chars,
    short_solution = short_solution,
    stringsAsFactors = FALSE
  )
}

questions <- do.call(rbind, question_rows)
alerts <- if (length(alert_rows) > 0) {
  do.call(rbind, alert_rows)
} else {
  data.frame(file = character(), severity = character(), problem = character(), stringsAsFactors = FALSE)
}

subject_counts <- as.data.frame(sort(table(questions$subject), decreasing = TRUE), stringsAsFactors = FALSE)
names(subject_counts) <- c("subject", "questions")

extype_counts <- as.data.frame(sort(table(questions$extype), decreasing = TRUE), stringsAsFactors = FALSE)
names(extype_counts) <- c("extype", "questions")

summary <- data.frame(
  metric = c(
    "total_questions",
    "total_subjects",
    "dynamic_questions",
    "static_questions",
    "questions_with_solution",
    "questions_without_solution",
    "short_solutions",
    "alerts_total",
    "alerts_errors",
    "alerts_warnings"
  ),
  value = c(
    nrow(questions),
    length(unique(questions$subject)),
    sum(questions$dynamic),
    sum(!questions$dynamic),
    sum(questions$has_solution),
    sum(!questions$has_solution),
    sum(questions$short_solution),
    nrow(alerts),
    sum(alerts$severity == "error"),
    sum(alerts$severity == "warning")
  ),
  stringsAsFactors = FALSE
)

write.csv(questions, file.path(out_dir, "quality-questions.csv"), row.names = FALSE, fileEncoding = "UTF-8")
write.csv(alerts, file.path(out_dir, "quality-alerts.csv"), row.names = FALSE, fileEncoding = "UTF-8")
write.csv(summary, file.path(out_dir, "quality-summary.csv"), row.names = FALSE, fileEncoding = "UTF-8")
write.csv(subject_counts, file.path(out_dir, "quality-subjects.csv"), row.names = FALSE, fileEncoding = "UTF-8")
write.csv(extype_counts, file.path(out_dir, "quality-extypes.csv"), row.names = FALSE, fileEncoding = "UTF-8")

format_md_table <- function(df, max_rows = Inf) {
  if (nrow(df) == 0) return("Nenhum item encontrado.\n")
  df <- head(df, max_rows)
  cols <- names(df)
  out <- c(
    paste0("| ", paste(cols, collapse = " | "), " |"),
    paste0("| ", paste(rep("---", length(cols)), collapse = " | "), " |")
  )
  for (i in seq_len(nrow(df))) {
    values <- vapply(df[i, , drop = FALSE], as.character, character(1))
    values <- gsub("\\|", "\\\\|", values)
    out <- c(out, paste0("| ", paste(values, collapse = " | "), " |"))
  }
  paste(out, collapse = "\n")
}

report <- c(
  "# Relatório de qualidade do BancoFisica",
  "",
  paste0("Gerado em: `", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z"), "`"),
  "",
  "## Resumo geral",
  "",
  format_md_table(summary),
  "",
  "## Questões por assunto",
  "",
  format_md_table(subject_counts),
  "",
  "## Questões por tipo (`extype`)",
  "",
  format_md_table(extype_counts),
  "",
  "## Alertas estruturais e pedagógicos simples",
  "",
  if (nrow(alerts) > 50) {
    paste0("Mostrando os primeiros 50 de ", nrow(alerts), " alertas. Consulte `quality-alerts.csv` para a lista completa.\n\n",
           format_md_table(alerts, max_rows = 50))
  } else {
    format_md_table(alerts)
  },
  "",
  "## Arquivos gerados",
  "",
  "- `quality-report.md`",
  "- `quality-summary.csv`",
  "- `quality-questions.csv`",
  "- `quality-alerts.csv`",
  "- `quality-subjects.csv`",
  "- `quality-extypes.csv`",
  "",
  "Observação: este relatório é diagnóstico. Ele não bloqueia o CI; bloqueios devem ser ativados em validadores específicos quando o banco estiver limpo."
)

writeLines(report, file.path(out_dir, "quality-report.md"), useBytes = TRUE)

cat("QUALITY_REPORT_BEGIN\n")
cat("Generated report directory:", out_dir, "\n")
print(summary, row.names = FALSE)
cat("QUALITY_REPORT_END\n")
