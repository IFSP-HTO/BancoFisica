# executar no RStudio

## load package
library(tools)
library("exams")

############### velocidade media ##################
## Definindo a pasta com as questoes do exame
myexam <- dir("../BancoDeQuestoes/vm", pattern = ".rnw", ignore.case=TRUE)
ano <- 12017
## Cria o arquivo .xml para entrada no moodle
set.seed(ano)
exams2moodle(myexam, n = 5, rule="none", schoice = list(shuffle = TRUE), name = paste0("vm-",ano),
             encoding = "UTF-8",
             dir = "../Moodle",
             edir = "../BancoDeQuestoes/vm")

############### exemplos ##################
## Definindo a pasta com as questoes do exame
myexam <- dir("../BancoDeQuestoes/exemplos", pattern = ".rnw", ignore.case=TRUE)
ano <- 12017
## Cria o arquivo .xml para entrada no moodle
set.seed(ano)
exams2moodle(myexam, n = 5, rule="none", schoice = list(shuffle = TRUE), name = paste0("exemplos-",ano),
             encoding = "UTF-8",
             dir = "../Moodle",
             edir = "../BancoDeQuestoes/exemplos")

############### dilatacao ##################
## Definindo a pasta com as questoes do exame
myexam <- dir("../BancoDeQuestoes/dilatterm", pattern = ".rnw", ignore.case=TRUE)
ano <- 12017
## Cria o arquivo .xml para entrada no moodle
set.seed(ano)
exams2moodle(myexam, n = 100, rule="none", schoice = list(shuffle = TRUE), name = paste0("dilatterm-",ano),
             encoding = "UTF-8",
             dir = "../Moodle",
             edir = "../BancoDeQuestoes/dilatterm")
