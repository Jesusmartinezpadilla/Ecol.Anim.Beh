# Web académica del grupo (Quarto + R + GitHub Pages)

Los contenidos están en `data/*.csv` (equipo, publicaciones, proyectos, charlas, noticias) y en los `.qmd` (texto libre). Las funciones de `R/helpers.R` convierten los CSV en tarjetas y listas.

## Primera vez

1.  Instala [Quarto](https://quarto.org/docs/get-started/) y, en R: `install.packages(c("rmarkdown", "knitr", "quarto"))`.
2.  Abre `group-website.Rproj` en RStudio.
3.  Crea un repositorio en GitHub y sube el proyecto a la rama `main`.
4.  En GitHub: *Settings → Pages → Source: **GitHub Actions***.

## Flujo de trabajo diario (desde R)

``` r
source("R/publish.R")
preview()                       # vista previa local
update_site("Nueva publicación")  # git add + commit + push -> GitHub publica la web
```

## Qué editar

| Archivo | Contenido |
|----|----|
| `_quarto.yml` | Nombre del grupo, menú, pie de página |
| `index.qmd` | Portada: banner, presentación, líneas de investigación |
| `data/team.csv` | Equipo (`group` define las secciones; `photo` = ruta en `images/`) |
| `data/publications.csv` | Ver sección siguiente |
| `data/projects.csv` | `status`: current o past |
| `data/talks.csv` | `type`: invited, conference o seminar |
| `data/news.csv` | Noticias de la portada (las 4 más recientes) |
| `outreach.qmd`, `pi.qmd` | Texto libre |
| `theme.scss` | Colores y tipografías |

Las filas que empiezan por `[EXAMPLE]` son marcadores: bórralas o reemplázalas. Si editas los CSV con Excel, guarda como *CSV UTF-8*.

## Cómo añadir publicaciones

Todas están en `data/publications.csv`, **una fila por publicación**, con estas columnas:

| Columna | Qué poner |
|----|----|
| `type` | `sci` (revistas SCI), `popular` (divulgativas), `book`, `chapter`, `report` (informes técnicos) |
| `year` | Año (se usa para ordenar y agrupar). Para artículos aún no aceptados, escribe `In review` |
| `citation` | La referencia completa tal como la pondrías en el CV. Admite Markdown: `*cursiva*`, `**negrita**` (p. ej. tu nombre) |
| `doi`, `pdf`, `url` | Opcionales; añaden enlaces «DOI», «PDF» y «Link» al final |

Puedes abrir el CSV en Excel (guárdalo como *CSV UTF-8*), en RStudio, o añadir filas desde R:

``` r
nueva <- data.frame(type = "popular", year = "2026",
  citation = "Apellido, N. Título. *Revista*, 45: 12-15.", doi = "", pdf = "", url = "")
write.table(nueva, "data/publications.csv", append = TRUE, sep = ",",
            col.names = FALSE, row.names = FALSE, qmethod = "double", fileEncoding = "UTF-8")
```

El CSV ya incluye las 129 publicaciones de tu CV (91 SCI —con 2 «In review»—, 2 libros, 11 capítulos y 25 informes y otras publicaciones; no he incluido las marcadas «Rejected») y una fila de ejemplo `[EXAMPLE]` de divulgación para que veas esa sección.
