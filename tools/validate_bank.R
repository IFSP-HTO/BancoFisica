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
strict_warnings <- "--strict-warnings" %in% args ||
  tolower(Sys.getenv("BANK_VALIDATE_STRICT_WARNINGS", "false")) %in% c("1", "true", "yes")

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

problems <- data.frame(
  file = character(),
  severity = character(),
  problem = character(),
  stringsAsFactors = FALSE
)

add_problem <- function(file, severity, problem) {
  problems <<- rbind(
    problems,
    data.frame(
      file = file,
      severity = severity,
      problem = problem,
      stringsAsFactors = FALSE
    )
  )
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
  sub(pattern, "\\1", hits[1])
}

strip_rnw_noise <- function(x) {
  x <- gsub("%%.*$", "", x)
  x <- gsub("<<[^>]*>>=", "", x)
  x <- gsub("^@\\s*$", "", x)
  x <- gsub("\\\\Sexpr\\{[^}]+\\}", " Sexpr ", x)
  x <- gsub("\\\\begin\\{answerlist\\}|\\\\end\\{answerlist\\}|\\\\item", "", x)
  x <- gsub("[$_{}\\\\]", " ", x)
  trimws(x)
}

nonempty_text <- function(x, min_chars = 1) {
  if (is.null(x) || length(x) == 0) return(FALSE)
  clean <- strip_rnw_noise(x)
  clean <- clean[nzchar(clean)]
  nchar(paste(clean, collapse = " ")) >= min_chars
}

relative_path <- function(file) {
  sub(paste0("^", normalizePath(questions_dir, winslash = "/", mustWork = TRUE), "/?"),
      "", normalizePath(file, winslash = "/", mustWork = TRUE))
}

ids <- character(length(files))
subjects <- character(length(files))
extypes <- character(length(files))

for (i in seq_along(files)) {
  file <- files[i]
  rel <- relative_path(file)
  txt <- readLines(file, warn = FALSE, encoding = "UTF-8")

  question <- extract_block(txt, "question")
  solution <- extract_block(txt, "solution")
  extype <- extract_meta(txt, "extype")
  exsolution <- extract_meta(txt, "exsolution")
  exname <- extract_meta(txt, "exname")

  extypes[i] <- ifelse(is.na(extype), NA_character_, extype)

  subject <- dirname(rel)
  subjects[i] <- subject
  if (identical(subject, ".") || !nzchar(subject)) {
    add_problem(rel, "error", "missing_subject_directory")
  }

  if (is.na(exname) || !nzchar(trimws(exname))) {
    ids[i] <- tools::file_path_sans_ext(basename(rel))
    add_problem(rel, "warning", "missing_exname_using_filename_as_id")
  } else {
    ids[i] <- trimws(exname)
  }

  if (is.null(question)) {
    add_problem(rel, "error", "missing_question_block")
  } else if (!nonempty_text(question, min_chars = 10)) {
    add_problem(rel, "error", "empty_question_block")
  }

  if (is.null(solution)) {
    add_problem(rel, "error", "missing_solution_block")
  } else if (!nonempty_text(solution, min_chars = 1)) {
    add_problem(rel, "error", "empty_solution_block")
  }

  if (is.na(extype) || !nzchar(trimws(extype))) {
    add_problem(rel, "error", "missing_extype")
  } else if (!trimws(extype) %in% c("schoice", "mchoice", "num", "string", "cloze")) {
    add_problem(rel, "warning", paste0("unknown_extype:", trimws(extype)))
  }

  if (is.na(exsolution) || !nzchar(trimws(exsolution))) {
    add_problem(rel, "error", "missing_exsolution")
  }

  if (!is.na(extype) && trimws(extype) %in% c("schoice", "mchoice") && !is.null(question)) {
    question_text <- paste(question, collapse = "\n")
    if (!grepl("answerlist\\s*\\(", question_text)) {
      add_problem(rel, "error", "choice_question_without_answerlist")
    }

    if (!is.na(exsolution) && grepl("^[01]+$", trimws(exsolution))) {
      n_correct <- sum(strsplit(trimws(exsolution), "")[[1]] == "1")
      if (trimws(extype) == "schoice" && n_correct != 1) {
        add_problem(rel, "error", "schoice_exsolution_not_single_correct")
      }
      if (trimws(extype) == "mchoice" && n_correct < 1) {
        add_problem(rel, "error", "mchoice_exsolution_without_correct_option")
      }
    }
  }
}

id_table <- table(ids)
duplicate_ids <- names(id_table[id_table > 1])
if (length(duplicate_ids) > 0) {
  for (id in duplicate_ids) {
    duplicated_files <- relative_path(files[ids == id])
    add_problem(
      paste(duplicated_files, collapse = "; "),
      "error",
      paste0("duplicate_question_id:", id)
    )
  }
}

summary_by_subject <- sort(table(subjects), decreasing = TRUE)
summary_by_extype <- sort(table(extypes, useNA = "ifany"), decreasing = TRUE)

cat("BancoFisica structural validation\n")
cat("================================\n")
cat("Questions directory:", questions_dir, "\n")
cat("Total .Rnw files:", length(files), "\n")
cat("Unique question IDs:", length(unique(ids)), "\n")
cat("Strict warnings:", strict_warnings, "\n\n")

cat("Questions by subject\n")
print(summary_by_subject)
cat("\nQuestions by extype\n")
print(summary_by_extype)
cat("\n")

if (nrow(problems) > 0) {
  problems <- problems[order(problems$severity, problems$file, problems$problem), ]
  print(problems, row.names = FALSE)
  cat("\nSummary by severity\n")
  print(table(problems$severity))
  cat("\nSummary by problem\n")
  print(sort(table(problems$problem), decreasing = TRUE))

  has_errors <- any(problems$severity == "error")
  has_warnings <- any(problems$severity == "warning")

  if (has_errors || (strict_warnings && has_warnings)) {
    cat("\nStructural validation failed.\n")
    quit(status = 1)
  }

  cat("\nStructural validation passed with warnings.\n")
  quit(status = 0)
}

cat("Structural validation passed.\n")
