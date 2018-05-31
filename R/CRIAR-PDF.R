## Carregando os pacotes necessarios
library(tools)
library(exams)

################# exemplos ####################
## Definindo a pasta com as questoes do exame
assunto = "exemplos"
myexam <- dir(paste0("./BancoDeQuestoes/",assunto), pattern = ".rnw", ignore.case=TRUE)
## Gerando HTML com o arquivo da questao
set.seed(12018)
exams2pdf(myexam, n = 1,
          name=assunto,
          dir=paste0("./BancoDeQuestoes/",assunto),
          encoding = "UTF-8",
          edir = paste0("./BancoDeQuestoes/",assunto),
          template = "plain8")

############### aceleracao media ##################
## Definindo a pasta com as questoes do exame
assunto = "acel"
myexam <- dir(paste0("./BancoDeQuestoes/",assunto), pattern = ".rnw", ignore.case=TRUE)
## Gerando HTML com o arquivo da questao
set.seed(12018)
exams2pdf(myexam, n = 1,
          name=assunto,
          dir=paste0("./BancoDeQuestoes/",assunto),
          encoding = "UTF-8",
          edir = paste0("./BancoDeQuestoes/",assunto),
          template = "plain8")

############### calorimetria ##################
## Definindo a pasta com as questoes do exame
assunto = "calorimetria"
myexam <- dir(paste0("./BancoDeQuestoes/",assunto), pattern = ".rnw", ignore.case=TRUE)
## Gerando HTML com o arquivo da questao
set.seed(12018)
exams2pdf(myexam, n = 1,
          name=assunto,
          dir=paste0("./BancoDeQuestoes/",assunto),
          encoding = "UTF-8",
          edir = paste0("./BancoDeQuestoes/",assunto),
          template = "plain8")

############### calor e temperatura ##################
## Definindo a pasta com as questoes do exame
assunto = "calortemp"
myexam <- dir(paste0("./BancoDeQuestoes/",assunto), pattern = ".rnw", ignore.case=TRUE)
## Gerando HTML com o arquivo da questao
set.seed(12018)
exams2pdf(myexam, n = 1,
          name=assunto,
          dir=paste0("./BancoDeQuestoes/",assunto),
          encoding = "UTF-8",
          edir = paste0("./BancoDeQuestoes/",assunto),
          template = "plain8")

############### dilatacao termica ##################
## Definindo a pasta com as questoes do exame
assunto = "dilatterm"
myexam <- dir(paste0("./BancoDeQuestoes/",assunto), pattern = ".rnw", ignore.case=TRUE)
## Gerando HTML com o arquivo da questao
set.seed(12018)
exams2pdf(myexam, n = 1,
          name=assunto,
          dir=paste0("./BancoDeQuestoes/",assunto),
          encoding = "UTF-8",
          edir = paste0("./BancoDeQuestoes/",assunto),
          template = "plain8")

############### eletricidade ########################
## Definindo a pasta com as questoes do exame
assunto = "eletricidade"
myexam <- dir(paste0("./BancoDeQuestoes/",assunto), pattern = ".rnw", ignore.case=TRUE)
## Gerando HTML com o arquivo da questao
set.seed(12018)
exams2pdf(myexam, n = 1,
          name=assunto,
          dir=paste0("./BancoDeQuestoes/",assunto),
          encoding = "UTF-8",
          edir = paste0("./BancoDeQuestoes/",assunto),
          template = "plain8")

################# eletromagnetismo ####################
## Definindo a pasta com as questoes do exame
assunto = "eletromagnetismo"
myexam <- dir(paste0("./BancoDeQuestoes/",assunto), pattern = ".rnw", ignore.case=TRUE)
## Gerando HTML com o arquivo da questao
set.seed(12018)
exams2pdf(myexam, n = 1,
          name=assunto,
          dir=paste0("./BancoDeQuestoes/",assunto),
          encoding = "UTF-8",
          edir = paste0("./BancoDeQuestoes/",assunto),
          template = "plain8")

################### eletrostatica ######################
## Definindo a pasta com as questoes do exame
assunto = "eletrostatica"
myexam <- dir(paste0("./BancoDeQuestoes/",assunto), pattern = ".rnw", ignore.case=TRUE)
## Gerando HTML com o arquivo da questao
set.seed(12018)
exams2pdf(myexam, n = 1,
          name=assunto,
          dir=paste0("./BancoDeQuestoes/",assunto),
          encoding = "UTF-8",
          edir = paste0("./BancoDeQuestoes/",assunto),
          template = "plain8")

##############energia e conservacao###################
## Definindo a pasta com as questoes do exame
assunto = "energiaeconservacao"
myexam <- dir(paste0("./BancoDeQuestoes/",assunto), pattern = ".rnw", ignore.case=TRUE)
## Gerando HTML com o arquivo da questao
set.seed(12018)
exams2pdf(myexam, n = 1,
          name=assunto,
          dir=paste0("./BancoDeQuestoes/",assunto),
          encoding = "UTF-8",
          edir = paste0("./BancoDeQuestoes/",assunto),
          template = "plain8")

#####################gravitacao#######################
## Definindo a pasta com as questoes do exame
assunto = "gravitacao"
myexam <- dir(paste0("./BancoDeQuestoes/",assunto), pattern = ".rnw", ignore.case=TRUE)
## Gerando HTML com o arquivo da questao
set.seed(12018)
exams2pdf(myexam, n = 1,
          name=assunto,
          dir=paste0("./BancoDeQuestoes/",assunto),
          encoding = "UTF-8",
          edir = paste0("./BancoDeQuestoes/",assunto),
          template = "plain8")


#####################hidrostatica#######################
## Definindo a pasta com as questoes do exame
assunto = "hidrostatica"
myexam <- dir(paste0("./BancoDeQuestoes/",assunto), pattern = ".rnw", ignore.case=TRUE)
## Gerando HTML com o arquivo da questao
set.seed(12018)
exams2pdf(myexam, n = 1,
          name=assunto,
          dir=paste0("./BancoDeQuestoes/",assunto),
          encoding = "UTF-8",
          edir = paste0("./BancoDeQuestoes/",assunto),
          template = "plain8")


##########impulso e quantidade de movimento############
## Definindo a pasta com as questoes do exame
assunto = "impulso"
myexam <- dir(paste0("./BancoDeQuestoes/",assunto), pattern = ".rnw", ignore.case=TRUE)
## Gerando HTML com o arquivo da questao
set.seed(12018)
exams2pdf(myexam, n = 1,
          name=assunto,
          dir=paste0("./BancoDeQuestoes/",assunto),
          encoding = "UTF-8",
          edir = paste0("./BancoDeQuestoes/",assunto),
          template = "plain8")


####################lei dos gases#######################
## Definindo a pasta com as questoes do exame
assunto = "leidosgases"
myexam <- dir(paste0("./BancoDeQuestoes/",assunto), pattern = ".rnw", ignore.case=TRUE)
## Gerando HTML com o arquivo da questao
set.seed(12018)
exams2pdf(myexam, n = 1,
          name=assunto,
          dir=paste0("./BancoDeQuestoes/",assunto),
          encoding = "UTF-8",
          edir = paste0("./BancoDeQuestoes/",assunto),
          template = "plain8")

####################leis de newton#######################
## Definindo a pasta com as questoes do exame
assunto = "leisdenewton"
myexam <- dir(paste0("./BancoDeQuestoes/",assunto), pattern = ".rnw", ignore.case=TRUE)
## Gerando HTML com o arquivo da questao
set.seed(12018)
exams2pdf(myexam, n = 1,
          name=assunto,
          dir=paste0("./BancoDeQuestoes/",assunto),
          encoding = "UTF-8",
          edir = paste0("./BancoDeQuestoes/",assunto),
          template = "plain8")


#######################magnetismo##########################
## Definindo a pasta com as questoes do exame
assunto = "magnetismo"
myexam <- dir(paste0("./BancoDeQuestoes/",assunto), pattern = ".rnw", ignore.case=TRUE)
## Gerando HTML com o arquivo da questao
set.seed(12018)
exams2pdf(myexam, n = 1,
          name=assunto,
          dir=paste0("./BancoDeQuestoes/",assunto),
          encoding = "UTF-8",
          edir = paste0("./BancoDeQuestoes/",assunto),
          template = "plain8")


#################movimento circular######################
## Definindo a pasta com as questoes do exame
assunto = "movcircular"
myexam <- dir(paste0("./BancoDeQuestoes/",assunto), pattern = ".rnw", ignore.case=TRUE)
## Gerando HTML com o arquivo da questao
set.seed(12018)
exams2pdf(myexam, n = 1,
          name=assunto,
          dir=paste0("./BancoDeQuestoes/",assunto),
          encoding = "UTF-8",
          edir = paste0("./BancoDeQuestoes/",assunto),
          template = "plain8")


#############################MRU##########################
## Definindo a pasta com as questoes do exame
assunto = "mru"
myexam <- dir(paste0("./BancoDeQuestoes/",assunto), pattern = ".rnw", ignore.case=TRUE)
## Gerando HTML com o arquivo da questao
set.seed(12018)
exams2pdf(myexam, n = 1,
          name=assunto,
          dir=paste0("./BancoDeQuestoes/",assunto),
          encoding = "UTF-8",
          edir = paste0("./BancoDeQuestoes/",assunto),
          template = "plain8")


#############################MRUV##########################
## Definindo a pasta com as questoes do exame
assunto = "mruv"
myexam <- dir(paste0("./BancoDeQuestoes/",assunto), pattern = ".rnw", ignore.case=TRUE)
## Gerando HTML com o arquivo da questao
set.seed(12018)
exams2pdf(myexam, n = 1,
          name=assunto,
          dir=paste0("./BancoDeQuestoes/",assunto),
          encoding = "UTF-8",
          edir = paste0("./BancoDeQuestoes/",assunto),
          template = "plain8")


#############################ondas##########################
## Definindo a pasta com as questoes do exame
assunto = "ondas"

myexam <- dir(paste0("./BancoDeQuestoes/",assunto), pattern = ".rnw", ignore.case=TRUE)
## Gerando HTML com o arquivo da questao
set.seed(12018)
exams2pdf(myexam, n = 1,
          name=assunto,
          dir=paste0("./BancoDeQuestoes/",assunto),
          encoding = "UTF-8",
          edir = paste0("./BancoDeQuestoes/",assunto),
          template = "plain8")


#############################optica##########################
## Definindo a pasta com as questoes do exame
assunto = "optica"
myexam <- dir(paste0("./BancoDeQuestoes/",assunto), pattern = ".rnw", ignore.case=TRUE)
## Gerando HTML com o arquivo da questao
set.seed(12018)
exams2pdf(myexam, n = 1, 
          name=assunto,
          encoding = "UTF-8",
          edir = paste0("./BancoDeQuestoes/",assunto),
          template = "plain8")


########################termodinamica##########################
## Definindo a pasta com as questoes do exame
assunto = "termodinamica"
myexam <- dir(paste0("./BancoDeQuestoes/",assunto), pattern = ".rnw", ignore.case=TRUE)
## Gerando HTML com o arquivo da questao
set.seed(12018)
exams2pdf(myexam, n = 1,
          name=assunto,
          dir=paste0("./BancoDeQuestoes/",assunto),
          encoding = "UTF-8",
          edir = paste0("./BancoDeQuestoes/",assunto),
          template = "plain8")

############### testes ##################
## Definindo a pasta com as questoes do exame
assunto = "testes"
myexam <- dir(paste0("./BancoDeQuestoes/",assunto), pattern = ".rnw", ignore.case=TRUE)
## Gerando HTML com o arquivo da questao
set.seed(12018)
exams2pdf(myexam, n = 1,
          name=assunto,
          dir=paste0("./BancoDeQuestoes/",assunto),
          encoding = "UTF-8",
          edir = paste0("./BancoDeQuestoes/",assunto),
          template = "plain8")

#####################trabalho e potencia######################
## Definindo a pasta com as questoes do exame
assunto = "trabalhopotencia"
myexam <- dir(paste0("./BancoDeQuestoes/",assunto), pattern = ".rnw", ignore.case=TRUE)
## Gerando HTML com o arquivo da questao
set.seed(12018)
exams2pdf(myexam, n = 1,
          name=assunto,
          dir=paste0("./BancoDeQuestoes/",assunto),
          encoding = "UTF-8",
          edir = paste0("./BancoDeQuestoes/",assunto),
          template = "plain8")

################## MU ####################
## Definindo a pasta com as questoes do exame
myexam <- dir("./BancoDeQuestoes/cinematica/MU", pattern = ".rnw", ignore.case=TRUE)

## Gerando HTML com o arquivo da questao
set.seed(12018)
exams2pdf(myexam, n = 1,
          encoding = "UTF-8",
          edir = "./BancoDeQuestoes/cinematica/MU",
          template = "plain8")

################## estatica do corpo extenso ####################
## Definindo a pasta com as questoes do exame
assunto = "estatica"
myexam <- dir(paste0("./BancoDeQuestoes/",assunto), pattern = ".rnw", ignore.case=TRUE)
## Gerando HTML com o arquivo da questao
set.seed(12018)
exams2pdf(myexam, n = 1,
          name=assunto,
          dir=paste0("./BancoDeQuestoes/",assunto),
          encoding = "UTF-8",
          edir = paste0("./BancoDeQuestoes/",assunto),
          template = "plain8")

