## parse_moodle_xml.R
## Converte um arquivo Moodle XML (gerado por exams2moodle) numa lista de
## objetos-questão prontos para renderizar e corrigir.

library(xml2)

## ---- imagens: <file> base64 -> data URI; troca @@PLUGINFILE@@ no HTML -------
.mime_de <- function(nome) {
  ext <- tolower(tools::file_ext(nome))
  switch(ext,
         png = "image/png", jpg = "image/jpeg", jpeg = "image/jpeg",
         gif = "image/gif", svg = "image/svg+xml",
         paste0("image/", ext))
}

.embutir_imagens <- function(html, qnode, img_dir = NULL) {
  ## 1) supplements embutidos no próprio XML (<file> base64 + @@PLUGINFILE@@)
  arquivos <- xml_find_all(qnode, ".//file")
  for (f in arquivos) {
    nome <- xml_attr(f, "name")
    if (is.na(nome) || !nzchar(nome)) next
    b64  <- gsub("\\s+", "", xml_text(f))
    uri  <- paste0("data:", .mime_de(nome), ";base64,", b64)
    token <- paste0("@@PLUGINFILE@@/", nome)
    ## evita alt gigante: zera o alt que referencia o plugin file
    html <- gsub(paste0('alt="', token, '"'), 'alt=""', html, fixed = TRUE)
    html <- gsub(token, uri, html, fixed = TRUE)
  }
  ## 2) <img src> ainda não resolvidos (ex.: src="{Q14Trab.png}" no modo
  ##    compilar .Rnw). Limpa chaves e, se o arquivo existir em img_dir,
  ##    embute como data URI.
  srcs <- unique(regmatches(html, gregexpr('src="[^"]*"', html))[[1]])
  for (s in srcs) {
    val <- sub('"$', '', sub('^src="', '', s))
    if (grepl("^(data:|https?:)", val)) next
    nome <- basename(trimws(gsub("[{}]", "", val)))
    novo <- nome
    if (!is.null(img_dir)) {
      cam <- file.path(img_dir, nome)
      if (file.exists(cam))
        novo <- paste0("data:", .mime_de(nome), ";base64,",
                       base64enc::base64encode(cam))
    }
    html <- gsub(s, paste0('src="', novo, '"'), html, fixed = TRUE)
  }
  html
}

## ---- parser de uma lacuna cloze {GRADE:TYPE:body} ---------------------------
.parse_gap <- function(raw, id) {
  m <- regmatches(raw, regexec("^\\{(\\d+):([A-Za-z_]+):(.*)\\}$", raw))[[1]]
  if (length(m) != 4) {
    return(list(id = id, type = "text", answers = list(), raw = raw))
  }
  tipo_raw <- toupper(m[3]); body <- m[4]
  tipo <- if (tipo_raw %in% c("NUMERICAL", "NM")) "num"
          else if (tipo_raw %in% c("SHORTANSWER", "SA", "MW")) "text"
          else if (grepl("^MC|MULTICHOICE", tipo_raw)) "choice"
          else "text"

  entradas <- strsplit(body, "~", fixed = TRUE)[[1]]
  answers <- list(); options <- character(0)
  for (e in entradas) {
    correto <- grepl("^=", e) || grepl("^%100", e)
    frac <- 100
    fm <- regmatches(e, regexec("^%(-?\\d+(?:\\.\\d+)?)%", e))[[1]]
    if (length(fm) == 2) frac <- as.numeric(fm[2])
    corpo <- sub("^(=|%-?\\d+(?:\\.\\d+)?%)", "", e)
    if (tipo == "num") {
      tol <- 0
      tm <- regmatches(corpo, regexec(":(\\d+(?:[.,]\\d+)?)\\s*$", corpo))[[1]]
      if (length(tm) == 2) {
        tol  <- as.numeric(gsub(",", ".", tm[2]))
        corpo <- sub(":(\\d+(?:[.,]\\d+)?)\\s*$", "", corpo)
      }
      corpo <- sub("#.*$", "", corpo)              # remove feedback inline
      valor <- suppressWarnings(as.numeric(gsub(",", ".", trimws(corpo))))
      answers[[length(answers) + 1]] <- list(value = valor, tol = tol,
                                             fraction = frac)
    } else {
      txt <- trimws(sub("#.*$", "", corpo))
      options <- c(options, txt)
      answers[[length(answers) + 1]] <- list(text = txt, fraction = frac)
    }
  }
  list(id = id, type = tipo, answers = answers, options = unique(options))
}

## ---- extrai e substitui todas as lacunas do HTML por marcadores ⟦n⟧ ---------
.parse_cloze <- function(html) {
  ## Só campos cloze do Moodle ({N:TIPO:...}); evita chaves de LaTeX/math.
  padrao <- "\\{\\d+:[A-Za-z_]+:[^{}]*\\}"
  locs <- gregexpr(padrao, html)[[1]]
  if (locs[1] == -1) return(list(html = html, gaps = list()))
  brutos <- regmatches(html, gregexpr(padrao, html))[[1]]
  gaps <- list()
  for (i in seq_along(brutos)) {
    g <- .parse_gap(brutos[i], i)
    gaps[[i]] <- g
    marcador <- sprintf('<span class="cloze-gap">⟦%d⟧</span>', i)
    html <- sub(brutos[i], marcador, html, fixed = TRUE)
  }
  list(html = html, gaps = gaps)
}

## ---- uma questão -----------------------------------------------------------
.parse_question <- function(qnode, img_dir = NULL) {
  tipo <- xml_attr(qnode, "type")
  nome <- trimws(xml_text(xml_find_first(qnode, "./name/text")))
  html <- xml_text(xml_find_first(qnode, "./questiontext/text"))
  if (is.na(html)) html <- ""
  html <- .embutir_imagens(html, qnode, img_dir)
  solucao <- xml_text(xml_find_first(qnode, "./generalfeedback/text"))
  if (is.na(solucao)) solucao <- ""

  q <- list(type = tipo, name = nome, html = html, solution_html = solucao,
            gaps = list(), answers = list(), single = NA, options = list())

  if (tipo == "numerical") {
    ans <- xml_find_all(qnode, "./answer")
    lst <- list()
    for (a in ans) {
      frac <- as.numeric(xml_attr(a, "fraction"))
      if (is.na(frac) || frac <= 0) next
      val <- suppressWarnings(as.numeric(gsub(",", ".",
                trimws(xml_text(xml_find_first(a, "./text"))))))
      toln <- xml_text(xml_find_first(a, "./tolerance"))
      tol <- if (is.na(toln)) 0 else as.numeric(gsub(",", ".", toln))
      lst[[length(lst) + 1]] <- list(value = val, tol = tol)
    }
    q$answers <- lst

  } else if (tipo == "shortanswer") {
    usecase <- xml_text(xml_find_first(qnode, "./usecase"))
    q$usecase <- !is.na(usecase) && usecase == "1"
    ans <- xml_find_all(qnode, "./answer")
    aceitos <- character(0)
    for (a in ans) {
      frac <- as.numeric(xml_attr(a, "fraction"))
      if (is.na(frac) || frac <= 0) next
      aceitos <- c(aceitos, trimws(xml_text(xml_find_first(a, "./text"))))
    }
    q$answers <- aceitos

  } else if (tipo == "multichoice") {
    single <- xml_text(xml_find_first(qnode, "./single"))
    q$single <- !is.na(single) && single == "true"
    ans <- xml_find_all(qnode, "./answer")
    opts <- list()
    for (a in ans) {
      frac <- as.numeric(xml_attr(a, "fraction"))
      txt  <- xml_text(xml_find_first(a, "./text"))
      fb   <- xml_text(xml_find_first(a, "./feedback/text"))
      opts[[length(opts) + 1]] <- list(
        html = txt, fraction = ifelse(is.na(frac), 0, frac),
        feedback = ifelse(is.na(fb), "", fb))
    }
    q$options <- opts

  } else if (tipo == "cloze") {
    cl <- .parse_cloze(q$html)
    q$html <- cl$html
    q$gaps <- cl$gaps
  }
  q
}

## ---- API -------------------------------------------------------------------
## Lê o XML e devolve lista de questões (ignora separadores 'category').
## 'limite' protege contra arquivos enormes (ex.: estatica = 75MB).
parse_moodle_xml <- function(path, limite = 50, img_dir = NULL) {
  doc <- read_xml(path)
  nodes <- xml_find_all(doc, ".//question[@type!='category']")
  total <- length(nodes)
  if (total > limite) nodes <- nodes[seq_len(limite)]
  questoes <- lapply(nodes, .parse_question, img_dir = img_dir)
  attr(questoes, "total") <- total
  attr(questoes, "carregadas") <- length(questoes)
  questoes
}
