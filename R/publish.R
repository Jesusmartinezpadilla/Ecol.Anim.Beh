# Uso desde la consola de R / RStudio:  source("R/publish.R")
#   preview()                    -> vista previa local (se refresca al guardar)
#   update_site("mensaje")       -> git add + commit + push; GitHub publica la web

preview <- function() {
  if (!requireNamespace("quarto", quietly = TRUE)) stop("Instala el paquete: install.packages('quarto')")
  quarto::quarto_preview()
}

build <- function() {
  if (!requireNamespace("quarto", quietly = TRUE)) stop("Instala el paquete: install.packages('quarto')")
  quarto::quarto_render()
}

update_site <- function(msg = paste("Update website", Sys.Date())) {
  system2("git", c("add", "-A"))
  if (system2("git", c("diff", "--cached", "--quiet")) == 0) {
    message("No hay cambios que subir.")
    return(invisible(FALSE))
  }
  system2("git", c("commit", "-m", shQuote(msg)))
  system2("git", "push")
  message("Cambios subidos. GitHub Actions publicará la web en unos minutos.")
  invisible(TRUE)
}
