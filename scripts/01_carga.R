library(readr)
library(dplyr)
 
# Cargar dataset principal
desercion <- read_csv("data/desercion_sena.csv")
 
# Exploración inicial
dim(desercion)
glimpse(desercion)
head(desercion)
colSums(is.na(desercion))

# Cargar dataset de coordenadas
centros_geo <- read_csv("data/centros_geo.csv")
glimpse(centros_geo)
 
# Resumen de valores faltantes en ambos datasets
cat("\n--- NAs en dataset principal ---\n")
colSums(is.na(desercion))
 
cat("\n--- NAs en dataset coordenadas ---\n")
colSums(is.na(centros_geo))
head(centros_geo,20)
head(desercion,20)
