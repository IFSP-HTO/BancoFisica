#!/usr/bin/env Rscript
# BancoFisica - Lista de Hidrostatica do 2o ano: exportacao Moodle
# As questoes provem exclusivamente dos .Rnw do BancoFisica.

args <- commandArgs(trailingOnly = TRUE)
argument <- function(flag, default) {
  i <- match(flag, args)
  if (is.na(i)) return(default)
  if (i >= length(args)) stop("Sem valor para ", flag)
  args[i + 1L]
}
n <- as.integer(argument("--n", "1"))
seed <- as.integer(argument("--seed", "20261113"))
out_dir <- argument("--out-dir", "build/moodle-hidrostatica-lista-2ano")
stopifnot(!is.na(n), n >= 1L, n <= 100L, !is.na(seed))

suppressPackageStartupMessages({
  library(exams)
  library(xml2)
})
source("tools/moodle_xml_split.R")

edir <- "BancoDeQuestoes/hidrostatica"
files <- c(
  "Q03Densidade.Rnw",
  "Q92ClozeDensidadeProveta.Rnw",
  "Q101PressaoContato.Rnw",
  "Q100ClozePressaoAbsoluta.Rnw",
  "Q102GraficoStevin.Rnw",
  "Q103ManometroAberto.Rnw",
  "Q104TuboULiquidos.Rnw",
  "Q105PascalForca.Rnw",
  "Q106PascalDeslocamento.Rnw",
  "Q107EmpuxoVolume.Rnw",
  "Q108PesoAparente.Rnw",
  "Q109ClozeFracaoSubmersa.Rnw"
)
skills <- c(
  "Densidade e conversao de unidades",
  "Densidade por deslocamento de volume",
  "Pressao de contato",
  "Pressao absoluta e manometrica",
  "Grafico pressao x profundidade",
  "Manometro de tubo aberto",
  "Equilibrio em tubo U",
  "Principio de Pascal: forcas",
  "Principio de Pascal: deslocamentos",
  "Principio de Arquimedes: empuxo",
  "Peso aparente",
  "Fracao submersa"
)
stopifnot(length(files) == 12L, length(skills) == length(files),
          !anyDuplicated(files))
missing <- files[!file.exists(file.path(edir, files))]
if (length(missing)) stop("Questao nao encontrada: ", paste(missing, collapse = ", "))

dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
out_dir <- normalizePath(out_dir, winslash = "/", mustWork = TRUE)
old <- list.files(out_dir, pattern = "\\.xml$", full.names = TRUE)
if (length(old)) unlink(old)

xml_files <- generate_moodle_xml_limited(
  files = files, n = n, name = "hidrostatica-lista-2ano",
  seed = seed, edir = edir, dir = out_dir,
  encoding = "UTF-8", converter = "pandoc-mathjax",
  max_bytes = moodle_size_limit(10)
)
# Resolver também as imagens das questões da exportação legada de 12 itens.
code <- system2("python3", c("tools/embed_unresolved_moodle_images.py",
                            shQuote(out_dir), shQuote(edir)))
if (!identical(as.integer(code), 0L)) stop("Falha ao empacotar PNGs no XML")

numbers <- vapply(xml_files, function(path) {
  doc <- xml2::read_xml(path)
  if (xml2::xml_name(xml2::xml_root(doc)) != "quiz")
    stop("XML com raiz incorreta: ", path)
  length(xml2::xml_find_all(doc, "/quiz/question[not(@type = 'category')]"))
}, integer(1))
if (sum(numbers) != length(files) * n)
  stop("XML com contagem incorreta de questoes")
if (any(file.size(xml_files) > moodle_size_limit(10)))
  stop("XML excede limite de 10 MiB")

write.csv(data.frame(position = seq_along(files),
                     source_file = files, skill = skills,
                     variants = n, seed = seed),
          file.path(out_dir, "manifest.csv"),
          row.names = FALSE, fileEncoding = "UTF-8")
writeLines(c(
  "BancoFisica — Lista de Hidrostatica, 2o ano",
  paste("Questoes-base:", length(files)),
  paste("Variantes por questao:", n),
  paste("Questoes no Moodle:", sum(numbers)),
  paste("Seed:", seed),
  "Importe os arquivos XML deste pacote para o Banco de Questoes do Moodle.",
  "O PDF auxiliar nao corresponde a uma exportacao identica destas instancias parametrizadas.",
  paste("Arquivos XML:", paste(basename(xml_files), collapse = ", "))
), file.path(out_dir, "LEIA-ME.txt"), useBytes = TRUE)

cat("XMLs:", paste(xml_files, collapse = ", "), "\n")
cat("Questoes-base:", length(files), "\n")
cat("Questoes importaveis:", sum(numbers), "\n")
cat("Validacao XML: OK\n")
