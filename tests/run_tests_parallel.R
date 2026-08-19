## Parallel runner for the existing BancoFisica test definitions.
##
## tests/tests.R intentionally remains the canonical definition of the checks.
## This runner loads only its function definitions (everything before the
## execution marker) and replaces the sequential XML/PDF compilation loops with
## a configurable PSOCK worker pool. Each worker still calls compilar_isolado(),
## so every actual exams2moodle/exams2pdf invocation remains in its own callr
## subprocess.

load_test_definitions <- function(path = "tests/tests.R") {
  lines <- readLines(path, encoding = "UTF-8", warn = FALSE)
  marker <- grep("^## Rodando as funções[[:space:]]*$", lines)
  if (length(marker) != 1L) {
    stop("Could not locate the execution marker in ", path)
  }

  eval(parse(text = lines[seq_len(marker - 1L)]), envir = .GlobalEnv)
}

parse_jobs <- function(env_var = "BANK_JOBS", default = 1L) {
  raw <- Sys.getenv(env_var, unset = "")
  if (!nzchar(raw)) {
    return(as.integer(default))
  }

  jobs <- suppressWarnings(as.integer(raw))
  if (length(jobs) != 1L || is.na(jobs) || jobs < 1L) {
    stop("Invalid ", env_var, ": use a positive integer, e.g. 1,2,4")
  }
  jobs
}

run_compile_tasks <- function(tasks, jobs) {
  if (length(tasks) == 0L) {
    return(list())
  }

  if (jobs <= 1L || length(tasks) == 1L) {
    return(lapply(tasks, function(task) {
      compilar_isolado(
        task$arquivo, task$diretorio, task$formato, task$ano, task$seed
      )
    }))
  }

  workers <- min(as.integer(jobs), length(tasks))
  message("Running ", length(tasks), " isolated compilation(s) with ",
          workers, " worker(s)")

  cl <- parallel::makeCluster(workers, type = "PSOCK")
  on.exit(parallel::stopCluster(cl), add = TRUE)

  parallel::clusterExport(cl, "compilar_isolado", envir = .GlobalEnv)

  parallel::parLapplyLB(cl, tasks, function(task) {
    compilar_isolado(
      task$arquivo, task$diretorio, task$formato, task$ano, task$seed
    )
  })
}

generate_xml_parallel <- function(files = get_bank_test_files(), jobs = parse_jobs()) {
  if (length(files) == 0L) {
    message("No affected questions: skipping Moodle XML compilation")
    return(invisible(NULL))
  }

  ## BANK_JOBS=1 delegates to the canonical implementation byte-for-byte.
  if (jobs <= 1L) {
    return(generate_xml(files))
  }

  arquivos <- data.frame(file = files, stringsAsFactors = FALSE)
  ano <- 2018
  xml_seeds <- parse_seed_list()
  message("Validating Moodle XML with seeds: ", paste(xml_seeds, collapse = ", "))

  plano <- expand.grid(
    file_index = seq_len(nrow(arquivos)),
    seed = xml_seeds,
    KEEP.OUT.ATTRS = FALSE
  )

  tasks <- lapply(seq_len(nrow(plano)), function(j) {
    i <- plano$file_index[j]
    arquivo <- normalizePath(arquivos$file[i])
    list(
      file_index = i,
      arquivo = arquivo,
      diretorio = dirname(arquivo),
      formato = "xml",
      ano = ano,
      seed = as.integer(plano$seed[j])
    )
  })

  resultados <- run_compile_tasks(tasks, jobs)

  xml_report <- do.call(rbind, lapply(seq_along(resultados), function(j) {
    i <- tasks[[j]]$file_index
    res <- resultados[[j]]
    data.frame(
      file = arquivos$file[i],
      seed = tasks[[j]]$seed,
      ok = isTRUE(res$ok),
      message = as.character(res$message),
      xml_file = as.character(res$xml_file),
      xml_bytes = as.numeric(res$xml_bytes),
      xml_questions = as.integer(res$xml_questions),
      quiz_tags = as.integer(res$quiz_tags),
      raw_question_tags = as.integer(res$raw_question_tags),
      stringsAsFactors = FALSE
    )
  }))

  if (!dir.exists("build/moodle-xml")) {
    dir.create("build/moodle-xml", recursive = TRUE)
  }
  write.csv(xml_report, "build/moodle-xml/xml-validation.csv",
            row.names = FALSE, fileEncoding = "UTF-8")

  ind_xml <- which(!xml_report$ok)
  if (length(ind_xml) > 0L) {
    erro <- paste(
      "NÃO COMPILA OU NÃO VALIDA PARA XML:",
      xml_report$file[ind_xml],
      "seed", xml_report$seed[ind_xml],
      xml_report$message[ind_xml], "\n"
    )
    stop(erro)
  }
}

generate_pdf_parallel <- function(files = get_bank_test_files(), jobs = parse_jobs()) {
  if (length(files) == 0L) {
    message("No affected questions: skipping PDF compilation")
    return(invisible(NULL))
  }

  ## BANK_JOBS=1 delegates to the canonical implementation byte-for-byte.
  if (jobs <= 1L) {
    return(generate_pdf(files))
  }

  arquivos <- data.frame(file = files, stringsAsFactors = FALSE)
  ano <- 2018

  tasks <- lapply(seq_len(nrow(arquivos)), function(i) {
    arquivo <- normalizePath(arquivos$file[i])
    list(
      file_index = i,
      arquivo = arquivo,
      diretorio = dirname(arquivo),
      formato = "pdf",
      ano = ano,
      seed = i
    )
  })

  resultados <- run_compile_tasks(tasks, jobs)
  ok <- vapply(resultados, function(res) isTRUE(res$ok), logical(1))

  ind_pdf <- which(!ok)
  if (length(ind_pdf) > 0L) {
    erro <- paste(
      "NÃO COMPILA PARA PDF:",
      arquivos$file[ind_pdf], "\n"
    )
    stop(erro)
  }
}

## Load all canonical checks without executing their serial runner.
load_test_definitions()

bank_test_mode <- Sys.getenv("BANK_TEST_MODE", unset = "full")
question_files <- get_bank_test_files()
bank_jobs <- parse_jobs()
message(
  "BancoFisica CI mode: ", bank_test_mode,
  " (", length(question_files), " question(s) selected; ",
  "BANK_JOBS=", bank_jobs, ")"
)

check_bank_structure()
check_question_counts()

## These checks exercise shared infrastructure and perform additional
## compilations. They remain full-mode checks exactly as in tests/tests.R.
if (identical(bank_test_mode, "full")) {
  check_moodle_split()
  check_moodle_split_oversize()
} else {
  message("Incremental CI: skipping shared Moodle split regression checks")
}

check_encoding(question_files)
generate_xml_parallel(question_files, jobs = bank_jobs)
generate_pdf_parallel(question_files, jobs = bank_jobs)
