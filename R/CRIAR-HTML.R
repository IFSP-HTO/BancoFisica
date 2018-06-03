## Carregando os pacotes necessarios
library(tools)
library(exams)

############### aceleracao media ##################
## Definindo a pasta com as questoes do exame
myexam <- dir("./BancoDeQuestoes/acel/", pattern = ".rnw", ignore.case=TRUE)

## Gerando HTML com o arquivo da questao
set.seed(12018)
exams2html(myexam, n = 1,solution=TRUE,
           encoding = "UTF-8",
           edir = "./BancoDeQuestoes/acel",
           template = "plain8")

############### calorimetria ##################
## Definindo a pasta com as questoes do exame
myexam <- dir("./BancoDeQuestoes/calorimetria/", pattern = ".rnw", ignore.case=TRUE)

## Gerando HTML com o arquivo da questao
set.seed(12018)
exams2html(myexam, n = 1,solution=TRUE,
           encoding = "UTF-8",
           edir = "./BancoDeQuestoes/calorimetria",
           template = "templates/plain.html")

############### calor e temperatura ##################
## Definindo a pasta com as questoes do exame
myexam <- dir("./BancoDeQuestoes/calortemp/", pattern = ".rnw", ignore.case=TRUE)

## Gerando HTML com o arquivo da questao
set.seed(12018)
exams2html(myexam, n = 1,solution=TRUE,
           encoding = "UTF-8",
           edir = "./BancoDeQuestoes/calortemp",
           template = "templates/plain.html")

############### dilatacao termica ##################
## Definindo a pasta com as questoes do exame
myexam <- dir("./BancoDeQuestoes/dilatterm/", pattern = ".rnw", ignore.case=TRUE)

## Gerando HTML com o arquivo da questao
set.seed(12018)
exams2html(myexam, n = 1,solution=TRUE,
           encoding = "UTF-8",
           edir = "./BancoDeQuestoes/dilatterm",
           template = "templates/plain.html")

############### eletricidade ########################
## Definindo a pasta com as questoes do exame
myexam <- dir("./BancoDeQuestoes/eletricidade/", pattern = ".rnw", ignore.case=TRUE)

## Gerando HTML com o arquivo da questao
set.seed(12018)
exams2html(myexam, n = 1,solution=TRUE,
           encoding = "UTF-8",
           edir = "./BancoDeQuestoes/eletricidade",
           template = "templates/plain.html")

################# eletromagnetismo ####################
## Definindo a pasta com as questoes do exame
myexam <- dir("./BancoDeQuestoes/eletromagnetismo/", pattern = ".rnw", ignore.case=TRUE)

## Gerando HTML com o arquivo da questao
set.seed(12018)
exams2html(myexam, n = 1,solution=TRUE,
           encoding = "UTF-8",
           edir = "./BancoDeQuestoes/eletromagnetismo",
           template = "templates/plain.html")

################### eletrostatica ######################
## Definindo a pasta com as questoes do exame
myexam <- dir("./BancoDeQuestoes/eletrostatica/", pattern = ".rnw", ignore.case=TRUE)

## Gerando HTML com o arquivo da questao
set.seed(12018)
exams2html(myexam, n = 1,solution=TRUE,
           encoding = "UTF-8",
           edir = "./BancoDeQuestoes/eletrostatica",
           template = "templates/plain.html")

##############energia e conservacao###################
## Definindo a pasta com as questoes do exame
myexam <- dir("./BancoDeQuestoes/energiaeconservacao/", pattern = ".rnw", ignore.case=TRUE)

## Gerando HTML com o arquivo da questao
set.seed(12018)
exams2html(myexam, n = 1,solution=TRUE,
           encoding = "UTF-8",
           edir = "./BancoDeQuestoes/energiaeconservacao",
           template = "templates/plain.html")

#####################gravitacao#######################
## Definindo a pasta com as questoes do exame
myexam <- dir("./BancoDeQuestoes/gravitacao/", pattern = ".rnw", ignore.case=TRUE)

## Gerando HTML com o arquivo da questao
set.seed(12018)
exams2html(myexam, n = 1,solution=TRUE,
           encoding = "UTF-8",
           edir = "./BancoDeQuestoes/gravitacao",
           template = "templates/plain.html")


#####################hidrostatica#######################
## Definindo a pasta com as questoes do exame
myexam <- dir("./BancoDeQuestoes/hidrostatica/", pattern = ".rnw", ignore.case=TRUE)

## Gerando HTML com o arquivo da questao
set.seed(12018)
exams2html(myexam, n = 1,solution=TRUE, mathjax = TRUE,
           encoding = "UTF-8",
           edir = "./BancoDeQuestoes/hidrostatica",
           template = "templates/plain.html")


##########impulso e quantidade de movimento############
## Definindo a pasta com as questoes do exame
myexam <- dir("./BancoDeQuestoes/impulso/", pattern = ".rnw", ignore.case=TRUE)

## Gerando HTML com o arquivo da questao
set.seed(12018)
exams2html(myexam, n = 1,solution=TRUE,
           encoding = "UTF-8",
           edir = "./BancoDeQuestoes/impulso",
           template = "templates/plain.html")


####################lei dos gases#######################
## Definindo a pasta com as questoes do exame
myexam <- dir("./BancoDeQuestoes/leidosgases/", pattern = ".rnw", ignore.case=TRUE)

## Gerando HTML com o arquivo da questao
set.seed(12018)
exams2html(myexam, n = 1,solution=TRUE,
           encoding = "UTF-8",
           edir = "./BancoDeQuestoes/leidosgases",
           template = "templates/plain.html")

####################leis de newton#######################
## Definindo a pasta com as questoes do exame
myexam <- dir("./BancoDeQuestoes/leisdenewton/", pattern = ".rnw", ignore.case=TRUE)

## Gerando HTML com o arquivo da questao
set.seed(12018)
exams2html(myexam, n = 1,solution=TRUE,
           encoding = "UTF-8",
           edir = "./BancoDeQuestoes/leisdenewton",
           template = "templates/plain.html")


#######################magnetismo##########################
## Definindo a pasta com as questoes do exame
myexam <- dir("./BancoDeQuestoes/magnetismo/", pattern = ".rnw", ignore.case=TRUE)

## Gerando HTML com o arquivo da questao
set.seed(12018)
exams2html(myexam, n = 1,solution=TRUE,
           encoding = "UTF-8",
           edir = "./BancoDeQuestoes/magnetismo",
           template = "templates/plain.html")


#################movimento circular######################
## Definindo a pasta com as questoes do exame
myexam <- dir("./BancoDeQuestoes/movcircular/", pattern = ".rnw", ignore.case=TRUE)

## Gerando HTML com o arquivo da questao
set.seed(12018)
exams2html(myexam, n = 1,solution=TRUE,
           encoding = "UTF-8",
           edir = "./BancoDeQuestoes/movcircular",
           template = "templates/plain.html")


#############################MRU##########################
## Definindo a pasta com as questoes do exame
myexam <- dir("./BancoDeQuestoes/mru/", pattern = ".rnw", ignore.case=TRUE)

## Gerando HTML com o arquivo da questao
set.seed(12018)
exams2html(myexam, n = 1,solution=TRUE,
           encoding = "UTF-8",
           edir = "./BancoDeQuestoes/mru",
           template = "templates/plain.html")



#############################MRUV##########################
## Definindo a pasta com as questoes do exame
myexam <- dir("./BancoDeQuestoes/mruv/", pattern = ".rnw", ignore.case=TRUE)

## Gerando HTML com o arquivo da questao
set.seed(12018)
exams2html(myexam, n = 1,solution=TRUE,
           encoding = "UTF-8",
           edir = "./BancoDeQuestoes/mruv",
           template = "templates/plain.html")


#############################ondas##########################
## Definindo a pasta com as questoes do exame
myexam <- dir("./BancoDeQuestoes/ondas/", pattern = ".rnw", ignore.case=TRUE)

## Gerando HTML com o arquivo da questao
set.seed(12018)
exams2html(myexam, n = 1,solution=TRUE,
           encoding = "UTF-8",
           edir = "./BancoDeQuestoes/ondas",
           template = "templates/plain.html")


#############################optica##########################
## Definindo a pasta com as questoes do exame
myexam <- dir("./BancoDeQuestoes/optica/", pattern = ".rnw", ignore.case=TRUE)

## Gerando HTML com o arquivo da questao
set.seed(12018)
exams2html(myexam, n = 1,solution=TRUE,
           encoding = "UTF-8",
           edir = "./BancoDeQuestoes/optica",
           template = "templates/plain.html")


########################termodinamica##########################
## Definindo a pasta com as questoes do exame
myexam <- dir("./BancoDeQuestoes/termodinamica/", pattern = ".rnw", ignore.case=TRUE)

## Gerando HTML com o arquivo da questao
set.seed(12018)
exams2html(myexam, n = 1,solution=TRUE,
           encoding = "UTF-8",
           edir = "./BancoDeQuestoes/termodinamica",
           template = "templates/plain.html")

############### testes ##################
## Definindo a pasta com as questoes do exame
myexam <- dir("./BancoDeQuestoes/testes/", pattern = ".rnw", ignore.case=TRUE)

## Gerando HTML com o arquivo da questao
set.seed(12018)
exams2html(myexam, n = 1,solution=TRUE,
           encoding = "UTF-8",
           edir = "./BancoDeQuestoes/testes",
           template = "templates/plain.html")

#####################trabalho e potencia######################
## Definindo a pasta com as questoes do exame
myexam <- dir("./BancoDeQuestoes/trabalhopotencia/", pattern = ".rnw", ignore.case=TRUE)

## Gerando HTML com o arquivo da questao
set.seed(12018)
exams2html(myexam, n = 1,solution=TRUE, mathjax = TRUE,
           encoding = "UTF-8",
           edir = "./BancoDeQuestoes/trabalhopotencia",
           template = "templates/plain.html")


################## MU ####################
## Definindo a pasta com as questoes do exame
myexam <- dir("./BancoDeQuestoes/cinematica/MU", pattern = ".rnw", ignore.case=TRUE)

## Gerando HTML com o arquivo da questao
set.seed(12018)
exams2html(myexam, n = 1,solution=TRUE, converter = 'pandoc',
  encoding = "UTF-8",
  edir = "./BancoDeQuestoes/cinematica/MU",
  template = "templates/plain.html")

################## estatica corpo extenso ####################
## Definindo a pasta com as questoes do exame
myexam <- dir("./BancoDeQuestoes/estatica/", pattern = ".rnw", ignore.case=TRUE)

## Gerando HTML com o arquivo da questao
set.seed(12018)
exams2html(myexam, n = 1,solution=TRUE,
           encoding = "UTF-8",
           edir = "./BancoDeQuestoes/estatica",
           template = "templates/plain.html")
