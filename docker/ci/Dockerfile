FROM rocker/r-ver:4.4.3

ENV DEBIAN_FRONTEND=noninteractive \
    TZ=Etc/UTC \
    R_KEEP_PKG_SOURCE=yes \
    NOT_CRAN=true

RUN apt-get update -qq \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        file \
        git \
        libcurl4-openssl-dev \
        libfontconfig1-dev \
        libfreetype6-dev \
        libjpeg-dev \
        libpng-dev \
        libssl-dev \
        libtiff-dev \
        libxml2-dev \
        latexmk \
        pandoc \
        python3 \
        qpdf \
        texlive-fonts-recommended \
        texlive-lang-portuguese \
        texlive-latex-base \
        texlive-latex-extra \
        texlive-latex-recommended \
        tth \
    && rm -rf /var/lib/apt/lists/*

COPY DESCRIPTION /tmp/BancoFisica-DESCRIPTION

RUN Rscript -e 'options(repos = c(CRAN = "https://cloud.r-project.org")); d <- read.dcf("/tmp/BancoFisica-DESCRIPTION"); fields <- c("Imports", "Suggests"); deps <- unique(unlist(strsplit(paste(d[1, fields], collapse = ","), ","))); deps <- trimws(gsub("\\s*\\([^)]*\\)", "", deps)); deps <- deps[nzchar(deps) & deps != "tools"]; install.packages(deps, Ncpus = max(1L, parallel::detectCores() - 1L)); missing <- deps[!vapply(deps, requireNamespace, logical(1), quietly = TRUE)]; if (length(missing)) stop("Missing R packages: ", paste(missing, collapse = ", "))'

RUN Rscript -e 'stopifnot(getRversion() == package_version("4.4.3")); pkgs <- c("exams", "stringr", "magrittr", "purrr", "callr", "tth", "base64enc", "testthat", "shiny", "xml2"); stopifnot(all(vapply(pkgs, requireNamespace, logical(1), quietly = TRUE)))' \
    && latexmk -v >/dev/null \
    && qpdf --version >/dev/null \
    && pandoc --version >/dev/null \
    && python3 --version >/dev/null

WORKDIR /workspace
