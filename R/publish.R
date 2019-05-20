publicar <- function(arquivo) {
  rmarkdown::render(input = paste0("rmarkdown/", arquivo), 
                    output_file = "README.md")
  file.remove("README.md")
  file.copy(from = "rmarkdown/README.md", to = ".")
  file.copy(from = "rmarkdown/README.md", to = "docs/README.md")
}


