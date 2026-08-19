## Limite de upload do Moodle institucional: ~10 MB por importacao.
## Nenhum XML gerado para o banco deve ultrapassar esse limite; quando um
## assunto geraria um arquivo maior, a saida e dividida em varias partes de
## ate `max_bytes` cada.
##
## Este modulo e compartilhado por:
##   - tools/generate_moodle_xml.R (pipeline canonico, usado no CI)
##   - Moodle/ExerciciosParaMoodle.R (script legado de geracao em ./Moodle)

## Converte megabytes em bytes (MiB, base 2).
moodle_size_limit <- function(mb = 10) {
  as.numeric(mb) * 1024L * 1024L
}

## Remove artefatos de um `name` gerados em execucoes anteriores dentro de
## `dir`: o script legado grava sobre uma pasta persistente (./Moodle) que
## pode conter `name.xml` antigo e partes `name-partNN.xml` excedentes de uma
## rodada com mais partes. Nunca remove arquivos de outros assuntos.
clean_moodle_outputs <- function(dir, name) {
  esc <- gsub("([][{}()*+?.^$|\\\\])", "\\\\\\1", name)
  stale <- list.files(
    dir,
    pattern = paste0("^", esc, "(\\.xml|\\-part[0-9]+\\.xml)$"),
    full.names = TRUE
  )
  if (length(stale) > 0) unlink(stale)
  invisible(TRUE)
}

## exams2moodle numera Exercise/Q/R localmente em cada chamada. Quando o banco
## e repartido em varias chamadas, essa numeracao reinicia e categorias de
## questoes-base diferentes colidem no Moodle (por exemplo, duas "Exercise 1").
## Este pos-processamento torna a divisao transparente para a identidade Moodle:
##   * Q nos nomes das variantes recebe `question_offset` (posicao global do
##     .Rnw no conjunto completo);
##   * R recebe `replica_offset`, mantendo R001, R002, ... continuos entre as
##     partes quando as replicas de uma questao isolada sao repartidas;
##   * a categoria "Exercise N" e reescrita para N = Q global da questao que a
##     sucede (categorias customizadas de questoes com \exsection nao sao
##     tocadas). Isso e robusto a questoes com \exsection intercaladas: a
##     numeracao local de "Exercise" pula essas questoes e, portanto, nao pode
##     ser derivada apenas da posicao do arquivo.
rewrite_moodle_indices <- function(xml_file, question_offset = 0L,
                                   replica_offset = 0L) {
  question_offset <- as.integer(question_offset)
  replica_offset <- as.integer(replica_offset)
  if (question_offset == 0L && replica_offset == 0L) return(invisible(xml_file))

  lines <- readLines(xml_file, warn = FALSE, encoding = "UTF-8")

  ## Em cada nome de variante (linha), registra o Q global. Em cada categoria
  ## "Exercise N", registra o indice da primeira linha de variante que a segue
  ## (as variantes da categoria sempre vêm logo após a categoria no XML).
  name_q <- rep(NA_integer_, length(lines))
  name_r <- rep(NA_integer_, length(lines))
  cat_line <- integer()
  cat_name_line <- integer()

  for (k in seq_along(lines)) {
    line <- lines[k]

    m_cat <- regmatches(
      line,
      regexec("(<text>\\$course\\$/[^<]*/Exercise )([0-9]+)(</text>)",
              line, perl = TRUE)
    )[[1]]
    if (length(m_cat) > 0L) {
      cat_line <- c(cat_line, k)
      cat_name_line <- c(cat_name_line, NA_integer_)
      next
    }

    m_name <- regmatches(
      line,
      regexec("(<text>[[:space:]]*)R([0-9]+)[[:space:]]+Q([0-9]+)([[:space:]]*:)",
              line, perl = TRUE)
    )[[1]]
    if (length(m_name) > 0L) {
      name_r[k] <- as.integer(m_name[3])
      name_q[k] <- as.integer(m_name[4]) + question_offset
      last_cat <- length(cat_name_line)
      if (last_cat > 0L && is.na(cat_name_line[[last_cat]])) {
        cat_name_line[[last_cat]] <- k
      }
    }
  }

  ## Reescreve R e Q nos nomes das variantes.
  for (k in seq_along(lines)) {
    if (is.na(name_r[k])) next
    m_name <- regmatches(
      lines[k],
      regexec("(<text>[[:space:]]*)R([0-9]+)[[:space:]]+Q([0-9]+)([[:space:]]*:)",
              lines[k], perl = TRUE)
    )[[1]]
    global_r <- name_r[k] + replica_offset
    r_width <- nchar(m_name[3])
    r_text <- sprintf(paste0("%0", r_width, "d"), global_r)
    replacement <- paste0(m_name[2], "R", r_text, " Q", name_q[k], m_name[5])
    lines[k] <- sub(m_name[1], replacement, lines[k], fixed = TRUE)
  }

  ## Reescreve as categorias "Exercise N" para o Q global da questao que segue.
  for (j in seq_along(cat_line)) {
    nk <- cat_name_line[j]
    if (is.na(nk)) next
    m_cat <- regmatches(
      lines[cat_line[j]],
      regexec("(<text>\\$course\\$/[^<]*/Exercise )([0-9]+)(</text>)",
              lines[cat_line[j]], perl = TRUE)
    )[[1]]
    if (length(m_cat) > 0L) {
      replacement <- paste0(m_cat[2], name_q[nk], m_cat[4])
      lines[cat_line[j]] <- sub(m_cat[1], replacement, lines[cat_line[j]], fixed = TRUE)
    }
  }

  writeLines(lines, xml_file, useBytes = TRUE)
  invisible(xml_file)
}

## Verifica a propriedade que o particionamento deve preservar: juntar todas
## as partes tem de produzir exatamente as mesmas identidades logicas de uma
## geracao unica. Questoes com \exsection emitem categoria propria (sem
## "Exercise N"), entao a numeracao de categorias nao precisa cobrir 1..N.
## O que NUNCA pode acontecer:
##   * um mesmo "Exercise N" conter replicas de questoes-base diferentes em
##     partes distintas (colisao introduzida pelo particionamento);
##   * pares (Q,R) repetidos entre as partes.
## Alem disso, Q deve cobrir exatamente 1..N e o total de variantes deve ser
## N*n. Categorias customizadas (sem "Exercise N") sao metadados do conteudo:
## se duas questoes declaram a mesma seccao, a mescla ja aconteceria numa
## geracao em arquivo unico e, portanto, nao e responsabilidade do split.
validate_moodle_split_identity <- function(parts, total, n) {
  xml_lines <- unlist(lapply(parts, readLines, warn = FALSE, encoding = "UTF-8"),
                      use.names = FALSE)

  ## Parse sequencial: a categoria atual e a ultima linha <text>$course$...>;
  ## os nomes de variante registram (categoria, Q, R).
  current_cat <- NA_character_
  exercise_q <- integer()   ## Q global por "Exercise N" (chave = numero da categoria)
  custom_q <- list()        ## Qs por categoria customizada (apenas para aviso)
  questions <- integer()
  replicas <- integer()

  for (k in seq_along(xml_lines)) {
    line <- xml_lines[k]

    m_cat <- regmatches(
      line,
      regexec("<text>(\\$course\\$[^<]*)</text>", line, perl = TRUE)
    )[[1]]
    if (length(m_cat) > 0L) {
      current_cat <- m_cat[2]
      next
    }

    m_name <- regmatches(
      line,
      regexec("<text>[[:space:]]*R([0-9]+)[[:space:]]+Q([0-9]+)[[:space:]]*:",
              line, perl = TRUE)
    )[[1]]
    if (length(m_name) == 0L) next

    if (is.na(current_cat)) {
      stop("Moodle split identity error: variant found before any category in the XML parts")
    }

    r_local <- as.integer(m_name[2])
    q_local <- as.integer(m_name[3])
    questions <- c(questions, q_local)
    replicas <- c(replicas, r_local)

    ## Categoria "Exercise N": um mesmo N deve pertencer a uma unica questao.
    m_ex <- regmatches(
      current_cat,
      regexec("Exercise ([0-9]+)$", current_cat, perl = TRUE)
    )[[1]]
    if (length(m_ex) > 0L) {
      ex_num <- as.integer(m_ex[2])
      prev <- exercise_q[ex_num]
      if (is.na(prev)) {
        exercise_q[ex_num] <- q_local
      } else if (prev != q_local) {
        stop("Moodle split identity error: category '", current_cat,
             "' contains replicas of different base questions (Q", prev,
             " and Q", q_local, ")")
      }
    } else {
      ## Categoria customizada (exsection): apenas aviso se compartilhada.
      prev <- custom_q[[current_cat]]
      if (is.null(prev)) {
        custom_q[[current_cat]] <- q_local
      } else if (!q_local %in% prev) {
        custom_q[[current_cat]] <- c(prev, q_local)
        message("Moodle split identity note: custom category '", current_cat,
                "' is shared by base questions Q",
                paste(prev, collapse = ", Q"), " and Q", q_local,
                " - merging is inherent to the question content")
      }
    }
  }

  expected_questions <- seq_len(as.integer(total))
  if (!identical(sort(unique(questions)), expected_questions)) {
    stop("Moodle split identity error: Q numbering is not globally continuous (expected 1..",
         total, ")")
  }

  expected_variants <- as.integer(total) * as.integer(n)
  if (length(questions) != expected_variants) {
    stop("Moodle split identity error: expected ", expected_variants,
         " variants across parts, found ", length(questions))
  }

  keys <- paste(questions, replicas, sep = ":")
  if (anyDuplicated(keys)) {
    stop("Moodle split identity error: duplicate (Q,R) variant identity across XML parts")
  }

  invisible(TRUE)
}

## Gera o XML do Moodle para um conjunto de questoes, dividindo a saida em
## varias partes sempre que um unico arquivo excederia `max_bytes`.
##
## O comportamento para assuntos pequenos e identico ao exams2moodle puro
## (arquivo unico `name.xml`). Assuntos grandes sao repartidos em
## `name-part01.xml`, `name-part02.xml`, ... com cada parte dentro do limite.
## A divisao e transparente para a identidade Moodle: Exercise/Q mantem a
## numeracao global das questoes-base, mesmo quando cada parte e gerada por uma
## chamada independente a exams2moodle.
##
## Estrategia de particao: o tamanho do XML escala linearmente com o numero de
## variantes (medido com n=1 x2 x4 => ratio ~ n). Sonda-se o peso de cada
## questao com n=1 (geracao barata), agrupam-se as questoes ate o limite
## estimado e gera-se apenas UMA vez cada grupo final com `n` variantes.
##
## Garantia central: NENHUM arquivo retornado ultrapassa `max_bytes`. Uma
## questao cuja unica variante ainda exceda o limite nao pode ser repartida;
## o helper remove o arquivo e falha explicitamente em vez de devolver um XML
## acima do limite.
##
## Retorna um vetor de caracteres com os caminhos dos XML gerados.
generate_moodle_xml_limited <- function(files, n = 1L, name, seed, edir, dir,
                                        encoding = "UTF-8",
                                        converter = "pandoc-mathjax",
                                        max_bytes = moodle_size_limit(10),
                                        rule = "none",
                                        schoice = list(shuffle = TRUE)) {
  n <- as.integer(n)
  total <- length(files)
  if (total < 1L) stop("No question files to generate")

  if (!dir.exists(dir)) dir.create(dir, recursive = TRUE)

  ## Limpeza previa: remove XMLs antigos deste `name` para nao sobrar artefatos
  ## obsoletos quando um assunto muda entre uma parte unica e varias partes.
  clean_moodle_outputs(dir, name)

  run_exams <- function(sub_files, out_name, vn, seed_part,
                        question_offset = 0L, replica_offset = 0L) {
    set.seed(seed_part)
    args <- list(
      file = sub_files, n = vn, rule = rule, schoice = schoice,
      name = out_name, encoding = encoding, dir = dir, edir = edir
    )
    ## converter = NULL preserva o default do exams2moodle (blocos legados que
    ## nao declaravam converter); caso contrario, passa explicitamente.
    if (!is.null(converter)) args$converter <- converter
    do.call(exams2moodle, args)
    fp <- file.path(dir, paste0(out_name, ".xml"))
    rewrite_moodle_indices(
      fp, question_offset = question_offset, replica_offset = replica_offset
    )
    fp
  }

  ## Peso de cada questao com n=1 (probe barato). O tamanho de um grupo com
  ## `n` variantes e estimado como n * soma(weights), pois o XML escala
  ## ~linearmente com o numero de variantes.
  weight_file <- paste0(name, "__weight")
  weight <- vapply(files, function(f) {
    fp <- run_exams(f, weight_file, 1L, seed)
    w <- file.size(fp)
    unlink(fp)
    w
  }, numeric(1))

  ## Margem de seguranca de 5%: o criterio real e `max_bytes`, mas empacotar a
  ## 95% absorve o overhead dos blocos <question> e evita estouro na geracao.
  target <- max_bytes * 0.95

  ## Tentativa unica: se a estimativa cabe no alvo, gera um arquivo so. Se
  ## ainda assim passar do limite real (estimativa ligeiramente baixa), cai no
  ## particionamento.
  estimated_total <- n * sum(weight)
  if (estimated_total <= target) {
    single <- run_exams(files, name, n, seed)
    if (file.size(single) <= max_bytes) {
      return(single)
    }
    unlink(single)
  }

  ## nome de sonda efemero: as tentativas gravam em `__tmp` e a parte so recebe
  ## o nome sequencial definitivo ao ser aceita, evitando buracos na numeracao.
  tmp_name <- paste0(name, "__tmp")

  parts <- character()
  part_index <- 0L

  ## Faz o rename da sonda `fp` (no diretorio `dir`) para o nome sequencial da
  ## proxima parte e devolve o caminho final. Supoe que `fp` esta dentro de
  ## `dir`; usa o mesmo volume para nao quebrar com file.rename.
  accept_part <- function(fp) {
    part_index <<- part_index + 1L
    final_path <- file.path(dir, paste0(name, "-part", sprintf("%02d", part_index), ".xml"))
    if (!file.rename(fp, final_path)) {
      stop("Could not rename generated part to ", final_path)
    }
    final_path
  }

  ## Reparte as variantes de uma questao isolada que estoura o limite. Todas as
  ## partes preservam o mesmo Exercise/Q global; R continua entre as partes para
  ## evitar nomes de variantes duplicados. Sementes distintas evitam repeticao
  ## dos valores sorteados.
  split_single_variants <- function(single_file, w, question_index) {
    v_per_part <- max(1L, floor(target / w))
    remaining <- n
    while (remaining > 0L) {
      vn <- min(v_per_part, remaining)
      replica_offset <- n - remaining
      repeat {
        fp <- run_exams(
          single_file, tmp_name, vn, seed + part_index + 1L,
          question_offset = question_index - 1L,
          replica_offset = replica_offset
        )
        if (file.size(fp) <= max_bytes || vn <= 1L) break
        unlink(fp)
        vn <- max(1L, vn %/% 2L)
      }
      if (file.size(fp) > max_bytes) {
        ## Uma unica variante (n=1) ainda nao cabe no limite: impossivel
        ## repartir mais. Remove o arquivo e falha explicitamente.
        unlink(fp)
        stop("Question ", single_file, " still exceeds the ", max_bytes,
             " byte limit even with a single variant (n=1); cannot be split further")
      }
      parts <<- c(parts, accept_part(fp))
      remaining <- remaining - vn
    }
  }

  i <- 1L

  while (i <= total) {
    ## Agrupa questoes enquanto o tamanho estimado couber no alvo.
    acc <- 0
    j <- i
    g <- NA_integer_
    while (j <= total) {
      cand <- acc + weight[j] * n
      if (cand <= target) {
        acc <- cand
        g <- j
        j <- j + 1L
      } else {
        break
      }
    }

    ## Caso extremo: uma unica questao (com n variantes) ja estoura o limite.
    if (is.na(g)) {
      split_single_variants(files[i], weight[i], i)
      i <- i + 1L
      next
    }

    ## Gera o grupo final em sonda; garante o limite removendo a ultima questao
    ## caso a estimativa linear seja ligeiramente baixa; so aceita/numeera a
    ## parte quando couber. O offset i-1 preserva a identidade global.
    repeat {
      fp <- run_exams(
        files[i:g], tmp_name, n, seed,
        question_offset = i - 1L
      )
      if (file.size(fp) <= max_bytes) break
      unlink(fp)
      g <- g - 1L
      if (g < i) break
    }

    if (g < i) {
      ## Grupo encolheu para uma questao que continua estourando: reparte as
      ## variantes da questao isolada (mesmo tratamento do caso extremo).
      split_single_variants(files[i], weight[i], i)
      i <- i + 1L
    } else {
      parts <- c(parts, accept_part(fp))
      i <- g + 1L
    }
  }

  ## Falha antes de devolver arquivos importaveis se a divisao tiver alterado
  ## a identidade logica das questoes/replicas no Moodle.
  validate_moodle_split_identity(parts, total = total, n = n)
  parts
}
