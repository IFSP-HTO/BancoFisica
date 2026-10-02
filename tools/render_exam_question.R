#!/usr/bin/env Rscript
args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 3L) {
  stop("usage: render_exam_question.R INPUT.Rnw OUTPUT.tex SEED")
}
input <- normalizePath(args[[1]], mustWork = TRUE)
output <- normalizePath(args[[2]], mustWork = FALSE)
seed <- as.integer(args[[3]])
if (is.na(seed)) stop("invalid seed")
if (!requireNamespace("exams", quietly = TRUE)) stop("R package 'exams' is required")

set.seed(seed)
suppressPackageStartupMessages(library(exams))
old <- getwd()
on.exit(setwd(old), add = TRUE)
setwd(dirname(input))

# Sweave evaluates the same <<...>>= / \Sexpr{} constructs used by R/exams
# questions. The Python layer extracts only the question and its answerlist.
utils::Sweave(
  basename(input),
  output = output,
  quiet = TRUE,
  encoding = "UTF-8"
)
