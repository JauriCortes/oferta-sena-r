library(readr)
library(dplyr)
library(lubridate)

# Cargar dataset crudo
desercion <- read_csv("data/desercion_sena.csv")

# Limpiar comillas extra de cada columna de texto
desercion$NOMBRE_REGIONAL <- gsub('"', '', desercion$NOMBRE_REGIONAL)
desercion$NOMBRE_CENTRO <- gsub('"', '', desercion$NOMBRE_CENTRO)
desercion$FECHA_INICIO_FICHA <- gsub('"', '', desercion$FECHA_INICIO_FICHA)
desercion$FECHA_TERMINACION_FICHA <- gsub('"', '', desercion$FECHA_TERMINACION_FICHA)
desercion$CODIGO_PROGRAMA <- gsub('"', '', desercion$CODIGO_PROGRAMA)
desercion$NOMBRE_PROGRAMA_FORMACION <- gsub('"', '', desercion$NOMBRE_PROGRAMA_FORMACION)
desercion$NIVEL_FORMACION <- gsub('"', '', desercion$NIVEL_FORMACION)
desercion$MODALIDAD_FORMACION <- gsub('"', '', desercion$MODALIDAD_FORMACION)

# Verificar
glimpse(desercion)

# Parsear fechas con lubridate (submódulo 1.1)
desercion$FECHA_INICIO_FICHA <- dmy(desercion$FECHA_INICIO_FICHA)
desercion$FECHA_TERMINACION_FICHA <- dmy(desercion$FECHA_TERMINACION_FICHA)

# Columnas derivadas
desercion$tasa_desercion <- desercion$DESERTORES_AÑO_ACTUAL / desercion$TOTAL_APRENDICES_MATRICULADOS
desercion$duracion_dias <- as.numeric(desercion$FECHA_TERMINACION_FICHA - desercion$FECHA_INICIO_FICHA)
desercion$duracion_meses <- round(desercion$duracion_dias / 30.4, 1)
desercion$mes_inicio <- month(desercion$FECHA_INICIO_FICHA)
desercion$año_inicio <- year(desercion$FECHA_INICIO_FICHA)
desercion$tiene_desercion <- desercion$DESERTORES_AÑO_ACTUAL > 0

# Verificar las columnas nuevas
glimpse(desercion)

# ── Estadísticas de la oferta formativa ──

cat("═══ OFERTA FORMATIVA DEL SENA ═══\n\n")

cat("Total de fichas:", nrow(desercion), "\n")
cat("Total de aprendices matriculados:", sum(desercion$TOTAL_APRENDICES_MATRICULADOS), "\n")
cat("Programas únicos:", length(unique(desercion$NOMBRE_PROGRAMA_FORMACION)), "\n")
cat("Centros:", length(unique(desercion$NOMBRE_CENTRO)), "\n")
cat("Regionales:", length(unique(desercion$NOMBRE_REGIONAL)), "\n\n")

# Matriculados por nivel de formación
cat("── Matriculados por nivel ──\n")
desercion |>
  group_by(NIVEL_FORMACION) |>
  summarise(matriculados = sum(TOTAL_APRENDICES_MATRICULADOS)) |>
  arrange(desc(matriculados)) |>
  print()

# Top 10 programas por matriculados
cat("\n── Top 10 programas por matriculados ──\n")
desercion |>
  group_by(NOMBRE_PROGRAMA_FORMACION) |>
  summarise(matriculados = sum(TOTAL_APRENDICES_MATRICULADOS)) |>
  arrange(desc(matriculados)) |>
  head(10) |>
  print()

# Distribución por modalidad
cat("\n── Distribución por modalidad ──\n")
desercion |>
  group_by(MODALIDAD_FORMACION) |>
  summarise(
    matriculados = sum(TOTAL_APRENDICES_MATRICULADOS),
    porcentaje = round(matriculados / sum(desercion$TOTAL_APRENDICES_MATRICULADOS) * 100, 1)
  ) |>
  arrange(desc(matriculados)) |>
  print()

# Concentración geográfica - Top 5 regionales
cat("\n── Top 5 regionales por matriculados ──\n")
desercion |>
  group_by(NOMBRE_REGIONAL) |>
  summarise(matriculados = sum(TOTAL_APRENDICES_MATRICULADOS)) |>
  arrange(desc(matriculados)) |>
  head(5) |>
  print()

# Duración mediana por nivel
cat("\n── Duración mediana por nivel (meses) ──\n")
desercion |>
  group_by(NIVEL_FORMACION) |>
  summarise(duracion_mediana = median(duracion_meses)) |>
  arrange(desc(duracion_mediana)) |>
  print()

# ── Estadísticas de deserción ──

cat("\n═══ DESERCIÓN ═══\n\n")

cat("Total desertores:", sum(desercion$DESERTORES_AÑO_ACTUAL), "\n")
cat("Tasa global:", round(sum(desercion$DESERTORES_AÑO_ACTUAL) / sum(desercion$TOTAL_APRENDICES_MATRICULADOS) * 100, 1), "%\n")
cat("Fichas con deserción:", sum(desercion$tiene_desercion), "de", nrow(desercion),
    paste0("(", round(mean(desercion$tiene_desercion) * 100, 1), "%)"), "\n\n")

# Tasa por modalidad
cat("── Tasa de deserción por modalidad ──\n")
desercion |>
  group_by(MODALIDAD_FORMACION) |>
  summarise(
    matriculados = sum(TOTAL_APRENDICES_MATRICULADOS),
    desertores = sum(DESERTORES_AÑO_ACTUAL),
    tasa = round(desertores / matriculados * 100, 1)
  ) |>
  arrange(desc(tasa)) |>
  print()

# Tasa por nivel
cat("\n── Tasa de deserción por nivel ──\n")
desercion |>
  group_by(NIVEL_FORMACION) |>
  summarise(
    matriculados = sum(TOTAL_APRENDICES_MATRICULADOS),
    desertores = sum(DESERTORES_AÑO_ACTUAL),
    tasa = round(desertores / matriculados * 100, 1)
  ) |>
  arrange(desc(tasa)) |>
  print()

# Top 5 regionales con mayor deserción
cat("\n── Top 5 regionales con mayor tasa de deserción ──\n")
desercion |>
  group_by(NOMBRE_REGIONAL) |>
  summarise(
    matriculados = sum(TOTAL_APRENDICES_MATRICULADOS),
    desertores = sum(DESERTORES_AÑO_ACTUAL),
    tasa = round(desertores / matriculados * 100, 1)
  ) |>
  arrange(desc(tasa)) |>
  head(5) |>
  print()

# Top 5 regionales con menor deserción
cat("\n── Top 5 regionales con menor tasa de deserción ──\n")
desercion |>
  group_by(NOMBRE_REGIONAL) |>
  summarise(
    matriculados = sum(TOTAL_APRENDICES_MATRICULADOS),
    desertores = sum(DESERTORES_AÑO_ACTUAL),
    tasa = round(desertores / matriculados * 100, 1)
  ) |>
  arrange(tasa) |>
  head(5) |>
  print()

# ── Guardar dataset limpio ──
write_csv(desercion, "data/sena_limpio.csv")
cat("\nDataset limpio guardado en data/sena_limpio.csv\n")
cat("Dimensiones:", nrow(desercion), "filas x", ncol(desercion), "columnas\n")
