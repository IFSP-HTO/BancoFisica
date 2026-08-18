FROM rocker/r-ver:4.4.3

ENV DEBIAN_FRONTEND=noninteractive \
    TZ=Etc/UTC \
    R_KEEP_PKG_SOURCE=yes \
    NOT_CRAN=true \
    MAKEFLAGS=-j2

RUN apt-get update -qq \
    && apt-get install -y --no-install-recommends \
        build-essential \
        ca-certificates \
        file \
        gfortran \
        git \
        libbz2-dev \
        libcurl4-openssl-dev \
        libfontconfig1-dev \
        libfreetype6-dev \
        libicu-dev \
        libjpeg-dev \
        liblzma-dev \
        libpng-dev \
        libssl-dev \
        libtiff-dev \
        libuv1-dev \
        libxml2-dev \
        libzstd-dev \
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
        zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

COPY DESCRIPTION /tmp/BancoFisica-DESCRIPTION

RUN Rscript -e 'options(repos = c(CRAN = "https://cloud.r-project.org"), timeout = 600, Ncpus = 2L); d <- read.dcf("/tmp/BancoFisica-DESCRIPTION"); fields <- intersect(c("Imports", "Suggests"), colnames(d)); deps <- unique(unlist(strsplit(paste(d[1, fields], collapse = ","), ","))); deps <- trimws(gsub("\\s*\\([^)]*\\)", "", deps)); deps <- deps[nzchar(deps) & deps != "tools"]; message("BancoFisica direct R dependencies: ", paste(deps, collapse = ", ")); install.packages(deps, dependencies = c("Depends", "Imports", "LinkingTo"), Ncpus = 2L); missing <- deps[!vapply(deps, requireNamespace, logical(1), quietly = TRUE)]; if (length(missing)) { message("Retrying missing R packages serially: ", paste(missing, collapse = ", ")); for (pkg in missing) install.packages(pkg, dependencies = c("Depends", "Imports", "LinkingTo"), Ncpus = 1L) }; missing <- deps[!vapply(deps, requireNamespace, logical(1), quietly = TRUE)]; if (length(missing)) stop("Missing R packages after retry: ", paste(missing, collapse = ", "))'

RUN Rscript -e 'stopifnot(getRversion() == package_version("4.4.3")); pkgs <- c("exams", "stringr", "magrittr", "purrr", "callr", "tth", "base64enc", "testthat", "shiny", "xml2"); missing <- pkgs[!vapply(pkgs, requireNamespace, logical(1), quietly = TRUE)]; if (length(missing)) stop("CI image validation missing R packages: ", paste(missing, collapse = ", ")); message("Validated R packages: ", paste(pkgs, collapse = ", "))'

RUN latexmk -v >/dev/null \
    && qpdf --version >/dev/null \
    && pandoc --version >/dev/null \
    && python3 --version >/dev/null \
    && file --version >/dev/null

WORKDIR /workspace
