# executar no RStudio

## load package
library(tools)
library(exams)

## Limite de upload do Moodle institucional: ~10 MB por arquivo. Quando um
## assunto gera um XML maior, o script divide a saida em partes .xml de ate
## 10 MB cada (logica em tools/moodle_xml_split.R).
source("tools/moodle_xml_split.R")

## Gera o XML do Moodle para um assunto dentro do limite de upload.
## Assuntos cuja pasta nao tem questoes (.Rnw) sao pulados.
gerar_moodle <- function(files, n, name, seed, edir,
                         dir = "./Moodle", encoding = "UTF-8",
                         converter = NULL) {
  files <- files[nzchar(files)]
  if (length(files) == 0L) {
    message("Sem questoes .Rnw em ", name, " - pulado.")
    return(invisible(NULL))
  }
  generate_moodle_xml_limited(
    files = files, n = n, name = name, seed = seed,
    edir = edir, dir = dir, encoding = encoding, converter = converter
  )
}

########Notacao cientifica e ordem de grandeza##################
gerar_moodle(dir("./BancoDeQuestoes/nc_og", pattern = ".rnw", ignore.case = TRUE),
             n = 20, name = "nc_og-12026", seed = 12026,
             edir = "./BancoDeQuestoes/nc_og", converter = "pandoc-mathjax")

############### aceleracao ##################
gerar_moodle(dir("./BancoDeQuestoes/acel", pattern = ".rnw", ignore.case = TRUE),
             n = 100, name = "acel-12026", seed = 12026,
             edir = "./BancoDeQuestoes/acel", converter = "pandoc-mathjax")

############### calorimetria ###############
gerar_moodle(dir("./BancoDeQuestoes/calorimetria", pattern = ".rnw", ignore.case = TRUE),
             n = 100, name = "calorimetria-12018", seed = 12018,
             edir = "./BancoDeQuestoes/calorimetria", converter = "pandoc-mathjax")

############### calortemp ##################
gerar_moodle(dir("./BancoDeQuestoes/calortemp", pattern = ".rnw", ignore.case = TRUE),
             n = 100, name = "calortemp-12018", seed = 12018,
             edir = "./BancoDeQuestoes/calortemp", converter = "pandoc-mathjax")

############### dilatacao #################
gerar_moodle(dir("./BancoDeQuestoes/dilatterm", pattern = ".rnw", ignore.case = TRUE),
             n = 100, name = "dilatterm-12018", seed = 12018,
             edir = "./BancoDeQuestoes/dilatterm", converter = "pandoc-mathjax")

############### eletricidade #################
gerar_moodle(dir("./BancoDeQuestoes/eletricidade", pattern = ".rnw", ignore.case = TRUE),
             n = 100, name = "eletricidade-12018", seed = 12018,
             edir = "./BancoDeQuestoes/eletricidade", converter = "pandoc-mathjax")

############### eletromagnetismo #################
gerar_moodle(dir("./BancoDeQuestoes/eletromagnetismo/eletrostática", pattern = ".rnw", ignore.case = TRUE),
             n = 100, name = "eletromagnetismo-12018", seed = 12018,
             edir = "./BancoDeQuestoes/eletromagnetismo/eletrostática/", converter = "pandoc-mathjax")

############### eletrostatica ##################
gerar_moodle(dir("./BancoDeQuestoes/eletrostatica", pattern = ".rnw", ignore.case = TRUE),
             n = 100, name = "eletrostatica-12018", seed = 12018,
             edir = "./BancoDeQuestoes/eletrostatica", converter = "pandoc-mathjax")

############### energia e conservacao ##################
gerar_moodle(dir("./BancoDeQuestoes/energiaeconservacao", pattern = ".rnw", ignore.case = TRUE),
             n = 100, name = "energiaeconservacao-12026", seed = 12026,
             edir = "./BancoDeQuestoes/energiaeconservacao", converter = "pandoc-mathjax")

############### gravitacao ##################
gerar_moodle(dir("./BancoDeQuestoes/gravitacao", pattern = ".rnw", ignore.case = TRUE),
             n = 100, name = "gravitacao-12018", seed = 12018,
             edir = "./BancoDeQuestoes/gravitacao", converter = "pandoc-mathjax")

############### hidrostatica ##################
gerar_moodle(dir("./BancoDeQuestoes/hidrostatica", pattern = ".rnw", ignore.case = TRUE),
             n = 50, name = "hidrostatica-12019", seed = 12019,
             edir = "./BancoDeQuestoes/hidrostatica", converter = "pandoc-mathjax")

############### impulso ##################
gerar_moodle(dir("./BancoDeQuestoes/impulso", pattern = ".rnw", ignore.case = TRUE),
             n = 100, name = "impulso-12018", seed = 12018,
             edir = "./BancoDeQuestoes/impulso")

############### lei dos gases ##################
gerar_moodle(dir("./BancoDeQuestoes/leidosgases", pattern = ".rnw", ignore.case = TRUE),
             n = 100, name = "leidosgases-12018", seed = 12018,
             edir = "./BancoDeQuestoes/leidosgases")

############leis de newton - atrito##############
gerar_moodle(dir("./BancoDeQuestoes/leisdenewton/atrito", pattern = ".rnw", ignore.case = TRUE),
             n = 100, name = "leisdenewton-12018", seed = 12018,
             edir = "./BancoDeQuestoes/leisdenewton")

############### magnetismo ##################
gerar_moodle(dir("./BancoDeQuestoes/magnetismo", pattern = ".rnw", ignore.case = TRUE),
             n = 100, name = "magnetismo-12018", seed = 12018,
             edir = "./BancoDeQuestoes/magnetismo")

############### movimento circular ##################
gerar_moodle(dir("./BancoDeQuestoes/movcircular", pattern = ".rnw", ignore.case = TRUE),
             n = 100, name = "movcircular-12018", seed = 12018,
             edir = "./BancoDeQuestoes/movcircular")

############### MRU ##################
gerar_moodle(dir("./BancoDeQuestoes/mru", pattern = ".rnw", ignore.case = TRUE),
             n = 100, name = "mru-12026", seed = 12026,
             edir = "./BancoDeQuestoes/mru")

############### MRUV ##################
gerar_moodle(dir("./BancoDeQuestoes/mruv", pattern = ".rnw", ignore.case = TRUE),
             n = 100, name = "mruv-12026", seed = 12026,
             edir = "./BancoDeQuestoes/mruv")

############### ondas ##################
gerar_moodle(dir("./BancoDeQuestoes/ondas", pattern = ".rnw", ignore.case = TRUE),
             n = 100, name = "ondas-12018", seed = 12018,
             edir = "./BancoDeQuestoes/ondas")

############### optica ##################
gerar_moodle(dir("./BancoDeQuestoes/optica", pattern = ".rnw", ignore.case = TRUE),
             n = 100, name = "optica-12018", seed = 12018,
             edir = "./BancoDeQuestoes/optica")

############### termodinamica ##################
gerar_moodle(dir("./BancoDeQuestoes/termodinamica", pattern = ".rnw", ignore.case = TRUE),
             n = 100, name = "termodinamica-12018", seed = 12018,
             edir = "./BancoDeQuestoes/termodinamica")

############### trabalho e potencia ##################
gerar_moodle(dir("./BancoDeQuestoes/trabalhopotencia", pattern = ".rnw", ignore.case = TRUE),
             n = 100, name = "trabalhopotencia-12026", seed = 12026,
             edir = "./BancoDeQuestoes/trabalhopotencia")

################## MU ####################
gerar_moodle(dir("./BancoDeQuestoes/cinematica/MU", pattern = ".rnw", ignore.case = TRUE),
             n = 50, name = "MU-12026", seed = 12026,
             edir = "./BancoDeQuestoes/cinematica/MU")

############### estatica do corpo extenso ##################
gerar_moodle(dir("./BancoDeQuestoes/estatica", pattern = ".rnw", ignore.case = TRUE),
             n = 100, name = "estatica-12018", seed = 12018,
             edir = "./BancoDeQuestoes/estatica")