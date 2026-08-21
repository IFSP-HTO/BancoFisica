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

parse_test_profile <- function(env_var = "BANK_TEST_PROFILE", default = "full") {
  profile <- trimws(tolower(Sys.getenv(env_var, unset = default)))
  if (!profile %in% c("full", "asset")) {
    stop("Invalid ", env_var, ": use 'full' or 'asset'")
  }
  profile
}

parse_bool_env <- function(env_var, default = FALSE) {
  raw <- trimws(tolower(Sys.getenv(env_var, unset = "")))
  if (!nzchar(raw)) return(isTRUE(default))
  if (raw %in% c("1", "true", "yes", "on")) return(TRUE)
  if (raw %in% c("0", "false", "no", "off")) return(FALSE)
  stop("Invalid ", env_var, ": use 1/0, true/false, yes/no, or on/off")
}

local_environment_fingerprint <- function() {
  command_head <- function(command, args = character()) {
    tryCatch({
      out <- suppressWarnings(system2(command, args, stdout = TRUE, stderr = TRUE))
      if (length(out) == 0L) return("unknown")
      gsub("[[:space:]]+", "_", trimws(out[[1L]]))
    }, error = function(e) "unavailable")
  }

  paste(
    paste0("R-", getRversion()),
    paste0("exams-", as.character(utils::packageVersion("exams"))),
    paste0("pandoc-", command_head("pandoc", "--version")),
    paste0("latexmk-", command_head("latexmk", "-v")),
    sep = "|"
  )
}

new_cache_stats <- function() {
  stats <- new.env(parent = emptyenv())
  stats$hits <- 0L
  stats$misses <- 0L
  stats$writes <- 0L
  stats$executed <- 0L
  stats$bypassed <- 0L
  stats
}

prepare_compile_cache <- function(files) {
  enabled <- parse_bool_env("BANK_COMPILE_CACHE", default = FALSE)
  cache_dir <- Sys.getenv("BANK_CACHE_DIR", unset = ".cache/bancofisica-ci")
  stats <- new_cache_stats()

  if (parse_bool_env("BANK_CACHE_CLEAR", default = FALSE) && dir.exists(cache_dir)) {
    unlink(cache_dir, recursive = TRUE, force = TRUE)
    message("Compile cache cleared: ", cache_dir)
  }

  context <- list(
    enabled = enabled,
    cache_dir = cache_dir,
    environment = "disabled",
    base_fingerprints = character(),
    stats = stats,
    reason = if (enabled) "initializing" else "BANK_COMPILE_CACHE disabled"
  )

  if (!enabled || length(files) == 0L) {
    return(context)
  }

  dir.create(cache_dir, recursive = TRUE, showWarnings = FALSE)
  environment <- Sys.getenv("BANK_CACHE_ENV_FINGERPRINT", unset = "")
  if (!nzchar(environment)) {
    environment <- local_environment_fingerprint()
  }

  manifest <- tempfile("bank-cache-manifest-", fileext = ".txt")
  output <- tempfile("bank-cache-fingerprints-", fileext = ".tsv")
  writeLines(files, manifest, useBytes = TRUE)
  on.exit(unlink(c(manifest, output), force = TRUE), add = TRUE)

  args <- c(
    "tools/ci_compile_cache.py",
    "--manifest", shQuote(manifest),
    "--output", shQuote(output),
    "--environment", shQuote(environment)
  )
  status <- tryCatch(
    system2("python3", args),
    error = function(e) {
      warning("Compile-cache fingerprint helper failed: ", conditionMessage(e))
      1L
    }
  )

  if (!identical(as.integer(status), 0L) || !file.exists(output)) {
    warning("Compile cache disabled for this run because fingerprints could not be generated")
    context$enabled <- FALSE
    context$reason <- "fingerprint generation failed; safe fallback to compilation"
    return(context)
  }

  table <- tryCatch(
    utils::read.delim(output, stringsAsFactors = FALSE, check.names = FALSE),
    error = function(e) NULL
  )
  if (is.null(table) || !all(c("question", "fingerprint") %in% names(table)) ||
      nrow(table) != length(files)) {
    warning("Compile cache disabled: invalid fingerprint table")
    context$enabled <- FALSE
    context$reason <- "invalid fingerprint table; safe fallback to compilation"
    return(context)
  }

  context$environment <- environment
  context$base_fingerprints <- stats::setNames(table$fingerprint, table$question)
  context$reason <- "content-addressed cache enabled"
  message("Compile cache enabled: ", cache_dir, " (", length(files), " question fingerprint(s))")
  context
}

cache_enabled <- function(cache) {
  !is.null(cache) && isTRUE(cache$enabled)
}

cache_task_key <- function(cache, task) {
  if (!cache_enabled(cache)) return(NULL)
  base <- unname(cache$base_fingerprints[task$question])
  if (length(base) != 1L || is.na(base) || !nzchar(base)) return(NULL)
  paste0(base, "-", task$formato, "-seed-", as.integer(task$seed))
}

cache_entry_path <- function(cache, key) {
  file.path(cache$cache_dir, substr(key, 1L, 2L), paste0(key, ".rds"))
}

read_cache_entry <- function(cache, key) {
  path <- cache_entry_path(cache, key)
  if (!file.exists(path)) return(NULL)

  entry <- tryCatch(readRDS(path), error = function(e) NULL)
  valid <- is.list(entry) && identical(entry$schema, "bancofisica-cache-rds-v1") &&
    identical(entry$key, key) && is.list(entry$result) && isTRUE(entry$result$ok)
  if (!valid) {
    unlink(path, force = TRUE)
    return(NULL)
  }
  entry$result
}

write_cache_entry <- function(cache, key, result) {
  if (!cache_enabled(cache) || !isTRUE(result$ok)) return(FALSE)
  path <- cache_entry_path(cache, key)
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  tmp <- tempfile("cache-entry-", tmpdir = dirname(path), fileext = ".rds")
  entry <- list(
    schema = "bancofisica-cache-rds-v1",
    key = key,
    result = result
  )
  saveRDS(entry, tmp, version = 3)
  ok <- file.rename(tmp, path)
  if (!ok) unlink(tmp, force = TRUE)
  isTRUE(ok)
}

write_compile_cache_report <- function(cache) {
  dir.create("build/compile-cache", recursive = TRUE, showWarnings = FALSE)
  stats <- cache$stats
  report <- data.frame(
    enabled = isTRUE(cache$enabled),
    reason = as.character(cache$reason),
    hits = as.integer(stats$hits),
    misses = as.integer(stats$misses),
    writes = as.integer(stats$writes),
    executed = as.integer(stats$executed),
    bypassed = as.integer(stats$bypassed),
    cache_dir = as.character(cache$cache_dir),
    environment = as.character(cache$environment),
    stringsAsFactors = FALSE
  )
  utils::write.csv(
    report, "build/compile-cache/summary.csv",
    row.names = FALSE, fileEncoding = "UTF-8"
  )
  message(
    "Compile cache summary: enabled=", report$enabled,
    "; hits=", report$hits,
    "; misses=", report$misses,
    "; executed=", report$executed,
    "; writes=", report$writes,
    "; bypassed=", report$bypassed
  )
  invisible(report)
}

run_compile_tasks <- function(tasks, jobs, cache = NULL) {
  if (length(tasks) == 0L) {
    return(list())
  }

  results <- vector("list", length(tasks))
  miss_indices <- integer()

  for (i in seq_along(tasks)) {
    if (!cache_enabled(cache)) {
      cache$stats$bypassed <- cache$stats$bypassed + 1L
      miss_indices <- c(miss_indices, i)
      next
    }

    key <- cache_task_key(cache, tasks[[i]])
    tasks[[i]]$cache_key <- key
    cached <- if (is.null(key)) NULL else read_cache_entry(cache, key)
    if (!is.null(cached)) {
      results[[i]] <- cached
      cache$stats$hits <- cache$stats$hits + 1L
    } else {
      cache$stats$misses <- cache$stats$misses + 1L
      miss_indices <- c(miss_indices, i)
    }
  }

  if (cache_enabled(cache)) {
    message(
      "Compile cache lookup: ", cache$stats$hits, " cumulative hit(s), ",
      cache$stats$misses, " cumulative miss(es)"
    )
  }

  if (length(miss_indices) == 0L) {
    return(results)
  }

  tasks_to_run <- tasks[miss_indices]
  cache$stats$executed <- cache$stats$executed + length(tasks_to_run)

  compile_one <- function(task) {
    compilar_isolado(
      task$arquivo, task$diretorio, task$formato, task$ano, task$seed
    )
  }

  if (jobs <= 1L || length(tasks_to_run) == 1L) {
    fresh <- lapply(tasks_to_run, compile_one)
  } else {
    workers <- min(as.integer(jobs), length(tasks_to_run))
    message("Running ", length(tasks_to_run), " isolated compilation(s) with ",
            workers, " worker(s)")

    cl <- parallel::makeCluster(workers, type = "PSOCK")
    on.exit(parallel::stopCluster(cl), add = TRUE)
    parallel::clusterExport(cl, "compilar_isolado", envir = .GlobalEnv)
    fresh <- parallel::parLapplyLB(cl, tasks_to_run, function(task) {
      compilar_isolado(
        task$arquivo, task$diretorio, task$formato, task$ano, task$seed
      )
    })
  }

  for (j in seq_along(miss_indices)) {
    i <- miss_indices[[j]]
    result <- fresh[[j]]
    results[[i]] <- result
    key <- tasks[[i]]$cache_key
    if (!is.null(key) && write_cache_entry(cache, key, result)) {
      cache$stats$writes <- cache$stats$writes + 1L
    }
  }

  results
}

generate_xml_parallel <- function(
    files = get_bank_test_files(), jobs = parse_jobs(), profile = parse_test_profile(),
    cache = NULL) {
  if (length(files) == 0L) {
    message("No affected questions: skipping Moodle XML compilation")
    return(invisible(NULL))
  }

  ## Full + serial delegates to the historical implementation unchanged when
  ## cache is disabled. With cache enabled, even serial execution uses tasks.
  if (jobs <= 1L && identical(profile, "full") && !cache_enabled(cache)) {
    return(generate_xml(files))
  }

  arquivos <- data.frame(file = files, stringsAsFactors = FALSE)
  ano <- 2018
  xml_seeds <- parse_seed_list()
  if (identical(profile, "asset")) {
    xml_seeds <- xml_seeds[1L]
  }
  message(
    "Validating Moodle XML with profile=", profile,
    " and seeds: ", paste(xml_seeds, collapse = ", ")
  )

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
      question = arquivos$file[i],
      arquivo = arquivo,
      diretorio = dirname(arquivo),
      formato = "xml",
      ano = ano,
      seed = as.integer(plano$seed[j])
    )
  })

  resultados <- run_compile_tasks(tasks, jobs, cache = cache)

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

generate_pdf_parallel <- function(
    files = get_bank_test_files(), jobs = parse_jobs(), cache = NULL) {
  if (length(files) == 0L) {
    message("No affected questions: skipping PDF compilation")
    return(invisible(NULL))
  }

  ## BANK_JOBS=1 delegates to the canonical implementation when cache is off.
  if (jobs <= 1L && !cache_enabled(cache)) {
    return(generate_pdf(files))
  }

  arquivos <- data.frame(file = files, stringsAsFactors = FALSE)
  ano <- 2018

  tasks <- lapply(seq_len(nrow(arquivos)), function(i) {
    arquivo <- normalizePath(arquivos$file[i])
    list(
      file_index = i,
      question = arquivos$file[i],
      arquivo = arquivo,
      diretorio = dirname(arquivo),
      formato = "pdf",
      ano = ano,
      seed = i
    )
  })

  resultados <- run_compile_tasks(tasks, jobs, cache = cache)
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
bank_test_profile <- parse_test_profile()
compile_cache <- prepare_compile_cache(question_files)
message(
  "BancoFisica CI mode: ", bank_test_mode,
  " (", length(question_files), " question(s) selected; ",
  "BANK_JOBS=", bank_jobs, "; profile=", bank_test_profile,
  "; cache=", if (cache_enabled(compile_cache)) "on" else "off", ")"
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
generate_xml_parallel(
  question_files, jobs = bank_jobs, profile = bank_test_profile,
  cache = compile_cache
)
generate_pdf_parallel(question_files, jobs = bank_jobs, cache = compile_cache)
write_compile_cache_report(compile_cache)
