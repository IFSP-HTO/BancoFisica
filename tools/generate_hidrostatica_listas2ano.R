#!/usr/bin/env Rscript
# BancoFisica: duas listas de Fisica dos Fluidos (2o ano), de acordo
# com os slides Hidrostatica.pdf (56 paginas). Fontes = .Rnw do banco.
# Produz XML Moodle independente para cada lista, com validacao estrutural.

args <- commandArgs(trailingOnly = TRUE)
argument <- function(flag, default) {
  i <- match(flag, args)
  if (is.na(i)) return(default)
  if (i == length(args)) stop("Falta valor para ", flag)
  args[i + 1L]
}
n <- as.integer(argument("--n", "1"))
seed <- as.integer(argument("--seed", "20261113"))
out_dir <- argument("--out-dir", "build/moodle-hidrostatica-listas-2ano")
if (is.na(n) || n < 1L || n > 100L) stop("--n deve estar entre 1 e 100")
if (is.na(seed)) stop("--seed deve ser inteiro")

suppressPackageStartupMessages({
  library(exams)
  library(xml2)
})
source("tools/moodle_xml_split.R")

hidro <- "BancoDeQuestoes/hidrostatica"
dinam <- "BancoDeQuestoes/hidrodinamica"

lista1 <- c(
  "Q03Densidade.Rnw",
  "Q92ClozeDensidadeProveta.Rnw",
  "Q110QuizTensaoSuperficial.Rnw",
  "Q111QuizCapilaridade.Rnw",
  "Q101PressaoContato.Rnw",
  "Q07LeiStevin.Rnw",
  "Q100ClozePressaoAbsoluta.Rnw",
  "Q102GraficoStevin.Rnw",
  "Q104TuboULiquidos.Rnw",
  "Q103ManometroAberto.Rnw"
)
lista2_hidro <- c(
  "Q105PascalForca.Rnw",
  "Q106PascalDeslocamento.Rnw",
  "Q93QuizDensidadeFlutuacao.Rnw",
  "Q05Densidade.Rnw",
  "Q107EmpuxoVolume.Rnw",
  "Q108PesoAparente.Rnw",
  "Q109ClozeFracaoSubmersa.Rnw"
)
lista2_dinam <- c("Q02ClozeContinuidadeVazao.Rnw",
                   "Q03ClozeBernoulliReservatorio.Rnw")

listas <- list(
  lista1 = list(
    sources = file.path(hidro, lista1),
    figures = file.path(hidro, "Q07LeiStevin.png"),
    subjects = c("Densidade e unidades", "Proveta",
      "Tensao superficial", "Capilaridade", "Pressao F/A",
      "Stevin e pressao absoluta", "Pressao manometrica e absoluta",
      "Grafico p x h", "Vasos comunicantes", "Manometro")
  ),
  lista2 = list(
    sources = c(file.path(hidro, lista2_hidro),
                file.path(dinam, lista2_dinam)),
    figures = file.path(hidro, "Q05Densidade.png"),
    subjects = c("Pascal: forcas", "Pascal: deslocamentos",
      "Flutuacao", "Afundar ou flutuar", "Empuxo",
      "Peso aparente", "Fracao submersa", "Continuidade e vazao",
      "Bernoulli e vazao")
  )
)
if (length(listas$lista1$sources) != 10L ||
    length(listas$lista2$sources) != 9L) stop("Contagem de modelos incorreta")
if (anyDuplicated(unlist(lapply(listas, function(x) x$sources))))
  stop("Questao repetida entre as duas listas")

dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
out_dir <- normalizePath(out_dir, winslash = "/", mustWork = TRUE)

for (nome in names(listas)) {
  cfg <- listas[[nome]]
  files <- cfg$sources
  missing <- c(files, cfg$figures)
  missing <- missing[!file.exists(missing)]
  if (length(missing)) stop("Fontes ausentes em ", nome, ": ",
                            paste(missing, collapse = ", "))
  if (anyDuplicated(basename(files))) stop("Nomes duplicados em ", nome)
  if (length(cfg$subjects) != length(files)) stop("Assuntos incompletos")

  # Estagio temporario: o exams2moodle espera que o .Rnw e figuras
  # suplementares estejam no mesmo diretorio 'edir'. Assim e possivel
  # combinar hidrostatica e hidrodinamica sem duplicar fontes no Git.
  edir <- file.path(out_dir, paste0("_stage_", nome))
  dest <- file.path(out_dir, nome)
  if (dir.exists(edir)) unlink(edir, recursive = TRUE)
  if (dir.exists(dest)) unlink(dest, recursive = TRUE)
  dir.create(edir, recursive = TRUE)
  dir.create(dest, recursive = TRUE)

  to_copy <- c(files, cfg$figures)
  copied <- file.copy(to_copy, edir, overwrite = FALSE)
  if (!all(copied)) stop("Falha ao copiar fontes para ", nome)

  xmls <- generate_moodle_xml_limited(
    files = basename(files), n = n,
    name = paste0("hidrostatica-", nome, "-2ano"),
    seed = seed + match(nome, names(listas)) - 1L,
    edir = edir, dir = dest,
    encoding = "UTF-8", converter = "pandoc-mathjax",
    max_bytes = moodle_size_limit(10)
  )
  counts <- vapply(xmls, function(f) {
    doc <- xml2::read_xml(f)
    if (xml2::xml_name(xml2::xml_root(doc)) != "quiz")
      stop("Raiz XML invalida: ", f)
    length(xml2::xml_find_all(doc,
      "/quiz/question[not(@type = 'category')]"))
  }, integer(1))
  if (sum(counts) != n * length(files))
    stop("Numero de questoes Moodle incorreto em ", nome)
  if (any(file.size(xmls) > moodle_size_limit(10)))
    stop("XML acima de 10 MiB em ", nome)

  write.csv(data.frame(
    position = seq_along(files), source_file = files,
    assunto = cfg$subjects, variants = n, seed = seed,
    stringsAsFactors = FALSE
  ), file.path(dest, "manifest.csv"), row.names = FALSE,
  fileEncoding = "UTF-8")
  writeLines(c(
    paste("BancoFisica -", nome, "- Fisica dos Fluidos - 2o ano"),
    paste("Questoes-base:", length(files)),
    paste("Versoes por questao:", n),
    paste("Total importavel:", sum(counts)),
    "Importe somente os arquivos .xml desta pasta no banco de questoes do Moodle.",
    "Os .Rnw originais permanecem no BancoDeQuestoes; nao importar a pasta de estagio.",
    paste("XML:", paste(basename(xmls), collapse = ", "))
  ), file.path(dest, "LEIA-ME.txt"), useBytes = TRUE)
  cat("Lista:", nome, "bases:", length(files),
      "itens:", sum(counts), "XMLs:", paste(xmls, collapse = ", "), "\n")
}
cat("VALIDACAO DE AMBAS AS LISTAS: OK\n")
