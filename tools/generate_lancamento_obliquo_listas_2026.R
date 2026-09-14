#!/usr/bin/env Rscript
suppressPackageStartupMessages(library(exams))
source("tools/moodle_xml_split.R")

args <- commandArgs(trailingOnly = TRUE)
n <- if (length(args)) as.integer(args[[1]]) else 20L
if (is.na(n) || n < 1L) stop("Número de variantes inválido")

out_dir <- "build/lancamento-obliquo-listas-2026"
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

sets <- list(
  lista1 = list(
    dir = "BancoDeQuestoes/cinematica/lancamentos/listas2026/lista1",
    name = "lancamento-obliquo-lista1-set2026",
    prefix = "BancoFisica/Listas 2026/Lancamento Obliquo - Lista 1 - Setembro 2026"
  ),
  lista2 = list(
    dir = "BancoDeQuestoes/cinematica/lancamentos/listas2026/lista2",
    name = "lancamento-obliquo-lista2-set2026",
    prefix = "BancoFisica/Listas 2026/Lancamento Obliquo - Lista 2 - Setembro 2026"
  ),
  reserva = list(
    dir = "BancoDeQuestoes/cinematica/lancamentos/listas2026/reserva",
    name = "lancamento-obliquo-reserva-prova-21092026",
    prefix = "BancoFisica/Listas 2026/Lancamento Obliquo - Reserva Prova 21-09-2026"
  )
)

all_xml <- character()
for (key in names(sets)) {
  s <- sets[[key]]
  files <- sort(list.files(s$dir, pattern = "\\.Rnw$", ignore.case = TRUE))
  if (!length(files)) stop("Nenhuma questão encontrada em ", s$dir)
  xml <- generate_moodle_xml_limited(
    files=files, n=n, name=s$name, seed=21092026,
    edir=s$dir, dir=out_dir, encoding="UTF-8", converter="pandoc-mathjax"
  )
  status <- system2(
    "python3",
    c("tools/rewrite_lancamento_obliquo_moodle.py",
      "--prefix", shQuote(s$prefix),
      "--expected-variants", as.character(n), xml)
  )
  if (status != 0) stop("Falha ao pós-processar XML de ", key)
  all_xml <- c(all_xml, xml)
}
cat("Arquivos gerados:\n", paste(all_xml, collapse="\n"), "\n")
