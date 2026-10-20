#!/usr/bin/env Rscript
suppressPackageStartupMessages(library(exams))

args <- commandArgs(trailingOnly = TRUE)
n <- if (length(args)) as.integer(args[[1]]) else 25L
if (is.na(n) || n < 1L) stop("Número de réplicas inválido")

asset_root <- Sys.getenv("BF_PROVA_FIEL_ASSET_DIR")
if (!nzchar(asset_root)) {
  stop(
    "BF_PROVA_FIEL_ASSET_DIR não definido. ",
    "Este gerador usa as imagens EXATAS extraídas das provas impressas; ",
    "não substitua por imagens canônicas equivalentes do Banco."
  )
}

root <- "BancoDeQuestoes/cinematica/lancamentos/listas2026/provas2026/fieis"
out_dir <- "build/lancamento-obliquo-provas-2026-fieis"
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

sets <- list(
  mecanica = list(prefix="BancoFisica/Listas 2026/Lancamento Obliquo/Mecanica"),
  informatica = list(prefix="BancoFisica/Listas 2026/Lancamento Obliquo/Informatica"),
  automacao = list(prefix="BancoFisica/Listas 2026/Lancamento Obliquo/Automacao")
)

for (key in names(sets)) {
  edir <- file.path(root, key)
  files <- sprintf("Q%02dProvaFiel.Rnw", 1:10)
  missing <- files[!file.exists(file.path(edir, files))]
  if (length(missing)) stop(key, ": Rnw fiéis ausentes: ", paste(missing, collapse=", "))

  # Gera cada Q separadamente para que o pós-processamento preserve Q01...Q10.
  tmp <- file.path(out_dir, paste0(".tmp-", key))
  unlink(tmp, recursive=TRUE)
  dir.create(tmp, recursive=TRUE)
  xmls <- character(10)
  for (q in 1:10) {
    set.seed(20260925L + q + match(key, names(sets))*1000L)
    nm <- sprintf("%s-q%02d", key, q)
    exams2moodle(
      file=files[q], n=n, rule="none",
      schoice=list(shuffle=FALSE),
      name=nm, encoding="UTF-8", dir=tmp, edir=edir,
      converter="pandoc-mathjax"
    )
    xmls[q] <- file.path(tmp, paste0(nm, ".xml"))
  }

  output <- file.path(out_dir, paste0("lancamento-obliquo-", key, "-25-FIEL-A-PROVA.xml"))
  cmd <- c(
    "tools/assemble_lancamento_obliquo_exam_xml.py",
    "--prefix", shQuote(sets[[key]]$prefix),
    "--expected-variants", as.character(n),
    "--output", shQuote(output),
    vapply(seq_along(xmls), function(q) shQuote(paste0(q, "=", xmls[q])), character(1))
  )
  status <- system2("python3", cmd)
  if (status != 0) stop("Falha ao montar XML fiel de ", key)
  unlink(tmp, recursive=TRUE)
}

cat("XMLs fiéis gerados em ", out_dir, "\n", sep="")
