#!/usr/bin/env Rscript
# BancoFisica: exportacao Moodle + PDF de 8 questoes Filatte, com imagens aprovadas.
args <- commandArgs(trailingOnly = TRUE)
getarg <- function(key, default) {
  pos <- match(key,args)
  if (is.na(pos)) return(default)
  if (pos == length(args)) stop("Argumento sem valor: ",key)
  args[pos+1L]
}
n <- as.integer(getarg("--n","3"))
seed <- as.integer(getarg("--seed","20261116"))
outdir <- getarg("--out-dir","build/filatte-hidro-lote1")
stopifnot(!is.na(n),n>=1L,n<=12L,!is.na(seed))
suppressPackageStartupMessages({library(exams);library(xml2)})
source("tools/moodle_xml_split.R")

refs <- c(
  "BancoDeQuestoes/hidrodinamica/Q04QuizFamerp2026FluxoGrafico.Rnw",
  "BancoDeQuestoes/hidrostatica/Q112NumEEAR2025TuboU.Rnw",
  "BancoDeQuestoes/hidrostatica/Q113NumENEM2011DensidadeLago.Rnw",
  "BancoDeQuestoes/hidrostatica/Q114ClozeUFRGS2018VolumeDensidade.Rnw",
  "BancoDeQuestoes/hidrostatica/Q115NumENEM2020DescompressaoGrafico.Rnw",
  "BancoDeQuestoes/hidrostatica/Q116QuizEEAR2020PressaoVasos.Rnw",
  "BancoDeQuestoes/hidrostatica/Q117QuizENEM2019CapilaridadePapel.Rnw",
  "BancoDeQuestoes/hidrostatica/Q118NumUnicamp2019PressaoTemperatura.Rnw"
)
pngs <- c(
  "BancoDeQuestoes/hidrodinamica/Q04Famerp2026GraficoFluxo.png",
  "BancoDeQuestoes/hidrostatica/Q112EEAR2025TuboU.png",
  "BancoDeQuestoes/hidrostatica/Q113ENEM2011Dinamometro.png",
  "BancoDeQuestoes/hidrostatica/Q114UFRGS2018Dinamometros.png",
  "BancoDeQuestoes/hidrostatica/Q115ENEM2020Bolsao.png",
  "BancoDeQuestoes/hidrostatica/Q115ENEM2020Grafico.png",
  "BancoDeQuestoes/hidrostatica/Q116EEAR2020Vasos.png",
  "BancoDeQuestoes/hidrostatica/Q117ENEM2019Capilaridade.png",
  "BancoDeQuestoes/hidrostatica/Q118Unicamp2019Temperatura.png"
)
all <- c(refs,pngs)
if (any(!file.exists(all)))stop("Arquivos ausentes: ",paste(all[!file.exists(all)],collapse=", "))
if (anyDuplicated(basename(all)))stop("Nomes de arquivo conflitantes na area de estagio")
outdir <- normalizePath(outdir,mustWork=FALSE)
stage <- file.path(outdir,"stage")
xmlout <- file.path(outdir,"moodle")
pdfout <- file.path(outdir,"pdf")
dir.create(stage,recursive=TRUE,showWarnings=FALSE)
dir.create(xmlout,recursive=TRUE,showWarnings=FALSE)
dir.create(pdfout,recursive=TRUE,showWarnings=FALSE)
file.copy(all,stage,overwrite=TRUE)
stopifnot(all(file.exists(file.path(stage,basename(all)))))
files <- basename(refs)
set.seed(seed)
xmls <- generate_moodle_xml_limited(
  files=files,n=n,name="filatte-hidro-lote1",seed=seed,
  edir=stage,dir=xmlout,encoding="UTF-8",converter="pandoc-mathjax",
  max_bytes=moodle_size_limit(10)
)
status <- system2("python3",c("tools/embed_unresolved_moodle_images.py",
                              shQuote(xmlout),shQuote(stage)))
if (!identical(as.integer(status),0L)) stop("Nao foi possivel incorporar PNGs no Moodle")
count <- sum(vapply(xmls,function(p){
  doc <- xml2::read_xml(p)
  length(xml2::xml_find_all(doc,"/quiz/question[not(@type='category')]"))
},integer(1)))
if (count != 8L*n)stop("Numero incorreto de questoes no XML: ",count)
if (any(file.size(xmls)>moodle_size_limit(10)))stop("XML excedeu 10 MiB")

set.seed(seed)
exams2pdf(files,n=1,name="filatte-hidro-lote1",encoding="UTF-8",
          dir=pdfout,edir=stage,template="plain8")
pdfs <- list.files(pdfout,pattern="\\.pdf$",full.names=TRUE)
if (!length(pdfs)||any(file.size(pdfs)<1000))stop("Falha ao gerar a previa PDF")
write.csv(data.frame(position=seq_along(files),source=refs,
                     n_variants=n,seed=seed),
          file.path(outdir,"manifest.csv"),row.names=FALSE,fileEncoding="UTF-8")
cat("XML:",paste(xmls,collapse=", "),"\n")
cat("PDF:",paste(pdfs,collapse=", "),"\n")
cat("Questions:",count,"\n")
