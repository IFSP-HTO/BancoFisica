## Carregando os pacotes necessarios
library(tools)
library(exams)

############### exemplos ##################
## Definindo a pasta com as questoes do exame
myexam <- dir("./BancoDeQuestoes/exemplos/")

## Gerando HTML com o arquivo da questao
set.seed(12017)
exams2html(myexam, n = 1,solution=TRUE,
           encoding = "UTF-8",
           edir = "./BancoDeQuestoes/exemplos",
           template = "templates/plain.html")

############### velocidade media ##################
## Definindo a pasta com as questoes do exame
myexam <- dir("./BancoDeQuestoes/vm/")

## Gerando HTML com o arquivo da questao
set.seed(12017)
exams2html(myexam, n = 1,solution=TRUE,
  encoding = "UTF-8",
  edir = "./BancoDeQuestoes/vm",
  template = "templates/plain.html")

############### aceleração media ##################
## Definindo a pasta com as questoes do exame
myexam <- dir("./BancoDeQuestoes/acel/")

## Gerando HTML com o arquivo da questao
set.seed(12017)
exams2html(myexam, n = 1,solution=TRUE,
           encoding = "UTF-8",
           edir = "./BancoDeQuestoes/acel",
           template = "plain8")

############### calor e temperatura ##################
## Definindo a pasta com as questoes do exame
myexam <- dir("./BancoDeQuestoes/calortemp/")

## Gerando HTML com o arquivo da questao
set.seed(12017)
exams2html(myexam, n = 1,solution=TRUE,
           encoding = "UTF-8",
           edir = "./BancoDeQuestoes/calortemp",
           template = "templates/plain.html")


############### calorimetria ##################
## Definindo a pasta com as questoes do exame
myexam <- dir("./BancoDeQuestoes/calorimetria/")

## Gerando HTML com o arquivo da questao
set.seed(12017)
exams2html(myexam, n = 1,solution=TRUE,
           encoding = "UTF-8",
           edir = "./BancoDeQuestoes/calorimetria",
           template = "templates/plain.html")


############### dilatação trmica ##################
## Definindo a pasta com as questoes do exame
myexam <- dir("./BancoDeQuestoes/dilatterm/")

## Gerando HTML com o arquivo da questao
set.seed(12017)
exams2html(myexam, n = 1,solution=TRUE,
           encoding = "UTF-8",
           edir = "./BancoDeQuestoes/dilatterm",
           template = "templates/plain.html")

