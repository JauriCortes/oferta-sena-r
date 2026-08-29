# Exporta el mapa de centros de formación a un HTML autocontenido.
# El widget conserva zoom, agrupamiento y popups sin necesidad de un servidor R.
# Genera docs/mapa.html junto a docs/mapa_files/ con las librerias JS.
# Ejecutar desde la raíz del proyecto:  Rscript scripts/04_exportar_mapa.R

library(readr)
library(dplyr)
library(leaflet)
library(htmlwidgets)

desercion <- read_csv("data/sena_limpio.csv", show_col_types = FALSE)
centros_geo <- read_csv("data/centros_geo.csv", show_col_types = FALSE)

centros_stats <- desercion |>
  group_by(CODIGO_CENTRO, NOMBRE_CENTRO) |>
  summarise(
    matriculados = sum(TOTAL_APRENDICES_MATRICULADOS),
    programas = length(unique(NOMBRE_PROGRAMA_FORMACION)),
    .groups = "drop"
  )

centros_mapa <- merge(centros_stats, centros_geo, by = "CODIGO_CENTRO", all.x = FALSE)

top5_por_centro <- desercion |>
  group_by(CODIGO_CENTRO, NOMBRE_PROGRAMA_FORMACION) |>
  summarise(mat = sum(TOTAL_APRENDICES_MATRICULADOS), .groups = "drop") |>
  arrange(CODIGO_CENTRO, desc(mat)) |>
  group_by(CODIGO_CENTRO) |>
  slice_head(n = 5) |>
  summarise(top_prog = paste0("• ", NOMBRE_PROGRAMA_FORMACION, " (", mat, ")", collapse = "<br>"))

centros_mapa <- merge(centros_mapa, top5_por_centro, by = "CODIGO_CENTRO", all.x = TRUE)

mapa <- leaflet(centros_mapa) |>
  addTiles() |>
  setView(lng = -74.0, lat = 4.6, zoom = 6) |>
  setMaxBounds(lng1 = -82, lat1 = -5, lng2 = -66, lat2 = 14) |>
  addCircleMarkers(
    lng = ~LONGITUD, lat = ~LATITUD,
    radius = 8,
    color = "#466B3F",
    fillColor = "#466B3F",
    fillOpacity = 0.7,
    clusterOptions = markerClusterOptions(),
    popup = ~paste0("<b>", NOMBRE_CENTRO, "</b>",
                    "<br>Matriculados: ", matriculados,
                    "<br>Programas: ", programas,
                    "<br><br><b>Top 5 programas:</b><br>", top_prog)
  )

dir.create("docs", showWarnings = FALSE)
saveWidget(mapa, "docs/mapa.html", selfcontained = FALSE,
           title = "Centros de formación del SENA")

cat("Mapa exportado a docs/mapa.html\n")
cat("Centros georreferenciados:", nrow(centros_mapa), "\n")
