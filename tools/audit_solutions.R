#!/usr/bin/env Rscript

strict <- tolower(Sys.getenv("AUDIT_SOLUTIONS_STRICT", "false")) %in% c("1", "true", "yes")

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

add_problem <- function(report, file, problem) {
  rbind(
    report,
    data.frame(file = file, problem = problem, stringsAsFactors = FALSE)
  )
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
    report <- add_problem(report, f, "missing_solution_block")
    next
  }

  sol_text <- paste(sol, collapse = "\n")
  clean <- strip_noise(sol)
  clean_text <- paste(clean[nzchar(clean)], collapse = " ")

  if (grepl("Supply a solution here", sol_text, fixed = TRUE)) {
    report <- add_problem(report, f, "placeholder_solution")
  }

  if (nchar(clean_text) < 20) {
    report <- add_problem(report, f, "very_short_solution")
  }
}

cat("Solution audit\n")
cat("==============\n")
cat("Total .Rnw files:", length(files), "\n")
cat("Problematic entries:", nrow(report), "\n")
cat("Strict mode:", strict, "\n\n")

if (nrow(report) > 0) {
  print(report, row.names = FALSE)
  cat("\nSummary by problem:\n")
  print(sort(table(report$problem), decreasing = TRUE))

  if (strict) {
    cat("\nFailing because AUDIT_SOLUTIONS_STRICT is enabled.\n")
    quit(status = 1)
  }

  cat("\nAudit found issues, but this run is non-blocking.\n")
  cat("Set AUDIT_SOLUTIONS_STRICT=true to make these findings fail CI.\n")
  quit(status = 0)
}

cat("All questions have non-trivial solution blocks.\n")