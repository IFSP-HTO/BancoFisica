#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)

get_arg <- function(flag, default = NULL) {
  idx <- which(args == flag)
  if (length(idx) == 1 && length(args) >= idx + 1) {
    return(args[idx + 1])
  }
  default
}

has_flag <- function(flag) flag %in% args

questions_dir <- get_arg("--questions-dir", "BancoDeQuestoes")
out_dir <- get_arg("--out-dir", "Moodle/generated")
seed <- as.integer(get_arg("--seed", "1"))
n_variants <- as.integer(get_arg("--n", "100"))
layout <- get_arg("--layout", "structured")
make_zip <- has_flag("--zip")
check_mode <- has_flag("--check")

if (is.na(seed)) stop("--seed must be an integer")
if (is.na(n_variants) || n_variants < 1) stop("--n must be a positive integer")
if (!layout %in% c("structured", "flat")) {
  stop("--layout must be either 'structured' or 'flat'")
}
if (!dir.exists(questions_dir)) {
  stop("Questions directory not found: ", questions_dir)
}

repo_root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
questions_dir_abs <- normalizePath(questions_dir, winslash = "/", mustWork = TRUE)
out_parent <- dirname(out_dir)
if (!dir.exists(out_parent)) dir.create(out_parent, recursive = TRUE)
out_dir_abs <- normalizePath(out_dir, winslash = "/", mustWork = FALSE)
protected_dirs <- normalizePath(
  c(repo_root, questions_dir_abs, file.path(repo_root, "Moodle")),
  winslash = "/",
  mustWork = FALSE
)
if (out_dir_abs %in% protected_dirs) {
  stop("Refusing to clean protected output directory: ", out_dir)
}

suppressMessages({
  library(exams)
  library(callr)
  library(magrittr)
  library(stringr)
  library(purrr)
})

slug_segment <- function(x) {
  x <- iconv(x, from = "", to = "ASCII//TRANSLIT", sub = "")
  x <- tolower(x)
  x <- gsub("[^a-z0-9]+", "-", x)
  x <- gsub("(^-+|-+$)", "", x)
  if (!nzchar(x)) "assunto" else x
}

slug_path <- function(path) {
  parts <- strsplit(path, "/", fixed = TRUE)[[1]]
  paste(vapply(parts, slug_segment, character(1)), collapse = "/")
}

subject_dirs <- function(root) {
  files <- sort(list.files(
    root,
    pattern = "\\.[Rr]nw$",
    recursive = TRUE,
    full.names = TRUE
  ))
  if (length(files) == 0) stop("No .Rnw files found in ", root)
  dirs <- unique(dirname(files))
  dirs[order(dirs)]
}

relative_dir <- function(path, root) {
  sub(
    paste0("^", normalizePath(root, winslash = "/", mustWork = TRUE), "/?"),
    "",
    normalizePath(path, winslash = "/", mustWork = TRUE)
  )
}

output_for_subject <- function(subject, out_root, layout, seed) {
  slug <- slug_path(subject)
  if (layout == "structured") {
    parent <- dirname(slug)
    base <- basename(slug)
    dir <- if (identical(parent, ".")) out_root else file.path(out_root, parent)
    name <- paste0(base, "-", seed)
  } else {
    dir <- out_root
    name <- paste0(gsub("/", "-", slug, fixed = TRUE), "-", seed)
  }
  list(dir = dir, name = name, file = file.path(dir, paste0(name, ".xml")))
}

generate_subject <- function(source_dir, output_dir, output_name, n_variants, seed) {
  callr::r(
    function(source_dir, output_dir, output_name, n_variants, seed) {
      suppressMessages({
        library(exams)
        library(magrittr)
        library(stringr)
        library(purrr)
      })
      files <- sort(list.files(source_dir, pattern = "\\.[Rr]nw$", ignore.case = TRUE))
      if (length(files) == 0) stop("No .Rnw files in ", source_dir)
      if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE)
      set.seed(seed)
      exams2moodle(
        files,
        n = n_variants,
        rule = "none",
        schoice = list(shuffle = TRUE),
        converter = "pandoc-mathjax",
        name = output_name,
        encoding = "UTF-8",
        dir = output_dir,
        edir = source_dir
      )
      file.path(output_dir, paste0(output_name, ".xml"))
    },
    args = list(
      source_dir = source_dir,
      output_dir = output_dir,
      output_name = output_name,
      n_variants = n_variants,
      seed = seed
    )
  )
}

validate_xml <- function(path) {
  text <- paste(readLines(path, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
  if (!grepl("<quiz[[:space:]>]", text, perl = TRUE)) {
    stop("Missing <quiz> root in ", path)
  }
  if (!grepl("</quiz>", text, fixed = TRUE)) {
    stop("Missing </quiz> closing tag in ", path)
  }
  if (grepl("<parsererror", text, fixed = TRUE)) {
    stop("Parser error marker in ", path)
  }
  tags <- regmatches(
    text,
    gregexpr("<question[[:space:]]+type=\"[^\"]+\"", text, perl = TRUE)
  )[[1]]
  if (length(tags) == 1 && identical(tags, -1L)) tags <- character()
  sum(!grepl("type=\"category\"", tags, fixed = TRUE))
}

if (dir.exists(out_dir)) {
  unlink(out_dir, recursive = TRUE)
}
dir.create(out_dir, recursive = TRUE)

dirs <- subject_dirs(questions_dir)
rows <- vector("list", length(dirs))

cat("MOODLE_XML_GENERATION_BEGIN\n")
cat("Questions directory:", questions_dir, "\n")
cat("Output directory:", out_dir, "\n")
cat("Seed:", seed, "\n")
cat("Variants per question:", n_variants, "\n")
cat("Layout:", layout, "\n")
cat("Subjects:", length(dirs), "\n")

for (i in seq_along(dirs)) {
  source_dir <- dirs[[i]]
  subject <- relative_dir(source_dir, questions_dir)
  out <- output_for_subject(subject, out_dir, layout, seed)
  source_files <- list.files(source_dir, pattern = "\\.[Rr]nw$", ignore.case = TRUE)

  cat(sprintf("[%d/%d] %s -> %s\n", i, length(dirs), subject, out$file))
  xml_file <- generate_subject(source_dir, out$dir, out$name, n_variants, seed)
  n_questions <- validate_xml(xml_file)

  rows[[i]] <- data.frame(
    subject = subject,
    source_dir = source_dir,
    xml_file = xml_file,
    source_questions = length(source_files),
    moodle_questions = n_questions,
    variants = n_variants,
    seed = seed,
    stringsAsFactors = FALSE
  )
}

manifest <- do.call(rbind, rows)
manifest_file <- file.path(out_dir, "manifest.csv")
write.csv(manifest, manifest_file, row.names = FALSE, fileEncoding = "UTF-8")

zip_file <- NA_character_
if (make_zip) {
  zip_file <- file.path(out_dir, "XML.zip")
  old <- getwd()
  on.exit(setwd(old), add = TRUE)
  setwd(out_dir)
  files <- list.files(".", pattern = "\\.xml$|manifest\\.csv$", recursive = TRUE)
  status <- utils::zip("XML.zip", files = files)
  if (!identical(status, 0L)) stop("Failed to create ", zip_file)
  setwd(old)
}

print(manifest[, c("subject", "source_questions", "moodle_questions", "xml_file")],
      row.names = FALSE)
cat("Manifest:", manifest_file, "\n")
if (make_zip) cat("Zip:", zip_file, "\n")
cat("MOODLE_XML_GENERATION_END\n")

if (check_mode) {
  if (!file.exists(manifest_file)) stop("Manifest was not generated")
  if (any(!file.exists(manifest$xml_file))) stop("Some XML files were not generated")
  if (make_zip && !file.exists(zip_file)) stop("Zip was not generated")
}
