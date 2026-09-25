#!/usr/bin/env Rscript
suppressPackageStartupMessages(library(exams))

args <- commandArgs(trailingOnly = TRUE)
n <- if (length(args)) as.integer(args[[1]]) else 25L
if (is.na(n) || n < 1L) stop("Número de réplicas inválido")

out_dir <- "build/lancamento-obliquo-provas-2026"
source_root <- "BancoDeQuestoes/cinematica/lancamentos/provas2026_fieis"
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

sets <- list(
  mecanica = list(
    dir = file.path(source_root, "mecanica"),
    name = "lancamento-obliquo-mecanica",
    prefix = "BancoFisica/Listas 2026/Lancamento Obliquo/Mecanica"
  ),
  informatica = list(
    dir = file.path(source_root, "informatica"),
    name = "lancamento-obliquo-informatica",
    prefix = "BancoFisica/Listas 2026/Lancamento Obliquo/Informatica"
  ),
  automacao = list(
    dir = file.path(source_root, "automacao"),
    name = "lancamento-obliquo-automacao",
    prefix = "BancoFisica/Listas 2026/Lancamento Obliquo/Automacao"
  )
)

for (key in names(sets)) {
  s <- sets[[key]]
  files <- sprintf("Q%02d.Rnw", seq_len(10))
  full <- file.path(s$dir, files)
  missing <- full[!file.exists(full)]
  if (length(missing)) stop(key, ": fontes fiéis ausentes: ", paste(missing, collapse = ", "))

  # As alternativas A--E já aparecem na ordem correta dentro do recorte fiel.
  # Portanto o seletor Moodle NUNCA pode ser embaralhado.
  set.seed(26092026L + match(key, names(sets)) * 1000L)
  exams2moodle(
    file = files,
    n = n,
    rule = "none",
    schoice = list(shuffle = FALSE),
    name = s$name,
    encoding = "UTF-8",
    dir = out_dir,
    edir = s$dir,
    converter = "pandoc-mathjax"
  )

  xml <- file.path(out_dir, paste0(s$name, ".xml"))
  status <- system2(
    "python3",
    c(
      "tools/rewrite_lancamento_obliquo_moodle.py",
      "--prefix", shQuote(s$prefix),
      "--expected-variants", as.character(n),
      shQuote(xml)
    )
  )
  if (status != 0) stop("Falha ao pós-processar XML fiel de ", key)
  if (!file.exists(xml)) stop("XML não gerado para ", key)
  if (file.size(xml) > 10 * 1024^2) {
    stop(key, ": XML fiel excede 10 MiB (",
         sprintf("%.2f", file.size(xml) / 1024^2), " MiB)")
  }
}

cat("XMLs fiéis gerados:\n")
for (key in names(sets)) {
  p <- file.path(out_dir, paste0(sets[[key]]$name, ".xml"))
  cat(sprintf("  %s: %d réplicas/Q, %d itens (%0.2f MiB)\n",
              p, n, 10L * n, file.size(p) / 1024^2))
}
