#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
check_mode <- "--check" %in% args

questions_dir <- "BancoDeQuestoes"
out_dir <- "docs"
csv_file <- file.path(out_dir, "question-counts.csv")
svg_file <- file.path(out_dir, "question-counts.svg")

if (!dir.exists(questions_dir)) {
  stop("Directory not found: ", questions_dir)
}

files <- sort(list.files(
  questions_dir,
  pattern = "\\.[Rr]nw$",
  recursive = TRUE,
  full.names = TRUE
))

relative <- sub(paste0("^", questions_dir, "/"), "", files)
parts <- strsplit(relative, "/", fixed = TRUE)

subject_from_parts <- function(x) {
  dirs <- head(x, -1)
  if (length(dirs) == 0) return("Sem assunto")
  paste(dirs, collapse = "/")
}

subjects <- vapply(parts, subject_from_parts, character(1))
counts <- sort(table(subjects), decreasing = TRUE)

df <- data.frame(
  assunto = names(counts),
  questoes = as.integer(counts),
  stringsAsFactors = FALSE
)

if (!dir.exists(out_dir)) {
  dir.create(out_dir, recursive = TRUE)
}

write.csv(df, csv_file, row.names = FALSE, fileEncoding = "UTF-8")

height <- max(420, 26 * nrow(df) + 120)
width <- 960

svg(svg_file, width = width / 96, height = height / 96, bg = "white")
op <- par(
  mar = c(5, 18, 5, 3),
  family = "sans",
  cex.axis = 0.8,
  cex.names = 0.75
)
barplot(
  rev(df$questoes),
  names.arg = rev(df$assunto),
  horiz = TRUE,
  las = 1,
  xlab = "Número de questões",
  main = "Questões por assunto",
  border = NA
)
grid(nx = NA, ny = NULL, lty = "dotted", col = "gray80")
par(op)
dev.off()

cat("QUESTION_COUNTS_BEGIN\n")
cat("Total de questões:", length(files), "\n")
cat("Total de assuntos:", nrow(df), "\n")
print(df, row.names = FALSE)
cat("QUESTION_COUNTS_END\n")

if (check_mode) {
  status <- system("git diff --exit-code -- docs/question-counts.csv docs/question-counts.svg", ignore.stdout = TRUE, ignore.stderr = TRUE)
  if (!identical(status, 0L)) {
    stop("Question count chart is out of date. Run: Rscript tools/question_counts.R")
  }
}
