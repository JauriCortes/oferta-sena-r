library(dplyr)

stats_resumen <- function(datos) {
  list(
    fichas = nrow(datos),
    matriculados = sum(datos$TOTAL_APRENDICES_MATRICULADOS),
    desertores = sum(datos$DESERTORES_AÑO_ACTUAL),
    tasa = round(sum(datos$DESERTORES_AÑO_ACTUAL) / sum(datos$TOTAL_APRENDICES_MATRICULADOS) * 100, 1),
    programas = length(unique(datos$NOMBRE_PROGRAMA_FORMACION))
  )
}

top_programas <- function(datos, n = 10) {
  datos |>
    group_by(NOMBRE_PROGRAMA_FORMACION) |>
    summarise(matriculados = sum(TOTAL_APRENDICES_MATRICULADOS), .groups = "drop") |>
    arrange(desc(matriculados)) |>
    head(n)
}

filtrar_datos <- function(datos, regional, niveles, modalidades) {
  datos[datos$NOMBRE_REGIONAL == regional &
        datos$NIVEL_FORMACION %in% niveles &
        datos$MODALIDAD_FORMACION %in% modalidades, ]
}