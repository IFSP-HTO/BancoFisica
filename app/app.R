## app.R — Pré-visualizador de questões do BancoFisica "como no Moodle".
## Rode a partir da raiz do projeto: shiny::runApp("app")

library(shiny)
library(xml2)

source("R/compile_rnw.R",      local = TRUE)
source("R/parse_moodle_xml.R", local = TRUE)
source("R/render_question.R",  local = TRUE)
source("R/grade.R",            local = TRUE)

## Raiz do projeto (a wd durante runApp é a pasta app/).
find_root <- function(start = getwd()) {
  d <- start
  for (i in 1:5) {
    if (dir.exists(file.path(d, "BancoDeQuestoes"))) return(d)
    d <- dirname(d)
  }
  start
}
ROOT   <- find_root()
BANCO  <- file.path(ROOT, "BancoDeQuestoes")
MOODLE <- file.path(ROOT, "Moodle")

rnw_choices <- tryCatch(listar_rnw(BANCO), error = function(e) character(0))

## Agrupa as questões por assunto (1º componente do caminho) -> optgroups.
## Garante que subpastas (ex.: cinematica/MU/) apareçam sob o assunto.
montar_grupos <- function(choices) {
  if (length(choices) == 0) return(choices)
  rotulos <- names(choices)
  assunto <- sub("/.*$", "", rotulos)              # ex.: "cinematica"
  internos <- sub("^[^/]+/", "", rotulos)          # ex.: "MU/Q03MU.Rnw"
  vec <- stats::setNames(unname(choices), internos)
  split(vec, factor(assunto, levels = unique(assunto)))
}
rnw_grupos <- montar_grupos(rnw_choices)
xml_choices <- {
  fs <- list.files(MOODLE, pattern = "\\.xml$", full.names = TRUE)
  stats::setNames(fs, basename(fs))
}

## ---- UI --------------------------------------------------------------------
ui <- fluidPage(
  tags$head(
    tags$script(HTML(
      "window.MathJax={tex:{inlineMath:[['\\\\(','\\\\)']],",
      "displayMath:[['\\\\[','\\\\]']]},svg:{fontCache:'global'}};")),
    tags$script(async = NA, id = "MathJax-script",
      src = "https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-mml-chtml.js"),
    tags$script(HTML(
      "Shiny.addCustomMessageHandler('typeset', function(x){",
      "  setTimeout(function(){",
      "    if(window.MathJax && MathJax.typesetPromise){MathJax.typesetPromise();}",
      "  }, 120);",
      "});")),
    includeCSS("www/styles.css")
  ),
  titlePanel("BancoFisica — Pré-visualização Moodle"),
  sidebarLayout(
    sidebarPanel(width = 4,
      radioButtons("modo", "Fonte das questões:",
        c("Compilar .Rnw" = "rnw", "XML existente" = "xml",
          "Upload de XML" = "upload")),
      conditionalPanel("input.modo == 'rnw'",
        selectizeInput("rnw_file", "Questão (.Rnw):", choices = rnw_grupos,
                       options = list(maxOptions = 10000)),
        fluidRow(
          column(6, numericInput("n_var", "Variantes", value = 1, min = 1,
                                 max = 20)),
          column(6, numericInput("seed", "Seed", value = 1, min = 1))),
        actionButton("compilar", "Compilar e carregar", class = "btn-primary")),
      conditionalPanel("input.modo == 'xml'",
        selectInput("xml_file", "Arquivo XML:", choices = xml_choices),
        numericInput("limite_x", "Máx. de questões", value = 50, min = 1),
        actionButton("carregar_x", "Carregar", class = "btn-primary")),
      conditionalPanel("input.modo == 'upload'",
        fileInput("up_xml", "Enviar .xml", accept = ".xml"),
        numericInput("limite_u", "Máx. de questões", value = 50, min = 1)),
      tags$hr(),
      uiOutput("status")
    ),
    mainPanel(width = 8,
      uiOutput("nav"),
      tags$hr(),
      uiOutput("stem"),
      tags$div(class = "answer-box",
        uiOutput("inputs"),
        tags$div(class = "actions",
          actionButton("verificar", "Verificar", class = "btn-success"),
          actionButton("solucao", "Mostrar solução"))),
      uiOutput("feedback"),
      uiOutput("solucao_box")
    )
  )
)

## ---- Server ----------------------------------------------------------------
server <- function(input, output, session) {
  rv <- reactiveValues(questoes = NULL, idx = 1, msg = NULL,
                       fb = NULL, sol = FALSE)

  carregar <- function(questoes, origem) {
    if (length(questoes) == 0) {
      rv$msg <- list(type = "warning", text = "Nenhuma questão encontrada.")
      return()
    }
    rv$questoes <- questoes; rv$idx <- 1; rv$fb <- NULL; rv$sol <- FALSE
    tot <- attr(questoes, "total"); car <- attr(questoes, "carregadas")
    extra <- if (!is.null(tot) && tot > car)
      sprintf(" (mostrando %d de %d)", car, tot) else ""
    rv$msg <- list(type = "ok",
      text = sprintf("%s: %d questões%s", origem, length(questoes), extra))
  }

  observeEvent(input$compilar, {
    req(input$rnw_file)
    tryCatch(
      withProgress(message = "Compilando .Rnw...", value = 0.5, {
        xml <- compilar_rnw(input$rnw_file, n = input$n_var, seed = input$seed)
        carregar(parse_moodle_xml(xml, limite = 9999,
                                  img_dir = dirname(input$rnw_file)),
                 basename(input$rnw_file))
      }),
      error = function(e)
        rv$msg <- list(type = "err",
                       text = paste("Erro ao compilar:", conditionMessage(e))))
  })

  observeEvent(input$carregar_x, {
    req(input$xml_file)
    tryCatch(
      withProgress(message = "Lendo XML...", value = 0.5,
        carregar(parse_moodle_xml(input$xml_file, limite = input$limite_x),
                 basename(input$xml_file))),
      error = function(e)
        rv$msg <- list(type = "err",
                       text = paste("Erro ao ler XML:", conditionMessage(e))))
  })

  observeEvent(input$up_xml, {
    req(input$up_xml)
    tryCatch(
      carregar(parse_moodle_xml(input$up_xml$datapath, limite = input$limite_u),
               input$up_xml$name),
      error = function(e)
        rv$msg <- list(type = "err",
                       text = paste("Erro no upload:", conditionMessage(e))))
  })

  output$status <- renderUI({
    m <- rv$msg
    if (is.null(m)) return(tags$p(tags$em("Escolha uma fonte e carregue.")))
    cls <- switch(m$type, ok = "msg-ok", warning = "msg-warn", "msg-err")
    tags$p(class = cls, m$text)
  })

  cur <- reactive({ req(rv$questoes); rv$questoes[[rv$idx]] })

  ## Navegação
  output$nav <- renderUI({
    req(rv$questoes)
    rotulos <- vapply(seq_along(rv$questoes), function(i)
      sprintf("%d. %s [%s]", i, rv$questoes[[i]]$name, rv$questoes[[i]]$type),
      character(1))
    fluidRow(
      column(2, actionButton("prev", "◀")),
      column(8, selectInput("qsel", NULL, width = "100%",
        choices = stats::setNames(seq_along(rv$questoes), rotulos),
        selected = isolate(rv$idx))),
      column(2, actionButton("next_", "▶")))
  })

  observeEvent(input$qsel, {
    novo <- as.integer(input$qsel)
    if (!is.na(novo) && novo != rv$idx) { rv$idx <- novo; rv$fb <- NULL; rv$sol <- FALSE }
  })
  observeEvent(input$prev, {
    if (rv$idx > 1) updateSelectInput(session, "qsel", selected = rv$idx - 1)
  })
  observeEvent(input$next_, {
    if (rv$idx < length(rv$questoes))
      updateSelectInput(session, "qsel", selected = rv$idx + 1)
  })

  output$stem   <- renderUI(render_stem(cur()))
  output$inputs <- renderUI(build_inputs(cur()))

  ## Re-tipografar math sempre que a questão/feedback/solução muda
  observe({ rv$idx; cur(); session$sendCustomMessage("typeset", runif(1)) })

  observeEvent(input$verificar, {
    q <- cur()
    rv$fb <- grade_question(q, collect_answers(input, q))
    session$sendCustomMessage("typeset", runif(1))
  })
  observeEvent(input$solucao, {
    rv$sol <- TRUE
    session$sendCustomMessage("typeset", runif(1))
  })

  output$feedback <- renderUI({
    if (is.null(rv$fb)) return(NULL)
    tags$div(class = "feedback-box", tags$h4("Correção"), build_feedback(rv$fb))
  })
  output$solucao_box <- renderUI({
    if (!isTRUE(rv$sol)) return(NULL)
    q <- cur()
    sol <- if (nzchar(q$solution_html)) HTML(q$solution_html)
           else tags$em("Sem solução no XML.")
    tags$div(class = "solution-box", tags$h4("Solução"), sol)
  })
}

shinyApp(ui, server)
