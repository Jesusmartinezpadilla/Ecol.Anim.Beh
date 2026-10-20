# Funciones que convierten los CSV de data/ en contenido para las páginas.
# Solo R base. Cada función escribe Markdown (cat) para usarse con results='asis'.

read_data <- function(file, required = NULL) {
  path <- file.path("data", file)
  if (!file.exists(path)) return(data.frame())
  # Excel en español guarda los CSV con ";" como separador: lo detectamos solo.
  first <- readLines(path, n = 1, warn = FALSE, encoding = "UTF-8")
  sep <- if (lengths(regmatches(first, gregexpr(";", first))) >
             lengths(regmatches(first, gregexpr(",", first)))) ";" else ","
  df <- utils::read.csv(path, sep = sep, stringsAsFactors = FALSE, na.strings = c("", "NA"),
                        fileEncoding = "UTF-8-BOM", colClasses = "character")
  names(df) <- tolower(trimws(names(df)))
  missing <- setdiff(required, names(df))
  if (length(missing) > 0)
    stop(file, ": faltan las columnas ", paste(missing, collapse = ", "),
         ". Columnas encontradas: ", paste(names(df), collapse = ", "), call. = FALSE)
  df
}

val <- function(x) { x <- as.character(x); x[is.na(x)] <- ""; trimws(x) }

md_link <- function(label, url) if (nzchar(url)) sprintf("[%s](%s)", label, url) else ""

join_parts <- function(...) { p <- c(...); p <- p[nzchar(p)]; paste(p, collapse = " · ") }

by_year <- function(d, entry_fn) {
  if (nrow(d) == 0) return(invisible(NULL))
  d <- d[order(-suppressWarnings(as.integer(val(d$year))), na.last = FALSE), , drop = FALSE]  # "In review" va primero
  for (y in unique(val(d$year))) {
    cat("\n\n### ", y, "\n\n", sep = "")
    dd <- d[val(d$year) == y, , drop = FALSE]
    for (i in seq_len(nrow(dd))) entry_fn(dd[i, , drop = FALSE])
  }
}

# ---- Home ----
glance <- function() {
  pubs <- read_data("publications.csv"); team <- read_data("team.csv"); pr <- read_data("projects.csv")
  items <- list(
    list(sum(val(pubs$type) == "sci"), "SCI articles"),
    list(nrow(team), "Group members"),
    list(sum(active_flags(pr)), "Active projects"))
  cat("\n::: {.stats}\n\n")
  for (it in items) cat("::: {.stat}\n**", it[[1]], "**\n\n", it[[2]], "\n:::\n\n", sep = "")
  cat(":::\n\n")
}

news_list <- function(n = 4) {
  df <- read_data("news.csv")
  if (nrow(df) == 0) return(invisible(NULL))
  df <- df[order(val(df$date), decreasing = TRUE), , drop = FALSE]
  df <- utils::head(df, n)
  for (i in seq_len(nrow(df))) {
    r <- df[i, , drop = FALSE]
    cat("\n::: {.news-item}\n\n[", val(r$date), "]{.date}\n\n**", val(r$title), "**\n\n", val(r$text), " ",
        md_link("More", val(r$url)), "\n\n:::\n", sep = "")
  }
}

# ---- Team ----
team_cards <- function() {
  df <- read_data("team.csv")
  if (nrow(df) == 0) return(invisible(NULL))
  for (g in unique(val(df$group))) {
    d <- df[val(df$group) == g, , drop = FALSE]
    cat("\n\n## ", g, "\n\n::: {.people}\n\n", sep = "")
    for (i in seq_len(nrow(d))) {
      r <- d[i, , drop = FALSE]
      photo <- val(r$photo); if (!nzchar(photo)) photo <- "images/placeholder.svg"
      email <- val(r$email)
      cat("::: {.person}\n\n",
          "<img class=\"photo\" src=\"", photo, "\" alt=\"", val(r$name), "\">\n\n",
          "**", val(r$name), "**\n\n", val(r$role), "\n\n", val(r$bio), "\n\n",
          join_parts(md_link("Email", if (nzchar(email)) paste0("mailto:", email) else ""),
                     md_link("Web", val(r$web))), "\n\n:::\n\n", sep = "")
    }
    cat(":::\n\n")
  }
}

# ---- Projects ----
# projects.csv: group (secciones, como en el CV), period, amount, citation (resto de la
# entrada en Markdown: tipo, título en *cursiva*, financiador, IP...) y url (opcional).
project_entry <- function(r, active) {
  amount <- val(r$amount)
  badge <- if (active) " [Active]{.badge-active}" else ""
  head <- paste0("**", val(r$period), "**", badge, if (nzchar(amount)) paste0(" ", amount, ".") else "")
  cat("::: {.entry data-active=\"", tolower(active), "\"}\n", head, " ", val(r$citation), " ",
      md_link("Link", val(r$url)), "\n:::\n\n", sep = "")
}

# Un proyecto está activo si su periodo termina este año o después.
# Opcional: la columna `active` del CSV (yes/no) tiene prioridad sobre el cálculo.
is_active <- function(r) {
  a <- tolower(val(r$active))
  if (length(a) == 1 && nzchar(a)) return(a %in% c("yes", "y", "true", "1", "si", "sí"))
  ey <- end_year(val(r$period))
  !is.na(ey) && ey >= as.integer(format(Sys.Date(), "%Y"))
}

active_flags <- function(df) {
  vapply(seq_len(nrow(df)), function(i) is_active(df[i, , drop = FALSE]), logical(1))
}

project_sections <- function() {
  df <- read_data("projects.csv", required = c("group", "period", "citation"))
  flags <- active_flags(df)
  cat("\n```{=html}\n<div class=\"proj-filter\" role=\"group\" aria-label=\"Filter projects\">",
      "<button type=\"button\" class=\"on\" data-f=\"all\">All projects (", nrow(df), ")</button>",
      "<button type=\"button\" data-f=\"active\">Active only (", sum(flags), ")</button></div>\n```\n\n", sep = "")
  for (g in unique(val(df$group))) {
    idx <- which(val(df$group) == g)
    cat("\n\n## ", g, "\n\n", sep = "")
    for (i in idx) project_entry(df[i, , drop = FALSE], flags[i])
  }
  cat("\n```{=html}\n<script>\n(function(){\n",
      "var btns=document.querySelectorAll('.proj-filter button');\n",
      "function apply(f){\n",
      "  document.querySelectorAll('.entry[data-active]').forEach(function(e){e.hidden=(f==='active'&&e.dataset.active!=='true');});\n",
      "  document.querySelectorAll('section.level2').forEach(function(s){\n",
      "    var es=s.querySelectorAll('.entry[data-active]'); if(!es.length) return;\n",
      "    s.hidden=![].some.call(es,function(e){return !e.hidden;});\n",
      "  });\n",
      "  btns.forEach(function(x){x.classList.toggle('on',x.dataset.f===f);});\n",
      "}\n",
      "btns.forEach(function(x){x.addEventListener('click',function(){apply(x.dataset.f);});});\n",
      "})();\n</script>\n```\n\n", sep = "")
}

# Año de fin de un periodo como "2024-2027" (o el año único); NA si no hay año
end_year <- function(period) {
  y <- regmatches(period, gregexpr("(19|20)[0-9]{2}", period))
  vapply(y, function(v) if (length(v)) max(as.integer(v)) else NA_integer_, integer(1))
}

# ---- Publications ----
# Cada fila de publications.csv tiene: type, year, citation (la referencia completa,
# en Markdown) y opcionalmente doi, pdf, url.
pub_entry <- function(r) {
  doi <- val(r$doi)
  links <- join_parts(md_link("DOI", if (nzchar(doi)) paste0("https://doi.org/", doi) else ""),
                      md_link("PDF", val(r$pdf)), md_link("Link", val(r$url)))
  cat("::: {.entry}\n", val(r$citation), " ", links, "\n:::\n\n", sep = "")
}

publication_sections <- function() {
  df <- read_data("publications.csv", required = c("type", "year", "citation"))
  types <- c(sci = "Peer-reviewed journal articles (SCI)",
             popular = "Popular science articles",
             book = "Books",
             chapter = "Book chapters",
             report = "Technical reports and other publications")
  for (t in names(types)) {
    d <- df[val(df$type) == t, , drop = FALSE]
    if (nrow(d) == 0) next
    cat("\n\n## ", types[[t]], "\n\n", sep = "")
    by_year(d, pub_entry)
  }
}

# ---- Talks ----
talk_entry <- function(r) {
  where <- join_parts(val(r$event), val(r$place))
  cat("::: {.entry}\n**", val(r$title), "**. ", where, " ", md_link("Link", val(r$url)), "\n:::\n\n", sep = "")
}

talk_sections <- function() {
  df <- read_data("talks.csv")
  types <- c(invited = "Invited talks", conference = "Conference contributions", seminar = "Seminars")
  for (t in names(types)) {
    d <- df[tolower(val(df$type)) == t, , drop = FALSE]
    if (nrow(d) == 0) next
    cat("\n\n## ", types[[t]], "\n\n", sep = "")
    by_year(d, talk_entry)
  }
}

# Diagnóstico: en la consola de R ejecuta  source("R/helpers.R"); check_publications()
check_publications <- function() {
  df <- read_data("publications.csv", required = c("type", "year", "citation"))
  cat("Filas leídas:", nrow(df), "\n")
  print(table(val(df$type), useNA = "ifany"))
  bad <- setdiff(unique(val(df$type)), c("sci", "popular", "book", "chapter", "report"))
  if (length(bad)) cat("Tipos no reconocidos (no se mostrarán):", paste(bad, collapse = ", "), "\n")
  invisible(df)
}
