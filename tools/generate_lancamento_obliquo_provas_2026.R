#!/usr/bin/env Rscript
suppressPackageStartupMessages(library(exams))

args <- commandArgs(trailingOnly = TRUE)
n <- if (length(args)) as.integer(args[[1]]) else 50L
if (is.na(n) || n < 1L) stop("Número de variantes inválido")

out_dir <- "build/lancamento-obliquo-provas-2026"
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

L1 <- "BancoDeQuestoes/cinematica/lancamentos/listas2026/lista1"
L2 <- "BancoDeQuestoes/cinematica/lancamentos/listas2026/lista2"
RS <- "BancoDeQuestoes/cinematica/lancamentos/listas2026/reserva"

sets <- list(
  mecanica = list(
    prefix = "BancoFisica/Listas 2026/Lancamento Obliquo/Mecanica",
    output = "lancamento-obliquo-mecanica.xml",
    strip_images = c(1, 2, 5, 9, 10),
    files = c(
      file.path(L1, "Q09QuizPanossoEstroboscopica.Rnw"),
      file.path(L1, "Q05QuizPUCSPConceitualApice.Rnw"),
      file.path(L1, "Q07QuizUELVelocidadeApice.Rnw"),
      file.path(L1, "Q10QuizSalto45graus10ms.Rnw"),
      file.path(L1, "Q06QuizUERJMassasAlcance.Rnw"),
      file.path(L2, "Q04QuizFESOMesmaAltura.Rnw"),
      file.path(L1, "Q15QuizBalisticaTempo6s.Rnw"),
      file.path(L1, "Q12ClozeFaltaAltura5m.Rnw"),
      file.path(L2, "Q01QuizUFTM2011Volei.Rnw"),
      file.path(L1, "Q14ClozePescaria30graus.Rnw")
    )
  ),
  informatica = list(
    prefix = "BancoFisica/Listas 2026/Lancamento Obliquo/Informatica",
    output = "lancamento-obliquo-informatica.xml",
    strip_images = c(1, 8),
    files = c(
      file.path(L1, "Q13QuizCebolinhaTempoVoo.Rnw"),
      file.path(L1, "Q03ClozeComponentes100ms.Rnw"),
      file.path(L1, "Q02QuizUFT2010AlturaMaxima.Rnw"),
      file.path(L2, "Q07ClozeFutebol108kmh60graus.Rnw"),
      file.path(L1, "Q11ClozeProjetil10msTrig.Rnw"),
      file.path(L1, "Q04ClozeAltura72VelTopo10.Rnw"),
      file.path(L2, "Q14ClozeGoleiroIntercepta18m.Rnw"),
      file.path(L2, "Q12ClozeAltura5Alcance40.Rnw"),
      file.path(L2, "Q13ClozeFlechaH80A240.Rnw"),
      file.path(L2, "Q10ClozeDaianeGrafico.Rnw")
    )
  ),
  automacao = list(
    prefix = "BancoFisica/Listas 2026/Lancamento Obliquo/Automacao",
    output = "lancamento-obliquo-automacao.xml",
    strip_images = c(1, 2, 5, 6, 7, 9),
    files = c(
      file.path(L1, "Q01QuizUEPG2011Conceitos.Rnw"),
      file.path(L2, "Q09ClozePele1970.Rnw"),
      file.path(L2, "Q08ClozeCanhao30e60.Rnw"),
      file.path(RS, "Q10ClozeBasqueteApice05s.Rnw"),
      file.path(RS, "Q09ClozeDebretFlecha45.Rnw"),
      file.path(RS, "Q02ClozeUFOP2010EdificioCorrigida.Rnw"),
      file.path(RS, "Q07QuizObstaculo64m.Rnw"),
      file.path(RS, "Q03ClozeUFU2010Ronaldinho.Rnw"),
      file.path(L2, "Q05ClozeMotocicletaFuscas.Rnw"),
      file.path(RS, "Q06QuizBalistica45Alcance360.Rnw")
    )
  )
)

for (key in names(sets)) {
  s <- sets[[key]]
  if (length(s$files) != 10L) stop(key, ": esperado exatamente 10 questões-base")
  missing <- s$files[!file.exists(s$files)]
  if (length(missing)) stop(key, ": arquivos ausentes: ", paste(missing, collapse = ", "))

  tmp_dir <- file.path(out_dir, paste0(".tmp-", key))
  unlink(tmp_dir, recursive = TRUE)
  dir.create(tmp_dir, recursive = TRUE, showWarnings = FALSE)

  xmls <- character(10)
  for (q in seq_along(s$files)) {
    src <- s$files[[q]]
    edir <- dirname(src)
    f <- basename(src)
    nm <- sprintf("%s-q%02d", key, q)

    set.seed(26092026L + match(key, names(sets)) * 1000L + q)
    exams2moodle(
      file = f,
      n = n,
      rule = "none",
      schoice = list(shuffle = TRUE),
      name = nm,
      encoding = "UTF-8",
      dir = tmp_dir,
      edir = edir,
      converter = "pandoc-mathjax"
    )
    xmls[[q]] <- file.path(tmp_dir, paste0(nm, ".xml"))
    if (!file.exists(xmls[[q]])) stop("Falha ao gerar ", key, " Q", sprintf("%02d", q))
  }

  output <- file.path(out_dir, s$output)
  cmd <- c(
    "tools/assemble_lancamento_obliquo_exam_xml.py",
    "--prefix", shQuote(s$prefix),
    "--expected-variants", as.character(n),
    "--output", shQuote(output),
    "--strip-images", shQuote(paste(s$strip_images, collapse = ",")),
    vapply(seq_along(xmls), function(q) {
      shQuote(paste0(q, "=", xmls[[q]]))
    }, character(1))
  )
  status <- system2("python3", cmd)
  if (status != 0) stop("Falha ao montar XML único para ", key)

  unlink(tmp_dir, recursive = TRUE)
}

cat("XMLs gerados:\n")
for (key in names(sets)) {
  p <- file.path(out_dir, sets[[key]]$output)
  cat(sprintf("  %s (%0.2f MiB)\n", p, file.size(p) / 1024^2))
}
