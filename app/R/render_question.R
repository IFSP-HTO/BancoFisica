## render_question.R
## Constrói a UI de uma questão (enunciado + campos de resposta) e o feedback.
## Usa funções do shiny (carregado pelo app.R).

## Enunciado: HTML já tem math em \(...\) e imagens em data URI.
render_stem <- function(q) {
  tagList(
    tags$div(class = "q-name", q$name),
    tags$div(class = "q-stem", HTML(q$html))
  )
}

## Campos de resposta conforme o tipo.
build_inputs <- function(q) {
  if (q$type == "numerical") {
    textInput("resp_num", "Sua resposta:", value = "",
              placeholder = "ex.: 4,9")

  } else if (q$type == "shortanswer") {
    textInput("resp_text", "Sua resposta:", value = "")

  } else if (q$type == "multichoice") {
    nomes <- lapply(q$options, function(o) HTML(o$html))
    valores <- as.character(seq_along(q$options))
    if (isTRUE(q$single)) {
      radioButtons("resp_choice", "Escolha uma alternativa:",
                   choiceNames = nomes, choiceValues = valores,
                   selected = character(0))
    } else {
      checkboxGroupInput("resp_choice", "Marque todas as corretas:",
                         choiceNames = nomes, choiceValues = valores)
    }

  } else if (q$type == "cloze") {
    if (length(q$gaps) == 0) return(tags$p(tags$em("Sem lacunas detectadas.")))
    campos <- lapply(q$gaps, function(g) {
      id <- paste0("gap_", g$id)
      rotulo <- sprintf("Lacuna ⟦%d⟧", g$id)
      if (g$type == "choice" && length(g$options) > 0) {
        radioButtons(id, rotulo, choices = g$options, selected = character(0))
      } else {
        textInput(id, rotulo, value = "")
      }
    })
    do.call(tagList, campos)
  }
}

## Lê do input as respostas no formato esperado por grade_question().
collect_answers <- function(input, q) {
  if (q$type == "numerical") {
    input$resp_num
  } else if (q$type == "shortanswer") {
    input$resp_text
  } else if (q$type == "multichoice") {
    as.integer(input$resp_choice)
  } else if (q$type == "cloze") {
    stats::setNames(
      lapply(q$gaps, function(g) input[[paste0("gap_", g$id)]]),
      vapply(q$gaps, function(g) paste0("gap_", g$id), character(1)))
  }
}

.badge <- function(ok) {
  if (isTRUE(ok)) tags$span(class = "badge-ok", "✓ Correto")
  else tags$span(class = "badge-no", "✗ Incorreto")
}

## Monta o HTML de feedback a partir do resultado de grade_question().
build_feedback <- function(res) {
  if (res$type %in% c("numerical", "shortanswer")) {
    .badge(res$correct)

  } else if (res$type == "multichoice") {
    itens <- lapply(res$options, function(o) {
      cls <- if (o$is_correct) "opt-correct" else "opt-wrong"
      marca <- if (o$selected) "● " else "○ "
      tags$li(class = cls,
        HTML(paste0(marca, o$html)),
        if (nzchar(o$feedback)) tags$div(class = "opt-fb", HTML(o$feedback)))
    })
    tagList(.badge(res$correct), tags$ul(class = "opt-list", itens))

  } else if (res$type == "cloze") {
    itens <- lapply(res$gaps, function(g)
      tags$li(sprintf("Lacuna ⟦%d⟧: ", g$id), .badge(g$correct)))
    tagList(
      tags$div(sprintf("Acertos: %d de %d", res$n_correct, res$n_total)),
      tags$ul(class = "gap-list", itens))
  }
}
