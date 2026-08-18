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
## Este pos-processamento torna a divisao transparente: question_offset mapeia
## Exercise/Q locais para a posicao global do .Rnw no conjunto completo; em uma
## questao isolada repartida por variantes, replica_offset mantem R001, R002, ...
## continuos entre as partes.
rewrite_moodle_indices <- function(xml_file, question_offset = 0L,
                                   replica_offset = 0L) {
  question_offset <- as.integer(question_offset)
  replica_offset <- as.integer(replica_offset)
  if (question_offset == 0L && replica_offset == 0L) return(invisible(xml_file))

  lines <- readLines(xml_file, warn = FALSE, encoding = "UTF-8")

  for (k in seq_along(lines)) {
    line <- lines[k]

    ## Categoria do Moodle: $course$/<name>/Exercise N
    m_cat <- regexec(
      "(<text>\\$course\\$/[^<]*/Exercise )([0-9]+)(</text>)",
      line, perl = TRUE
    )
    hit_cat <- regmatches(line, m_cat)[[1]]
    if (length(hit_cat) > 0L) {
      global_q <- as.integer(hit_cat[3]) + question_offset
      replacement <- paste0(hit_cat[2], global_q, hit_cat[4])
      line <- sub(hit_cat[1], replacement, line, fixed = TRUE)
    }

    ## Nome da variante: <text> R001 Q1 : ... </text>
    m_name <- regexec(
      "(<text>[[:space:]]*)R([0-9]+)[[:space:]]+Q([0-9]+)([[:space:]]*:)",
      line, perl = TRUE
    )
    hit_name <- regmatches(line, m_name)[[1]]
    if (length(hit_name) > 0L) {
      local_r <- as.integer(hit_name[3])
      global_q <- as.integer(hit_name[4]) + question_offset
      global_r <- local_r + replica_offset
      r_width <- nchar(hit_name[3])
      r_text <- sprintf(paste0("%0", r_width, "d"), global_r)
      replacement <- paste0(hit_name[2], "R", r_text, " Q", global_q, hit_name[5])
      line <- sub(hit_name[1], replacement, line, fixed = TRUE)
    }

    lines[k] <- line
  }

  writeLines(lines, xml_file, useBytes = TRUE)
  invisible(xml_file)
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

  parts
}
