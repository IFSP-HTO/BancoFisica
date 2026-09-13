#!/usr/bin/env Rscript

suppressPackageStartupMessages(library(exams))
source("tools/moodle_xml_split.R")

out_dir <- "build/lancamento-obliquo-listas-2026"
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

sets <- list(
  lista1 = list(
    dir = "BancoDeQuestoes/cinematica/lancamentos/listas2026/lista1",
    name = "lancamento-obliquo-lista1-set2026",
    category = "BancoFisica/Listas 2026/Lancamento Obliquo - Lista 1 - Setembro 2026"
  ),
  lista2 = list(
    dir = "BancoDeQuestoes/cinematica/lancamentos/listas2026/lista2",
    name = "lancamento-obliquo-lista2-set2026",
    category = "BancoFisica/Listas 2026/Lancamento Obliquo - Lista 2 - Setembro 2026"
  ),
  reserva = list(
    dir = "BancoDeQuestoes/cinematica/lancamentos/listas2026/reserva",
    name = "lancamento-obliquo-reserva-prova-21092026",
    category = "BancoFisica/Listas 2026/Lancamento Obliquo - Reserva Prova 21-09-2026"
  )
)

rewrite_xml <- function(path, category) {
  x <- readLines(path, warn = FALSE, encoding = "UTF-8")

  # Todas as categorias emitidas por exams2moodle neste pacote passam para a
  # categoria exclusiva da lista/reserva. Isto impede mistura com a categoria
  # historica de lancamento obliquo do banco.
  x <- sub(
    "<text>\\$course\\$/[^<]+</text>",
    paste0("<text>$course$/", category, "</text>"),
    x,
    perl = TRUE
  )

  # Nome visivel no Moodle: exatamente Q01, Q02, ... (sem R001, sem titulo).
  q_counter <- 0L
  for (i in seq_along(x)) {
    if (grepl("<text>[[:space:]]*R[0-9]+[[:space:]]+Q[0-9]+[[:space:]]*:", x[i], perl = TRUE)) {
      q_counter <- q_counter + 1L
      x[i] <- sub(
        "<text>[[:space:]]*R[0-9]+[[:space:]]+Q[0-9]+[[:space:]]*:[^<]*</text>",
        sprintf("<text>Q%02d</text>", q_counter),
        x[i], perl = TRUE
      )
    }
  }

  writeLines(x, path, useBytes = TRUE)
  invisible(path)
}

all_xml <- character()
for (key in names(sets)) {
  s <- sets[[key]]
  files <- sort(list.files(s$dir, pattern = "\\.Rnw$", ignore.case = TRUE))
  if (!length(files)) stop("Nenhuma questao encontrada em ", s$dir)

  xml <- generate_moodle_xml_limited(
    files = files,
    n = 1L,
    name = s$name,
    seed = 21092026,
    edir = s$dir,
    dir = out_dir,
    encoding = "UTF-8",
    converter = "pandoc-mathjax"
  )
  invisible(lapply(xml, rewrite_xml, category = s$category))
  all_xml <- c(all_xml, xml)
}

cat("Arquivos gerados:\n", paste(all_xml, collapse = "\n"), "\n")
