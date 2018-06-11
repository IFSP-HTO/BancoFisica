# executar no RStudio

## load package
library(tools)
library(exams)

############### aceleracao ##################
## Definindo a pasta com as questoes do exame
myexam <- dir("./BancoDeQuestoes/acel", pattern = ".rnw", ignore.case=TRUE)
ano <- 12018
## Cria o arquivo .xml para entrada no moodle
set.seed(ano)
exams2moodle(myexam, n = 100, rule="none", 
             schoice = list(shuffle = TRUE), 
             converter = "pandoc-mathjax",
             name = paste0("acel-",ano),
             encoding = "UTF-8",
             dir = "./Moodle",
             edir = "./BancoDeQuestoes/acel")

############### calorimetria ###############
## Definindo a pasta com as questoes do exame
myexam <- dir("./BancoDeQuestoes/calorimetria", pattern = ".rnw", ignore.case=TRUE)
ano <- 12018
## Cria o arquivo .xml para entrada no moodle
set.seed(ano)
exams2moodle(myexam, n = 100, rule="none", 
             schoice = list(shuffle = TRUE), 
             name = paste0("calorimetria-",ano),
             encoding = "UTF-8",
             converter = "pandoc-mathjax",
             dir = "./Moodle",
             edir = "./BancoDeQuestoes/calorimetria")

############### calortemp ##################
## Definindo a pasta com as questoes do exame
myexam <- dir("./BancoDeQuestoes/calortemp", pattern = ".rnw", ignore.case=TRUE)
ano <- 12018
## Cria o arquivo .xml para entrada no moodle
set.seed(ano)
exams2moodle(myexam, n = 100, rule="none", 
             schoice = list(shuffle = TRUE), 
             name = paste0("calortemp-",ano),
             encoding = "UTF-8",
             converter = "pandoc-mathjax",
             dir = "./Moodle",
             edir = "./BancoDeQuestoes/calortemp")

############### dilatacao #################
## Definindo a pasta com as questoes do exame
myexam <- dir("./BancoDeQuestoes/dilatterm", pattern = ".rnw", ignore.case=TRUE)
ano <- 12018
## Cria o arquivo .xml para entrada no moodle
set.seed(ano)
exams2moodle(myexam, n = 100, rule="none", 
             schoice = list(shuffle = TRUE), 
             name = paste0("dilatterm-",ano),
             encoding = "UTF-8",
             converter = "pandoc-mathjax",
             dir = "./Moodle",
             edir = "./BancoDeQuestoes/dilatterm")


############### eletricidade #################
## Definindo a pasta com as questoes do exame
myexam <- dir("./BancoDeQuestoes/eletricidade", pattern = ".rnw", ignore.case=TRUE)
ano <- 12018
## Cria o arquivo .xml para entrada no moodle
set.seed(ano)
exams2moodle(myexam, n = 100, rule="none", 
             schoice = list(shuffle = TRUE), 
             name = paste0("eletricidade-",ano),
             encoding = "UTF-8",
             converter = "pandoc-mathjax",
             dir = "./Moodle",
             edir = "./BancoDeQuestoes/eletricidade")

############### eletromagnetismo #################
## Definindo a pasta com as questoes do exame
myexam <- dir("./BancoDeQuestoes/eletromagnetismo", pattern = ".rnw", ignore.case=TRUE)
ano <- 12018
## Cria o arquivo .xml para entrada no moodle
set.seed(ano)
exams2moodle(myexam, n = 100, rule="none", 
             schoice = list(shuffle = TRUE), 
             name = paste0("eletromagnetismo-",ano),
             encoding = "UTF-8",
             converter = "pandoc-mathjax",
             dir = "./Moodle",
             edir = "./BancoDeQuestoes/eletromagnetismo")

############### eletrostatica ##################
## Definindo a pasta com as questoes do exame
myexam <- dir("./BancoDeQuestoes/eletrostatica", pattern = ".rnw", ignore.case=TRUE)
ano <- 12018
## Cria o arquivo .xml para entrada no moodle
set.seed(ano)
exams2moodle(myexam, n = 100, rule="none", 
             schoice = list(shuffle = TRUE), 
             name = paste0("eletrostatica-",ano),
             encoding = "UTF-8",
             converter = "pandoc-mathjax",
             dir = "./Moodle",
             edir = "./BancoDeQuestoes/eletrostatica")

############### energia e conservacao ##################
## Definindo a pasta com as questoes do exame
myexam <- dir("./BancoDeQuestoes/energiaeconservacao", pattern = ".rnw", ignore.case=TRUE)
ano <- 12018
## Cria o arquivo .xml para entrada no moodle
set.seed(ano)
exams2moodle(myexam, n = 100, rule="none", 
             schoice = list(shuffle = TRUE), 
             name = paste0("energiaeconservacao-",ano),
             encoding = "UTF-8",
             converter = "pandoc-mathjax",
             dir = "./Moodle",
             edir = "./BancoDeQuestoes/energiaeconservacao")

############### gravitacao ##################
## Definindo a pasta com as questoes do exame
myexam <- dir("./BancoDeQuestoes/gravitacao", pattern = ".rnw", ignore.case=TRUE)
ano <- 12018
## Cria o arquivo .xml para entrada no moodle
set.seed(ano)
exams2moodle(myexam, n = 100, rule="none", 
             schoice = list(shuffle = TRUE), 
             name = paste0("gravitacao-",ano),
             encoding = "UTF-8",
             converter = "pandoc-mathjax",
             dir = "./Moodle",
             edir = "./BancoDeQuestoes/gravitacao")


############### hidrostatica ##################
## Definindo a pasta com as questoes do exame
myexam <- dir("./BancoDeQuestoes/hidrostatica", pattern = ".rnw", ignore.case=TRUE)
ano <- 12018
## Cria o arquivo .xml para entrada no moodle
set.seed(ano)
exams2moodle(myexam[1:5], n = 100, 
             converter = "pandoc-mathjax",
             rule="none", 
             schoice = list(shuffle = TRUE), 
             name = paste0("hidrostatica-",ano),
             encoding = "UTF-8",
             dir = "./Moodle",
             edir = "./BancoDeQuestoes/hidrostatica")
exams2moodle(myexam[6], n = 100, 
             converter = "pandoc-mathjax",
             rule="none", schoice = list(shuffle = TRUE), 
             name = paste0("hidrostatica2-",ano),
             encoding = "UTF-8",
             dir = "./Moodle",
             edir = "./BancoDeQuestoes/hidrostatica")
exams2moodle(myexam[7], n = 100, 
             converter = "pandoc-mathjax",
             rule="none", schoice = list(shuffle = TRUE), 
             name = paste0("hidrostatica3-",ano),
             encoding = "UTF-8",
             dir = "./Moodle",
             edir = "./BancoDeQuestoes/hidrostatica")
exams2moodle(myexam[8:9], n = 100, 
             converter = "pandoc-mathjax",
             rule="none", schoice = list(shuffle = TRUE), 
             name = paste0("hidrostatica4-",ano),
             encoding = "UTF-8",
             dir = "./Moodle",
             edir = "./BancoDeQuestoes/hidrostatica")
exams2moodle(myexam[10], n = 50, 
             converter = "pandoc-mathjax",
             rule="none", schoice = list(shuffle = TRUE), 
             name = paste0("hidrostatica5-",ano),
             encoding = "UTF-8",
             dir = "./Moodle",
             edir = "./BancoDeQuestoes/hidrostatica")

############### impulso ##################
## Definindo a pasta com as questoes do exame
myexam <- dir("./BancoDeQuestoes/impulso", pattern = ".rnw", ignore.case=TRUE)
ano <- 12018
## Cria o arquivo .xml para entrada no moodle
set.seed(ano)
exams2moodle(myexam, n = 100, rule="none", schoice = list(shuffle = TRUE), name = paste0("impulso-",ano),
             encoding = "UTF-8",
             dir = "./Moodle",
             edir = "./BancoDeQuestoes/impulso")

############### lei dos gases ##################
## Definindo a pasta com as questoes do exame
myexam <- dir("./BancoDeQuestoes/leidosgases", pattern = ".rnw", ignore.case=TRUE)
ano <- 12018
## Cria o arquivo .xml para entrada no moodle
set.seed(ano)
exams2moodle(myexam, n = 100, rule="none", schoice = list(shuffle = TRUE), name = paste0("leidosgases-",ano),
             encoding = "UTF-8",
             dir = "./Moodle",
             edir = "./BancoDeQuestoes/leidosgases")

############### leis de newton ##################
## Definindo a pasta com as questoes do exame
myexam <- dir("./BancoDeQuestoes/leisdenewton", pattern = ".rnw", ignore.case=TRUE)
ano <- 12018
## Cria o arquivo .xml para entrada no moodle
set.seed(ano)
exams2moodle(myexam, n = 100, rule="none", schoice = list(shuffle = TRUE), name = paste0("leisdenewton-",ano),
             encoding = "UTF-8",
             dir = "./Moodle",
             edir = "./BancoDeQuestoes/leisdenewton")

############### magnetismo ##################
## Definindo a pasta com as questoes do exame
myexam <- dir("./BancoDeQuestoes/magnetismo", pattern = ".rnw", ignore.case=TRUE)
ano <- 12018
## Cria o arquivo .xml para entrada no moodle
set.seed(ano)
exams2moodle(myexam, n = 100, rule="none", schoice = list(shuffle = TRUE), name = paste0("magnetismo-",ano),
             encoding = "UTF-8",
             dir = "./Moodle",
             edir = "./BancoDeQuestoes/magnetismo")

############### movimento circular ##################
## Definindo a pasta com as questoes do exame
myexam <- dir("./BancoDeQuestoes/movcircular", pattern = ".rnw", ignore.case=TRUE)
ano <- 12018
## Cria o arquivo .xml para entrada no moodle
set.seed(ano)
exams2moodle(myexam, n = 100, rule="none", schoice = list(shuffle = TRUE), name = paste0("movcircular-",ano),
             encoding = "UTF-8",
             dir = "./Moodle",
             edir = "./BancoDeQuestoes/movcircular")

############### MRU ##################
## Definindo a pasta com as questoes do exame
myexam <- dir("./BancoDeQuestoes/mru", pattern = ".rnw", ignore.case=TRUE)
ano <- 12018
## Cria o arquivo .xml para entrada no moodle
set.seed(ano)
exams2moodle(myexam, n = 100, rule="none", schoice = list(shuffle = TRUE), name = paste0("mru-",ano),
             encoding = "UTF-8",
             dir = "./Moodle",
             edir = "./BancoDeQuestoes/mru")

############### MRUV ##################
## Definindo a pasta com as questoes do exame
myexam <- dir("./BancoDeQuestoes/mruv", pattern = ".rnw", ignore.case=TRUE)
ano <- 12018
## Cria o arquivo .xml para entrada no moodle
set.seed(ano)
exams2moodle(myexam, n = 100, rule="none", schoice = list(shuffle = TRUE), name = paste0("mruv-",ano),
             encoding = "UTF-8",
             dir = "./Moodle",
             edir = "./BancoDeQuestoes/mruv")


############### ondas ##################
## Definindo a pasta com as questoes do exame
myexam <- dir("./BancoDeQuestoes/ondas", pattern = ".rnw", ignore.case=TRUE)
ano <- 12018
## Cria o arquivo .xml para entrada no moodle
set.seed(ano)
exams2moodle(myexam, n = 100, rule="none", schoice = list(shuffle = TRUE), name = paste0("ondas-",ano),
             encoding = "UTF-8",
             dir = "./Moodle",
             edir = "./BancoDeQuestoes/ondas")

############### optica ##################
## Definindo a pasta com as questoes do exame
myexam <- dir("./BancoDeQuestoes/optica", pattern = ".rnw", ignore.case=TRUE)
ano <- 12018
## Cria o arquivo .xml para entrada no moodle
set.seed(ano)
exams2moodle(myexam, n = 100, rule="none", schoice = list(shuffle = TRUE), name = paste0("optica-",ano),
             encoding = "UTF-8",
             dir = "./Moodle",
             edir = "./BancoDeQuestoes/optica")

############### termodinamica ##################
## Definindo a pasta com as questoes do exame
myexam <- dir("./BancoDeQuestoes/termodinamica", pattern = ".rnw", ignore.case=TRUE)
ano <- 12018
## Cria o arquivo .xml para entrada no moodle
set.seed(ano)
exams2moodle(myexam, n = 100, rule="none", schoice = list(shuffle = TRUE), name = paste0("termodinamica-",ano),
             encoding = "UTF-8",
             dir = "./Moodle",
             edir = "./BancoDeQuestoes/termodinamica")

############### trabalho e potencia ##################
## Definindo a pasta com as questoes do exame
myexam <- dir("./BancoDeQuestoes/trabalhopotencia", pattern = ".rnw", ignore.case=TRUE)
ano <- 12018
## Cria o arquivo .xml para entrada no moodle
set.seed(ano)
exams2moodle(myexam, n = 100, rule="none", schoice = list(shuffle = TRUE), name = paste0("trabalhopotencia-",ano),
             encoding = "UTF-8",
             dir = "./Moodle",
             edir = "./BancoDeQuestoes/trabalhopotencia")

################## MU ####################
## Definindo a pasta com as questoes do exame
myexam <- dir("./BancoDeQuestoes/cinematica/MU", pattern = ".rnw", ignore.case=TRUE)
ano <- 12018
## Cria o arquivo .xml para entrada no moodle
set.seed(ano)
exams2moodle(myexam, n = 100, rule="none", schoice = list(shuffle = TRUE), name = paste0("MU-",ano),
             encoding = "UTF-8",
             dir = "./Moodle",
             edir = "./BancoDeQuestoes/cinematica/MU")

############### estatica do corpo extenso ##################
## Definindo a pasta com as questoes do exame
myexam <- dir("./BancoDeQuestoes/estatica", pattern = ".rnw", ignore.case=TRUE)
ano <- 12018
## Cria o arquivo .xml para entrada no moodle
set.seed(ano)
exams2moodle(myexam, n = 100, rule="none", schoice = list(shuffle = TRUE), name = paste0("estatica-",ano),
             encoding = "UTF-8",
             dir = "./Moodle",
             edir = "./BancoDeQuestoes/estatica")


