#!/usr/bin/env Rscript

files <- sort(list.files("BancoDeQuestoes", pattern = "\\.[Rr]nw$", recursive = TRUE, full.names = TRUE))

extract_solution <- function(txt) {
  start <- grep("\\\\begin\\{solution\\}", txt)
  end <- grep("\\\\end\\{solution\\}", txt)
  if (length(start) == 0 || length(end) == 0) return(NULL)
  end <- end[end > start[1]]
  if (length(end) == 0) return(NULL)
  txt[(start[1] + 1):(end[1] - 1)]
}

strip_noise <- function(x) {
  x <- gsub("%%.*$", "", x)
  x <- gsub("\\\\Sexpr\\{[^}]+\\}", "", x)
  x <- gsub("\\\\begin\\{answerlist\\}|\\\\end\\{answerlist\\}|\\\\item", "", x)
  x <- gsub("[$_{}\\\\]", " ", x)
  trimws(x)
}

report <- data.frame(
  file = character(),
  problem = character(),
  stringsAsFactors = FALSE
)

for (f in files) {
  txt <- readLines(f, warn = FALSE, encoding = "UTF-8")
  sol <- extract_solution(txt)

  if (is.null(sol)) {
    report <- rbind(report, data.frame(file = f, problem = "missing_solution_block"))
    next
  }

  sol_text <- paste(sol, collapse = "\n")
  clean <- strip_noise(sol)
  clean_text <- paste(clean[nzchar(clean)], collapse = " ")

  if (grepl("Supply a solution here", sol_text, fixed = TRUE)) {
    report <- rbind(report, data.frame(file = f, problem = "placeholder_solution"))
  }

  if (nchar(clean_text) < 20) {
    report <- rbind(report, data.frame(file = f, problem = "very_short_solution"))
  }
}

cat("Solution audit\n")
cat("==============\n")
cat("Total .Rnw files:", length(files), "\n")
cat("Problematic entries:", nrow(report), "\n\n")

if (nrow(report) > 0) {
  print(report, row.names = FALSE)
  cat("\nSummary by problem:\n")
  print(sort(table(report$problem), decreasing = TRUE))
  quit(status = 1)
}

cat("All questions have non-trivial solution blocks.\n")
