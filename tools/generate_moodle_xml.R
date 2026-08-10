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
max_size_mb <- as.numeric(get_arg("--max-size-mb", "10"))
make_zip <- has_flag("--zip")
check_mode <- has_flag("--check")

if (is.na(seed)) stop("--seed must be an integer")
if (is.na(n_variants) || n_variants < 1) stop("--n must be a positive integer")
if (is.na(max_size_mb) || max_size_mb < 1) stop("--max-size-mb must be a positive number of megabytes")
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

## Limite de 10 MB e particionamento compartilhados (tools/moodle_xml_split.R).
source("tools/moodle_xml_split.R")

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

generate_subject <- function(source_dir, output_dir, output_name, n_variants, seed, max_bytes) {
  callr::r(
    function(source_dir, output_dir, output_name, n_variants, seed, max_bytes, repo_root) {
      suppressMessages({
        library(exams)
        library(magrittr)
        library(stringr)
        library(purrr)
      })
      ## Particionamento em ate 10 MB compartilhado com o script legado.
      source(file.path(repo_root, "tools", "moodle_xml_split.R"))
      files <- sort(list.files(source_dir, pattern = "\\.[Rr]nw$", ignore.case = TRUE))
      if (length(files) == 0) stop("No .Rnw files in ", source_dir)
      if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE)
      generate_moodle_xml_limited(
        files,
        n = n_variants,
        name = output_name,
        seed = seed,
        edir = source_dir,
        dir = output_dir,
        encoding = "UTF-8",
        converter = "pandoc-mathjax",
        max_bytes = max_bytes
      )
    },
    args = list(
      source_dir = source_dir,
      output_dir = output_dir,
      output_name = output_name,
      n_variants = n_variants,
      seed = seed,
      max_bytes = max_bytes,
      repo_root = repo_root
    )
  )
}

validate_xml <- function(path, max_bytes = NULL) {
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
  if (!is.null(max_bytes) && file.size(path) > max_bytes) {
    stop("Moodle XML exceeds upload limit (", file.size(path),
         " > ", max_bytes, " bytes) in ", path)
  }
  if (grepl("src=\"%7B[^\"]*%7D\"", text, perl = TRUE)) {
    stop("Broken image src (percent-encoded braces %7B...%7D) in ", path)
  }
  img_srcs <- regmatches(
    text,
    gregexpr("src=\"[^\"]*\\.(png|jpe?g|gif|svg)\"", text,
             ignore.case = TRUE, perl = TRUE)
  )[[1]]
  bad_imgs <- img_srcs[
    !grepl("src=\"@@PLUGINFILE@@/", img_srcs, fixed = TRUE) &
      !grepl("src=\"data:", img_srcs, fixed = TRUE) &
      !grepl("src=\"https?://", img_srcs, perl = TRUE)
  ]
  if (length(bad_imgs) > 0) {
    stop("Image src not resolved to @@PLUGINFILE@@ in ", path, ": ",
         paste(utils::head(bad_imgs, 5), collapse = " | "))
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

max_bytes <- moodle_size_limit(max_size_mb)

cat("MOODLE_XML_GENERATION_BEGIN\n")
cat("Questions directory:", questions_dir, "\n")
cat("Output directory:", out_dir, "\n")
cat("Seed:", seed, "\n")
cat("Variants per question:", n_variants, "\n")
cat("Layout:", layout, "\n")
cat("Max XML size (bytes):", max_bytes, "\n")
cat("Subjects:", length(dirs), "\n")

for (i in seq_along(dirs)) {
  source_dir <- dirs[[i]]
  subject <- relative_dir(source_dir, questions_dir)
  out <- output_for_subject(subject, out_dir, layout, seed)
  source_files <- list.files(source_dir, pattern = "\\.[Rr]nw$", ignore.case = TRUE)

  xml_files <- generate_subject(source_dir, out$dir, out$name, n_variants, seed, max_bytes)
  n_questions <- sum(vapply(xml_files, function(f) validate_xml(f, max_bytes), integer(1)))

  cat(sprintf("[%d/%d] %s -> %d XML part(s)\n",
              i, length(dirs), subject, length(xml_files)))

  rows[[i]] <- data.frame(
    subject = subject,
    source_dir = source_dir,
    xml_file = paste(xml_files, collapse = ";"),
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
  check_each <- unlist(strsplit(manifest$xml_file, ";", fixed = TRUE))
  check_each <- check_each[nzchar(check_each)]
  if (length(check_each) == 0) stop("No generated XML files in manifest")
  if (any(!file.exists(check_each))) stop("Some XML files were not generated")
  if (any(file.size(check_each) > max_bytes)) {
    stop("Some XML files exceed the ", max_bytes, " byte upload limit")
  }
  if (make_zip && !file.exists(zip_file)) stop("Zip was not generated")
}
