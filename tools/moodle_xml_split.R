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

## Gera o XML do Moodle para um conjunto de questoes, dividindo a saida em
## varias partes sempre que um unico arquivo excederia `max_bytes`.
##
## O comportamento para assuntos pequenos e identico ao exams2moodle puro
## (arquivo unico `name.xml`). Assuntos grandes sao repartidos em
## `name-part01.xml`, `name-part02.xml`, ... com cada parte dentro do limite.
##
## Estrategia de particao: o tamanho do XML escala linearmente com o numero de
## variantes (medido com n=1 x2 x4 => ratio ~ n). Sonda-se o peso de cada
## questao com n=1 (geracao barata), agrupam-se as questoes ate o limite
## estimado e gera-se apenas UMA vez cada grupo final com `n` variantes.
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

  run_exams <- function(sub_files, out_name, vn, seed_part) {
    set.seed(seed_part)
    args <- list(
      file = sub_files, n = vn, rule = rule, schoice = schoice,
      name = out_name, encoding = encoding, dir = dir, edir = edir
    )
    ## converter = NULL preserva o default do exams2moodle (blocos legados que
    ## nao declaravam converter); caso contrario, passa explicitamente.
    if (!is.null(converter)) args$converter <- converter
    do.call(exams2moodle, args)
    file.path(dir, paste0(out_name, ".xml"))
  }

  ## 2) Peso de cada questao com n=1 (probe barato). O tamanho final para um
  ##    grupo com `n` variantes e estimado como n * soma(weights), pois o XML
  ##    escala ~linearmente com o numero de variantes.
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

  ## 1) Tentativa unica: se a estimativa cabe no alvo, gera um arquivo so e
  ##    valida contra o limite real. Assuntos que claramente estourariam pulam
  ##    essa geracao descartavel e vao direto para a particao (passo 3).
  estimated_total <- n * sum(weight)
  if (estimated_total <= target) {
    single <- run_exams(files, name, n, seed)
    if (file.size(single) <= max_bytes) {
      return(single)
    }
    unlink(single)
  }

  part_name <- function(index) paste0(name, "-part", sprintf("%02d", index))

  parts <- character()
  part_index <- 0L
  i <- 1L

  while (i <= total) {
    ## 3) Agrupa questoes enquanto o tamanho estimado couber no alvo.
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

    ## 4) Caso extremo: uma unica questao (com n variantes) ja estoura o
    ##    limite. Divide as variantes da questao em partes. Sementes mudam por
    ##    parte para nao repetir as mesmas variantes entre arquivos.
    if (is.na(g)) {
      single_file <- files[i]
      w <- weight[i]
      v_per_part <- max(1L, floor(target / w))
      remaining <- n
      while (remaining > 0L) {
        part_index <- part_index + 1L
        vn <- min(v_per_part, remaining)
        repeat {
          fp <- run_exams(single_file, part_name(part_index), vn, seed + part_index)
          if (file.size(fp) <= max_bytes || vn <= 1L) break
          unlink(fp)
          vn <- max(1L, vn %/% 2L)
        }
        parts <- c(parts, fp)
        remaining <- remaining - vn
      }
      i <- i + 1L
      next
    }

    ## 5) Gera o grupo final uma unica vez; garante o limite removendo a ultima
    ##    questao caso a estimativa linear seja ligeiramente baixa.
    repeat {
      part_index <- part_index + 1L
      fp <- run_exams(files[i:g], part_name(part_index), n, seed)
      if (file.size(fp) <= max_bytes) break
      unlink(fp)
      g <- g - 1L
      if (g < i) break
    }

    if (g < i) {
      ## Grupo colapsou para uma unica questao que ainda estoura: repete o caso
      ## extremo (4) para files[i] e reinicia o grupo seguinte em i + 1.
      single_file <- files[i]
      w <- weight[i]
      v_per_part <- max(1L, floor(target / w))
      remaining <- n
      while (remaining > 0L) {
        part_index <- part_index + 1L
        vn <- min(v_per_part, remaining)
        repeat {
          fp <- run_exams(single_file, part_name(part_index), vn, seed + part_index)
          if (file.size(fp) <= max_bytes || vn <= 1L) break
          unlink(fp)
          vn <- max(1L, vn %/% 2L)
        }
        parts <- c(parts, fp)
        remaining <- remaining - vn
      }
      i <- i + 1L
    } else {
      parts <- c(parts, fp)
      i <- g + 1L
    }
  }

  parts
}