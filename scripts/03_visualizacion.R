library(readr)
library(dplyr)
library(ggplot2)

# Cargar dataset limpio
desercion <- read_csv("data/sena_limpio.csv")

# Top 15 programas por matriculados
top_programas <- desercion |>
  group_by(NOMBRE_PROGRAMA_FORMACION, NIVEL_FORMACION) |>
  summarise(matriculados = sum(TOTAL_APRENDICES_MATRICULADOS), .groups = "drop") |>
  arrange(desc(matriculados)) |>
  head(15)

ggplot(top_programas, aes(x = reorder(NOMBRE_PROGRAMA_FORMACION, matriculados),
                          y = matriculados,
                          fill = NIVEL_FORMACION)) +
  geom_col() +
  coord_flip() +
  scale_fill_manual(values = c("TECNICO" = "#466B3F",
                                "TECNOLOGO" = "#5A8A50",
                                "CURSO ESPECIAL" = "#A61C31")) +
  scale_y_continuous(labels = scales::comma) +
  labs(title = "Top 15 programas por aprendices matriculados",
       x = NULL,
       y = "Matriculados",
       fill = "Nivel") +
  theme_minimal() +
  theme(legend.position = "bottom")

# Matriculados por nivel y modalidad
nivel_modalidad <- desercion |>
  group_by(NIVEL_FORMACION, MODALIDAD_FORMACION) |>
  summarise(matriculados = sum(TOTAL_APRENDICES_MATRICULADOS), .groups = "drop")

ggplot(nivel_modalidad, aes(x = reorder(NIVEL_FORMACION, -matriculados),
                            y = matriculados,
                            fill = MODALIDAD_FORMACION)) +
  geom_col(position = "fill") +
  scale_fill_manual(values = c("PRESENCIAL" = "#466B3F",
                                "VIRTUAL" = "#A61C31",
                                "A DISTANCIA" = "#AFB1B2")) +
  scale_y_continuous(labels = scales::percent) +
  labs(title = "Distribución de modalidad por nivel de formación",
       x = NULL,
       y = "Proporción de matriculados",
       fill = "Modalidad") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1),
        legend.position = "bottom")

# Filtrar niveles con duración > 0 (excluir EVENTO que dura 0)
duracion_data <- desercion |>
  filter(NIVEL_FORMACION %in% c("AUXILIAR", "CURSO ESPECIAL", "OPERARIO", "TECNICO", "TECNOLOGO"))

ggplot(duracion_data, aes(x = duracion_meses)) +
  geom_histogram(fill = "#466B3F", color = "white", bins = 20) +
  facet_wrap(~ NIVEL_FORMACION, scales = "free_y") +
  labs(title = "Distribución de duración de programas por nivel",
       x = "Duración (meses)",
       y = "Número de fichas") +
  theme_minimal()

# Resumen por regional
library(plotly)
regionales <- desercion |>
  group_by(NOMBRE_REGIONAL) |>
  summarise(
    matriculados = sum(TOTAL_APRENDICES_MATRICULADOS),
    programas = length(unique(NOMBRE_PROGRAMA_FORMACION)),
    centros = length(unique(NOMBRE_CENTRO)),
    tasa = round(sum(DESERTORES_AÑO_ACTUAL) / matriculados * 100, 1),
    .groups = "drop"
  )

p <- ggplot(regionales, aes(x = matriculados,
                            y = programas,
                            size = centros,
                            color = tasa,
                            text = paste0(NOMBRE_REGIONAL,
                                         "\nMatriculados: ", scales::comma(matriculados),
                                         "\nProgramas: ", programas,
                                         "\nCentros: ", centros,
                                         "\nTasa deserción: ", tasa, "%"))) +
  geom_point(alpha = 0.7) +
  scale_color_gradient(low = "#466B3F", high = "#A61C31") +
  scale_x_continuous(labels = scales::comma) +
  labs(title = "Regionales SENA: oferta vs. deserción",
       x = "Total matriculados",
       y = "Programas ofertados",
       color = "Tasa deserción %",
       size = "Centros") +
  theme_minimal()

ggplotly(p, tooltip = "text")

# Tasa por regional (reutilizamos el tibble 'regionales' de la gráfica 4)
tasa_global <- sum(desercion$DESERTORES_AÑO_ACTUAL) / sum(desercion$TOTAL_APRENDICES_MATRICULADOS) * 100

ggplot(regionales, aes(x = reorder(NOMBRE_REGIONAL, tasa), y = tasa)) +
  geom_segment(aes(xend = NOMBRE_REGIONAL, y = 0, yend = tasa), color = "#565A5C") +
  geom_point(size = 3, color = "#466B3F") +
  geom_hline(yintercept = tasa_global, linetype = "dashed", color = "#A61C31") +
  annotate("text", x = 3, y = tasa_global + 0.5, label = paste0("Media nacional: ", round(tasa_global, 1), "%"),
           color = "#A61C31", size = 3) +
  coord_flip() +
  labs(title = "Tasa de deserción por regional",
       x = NULL,
       y = "Tasa de deserción (%)") +
  theme_minimal()


# Guardar gráficas de ggplot2
ggsave("graficas/g1_top_programas.png", width = 10, height = 7)

# Para guardar las anteriores hay que reasignarlas a objetos
# La gráfica 5 (lollipop) ya es la última en pantalla, así que ggsave la guarda
# Para las demás, reconstruir y guardar:

g1 <- ggplot(top_programas, aes(x = reorder(NOMBRE_PROGRAMA_FORMACION, matriculados),
                                y = matriculados, fill = NIVEL_FORMACION)) +
  geom_col() + coord_flip() +
  scale_fill_manual(values = c("TECNICO" = "#466B3F", "TECNOLOGO" = "#5A8A50", "CURSO ESPECIAL" = "#A61C31")) +
  scale_y_continuous(labels = scales::comma) +
  labs(title = "Top 15 programas por aprendices matriculados", x = NULL, y = "Matriculados", fill = "Nivel") +
  theme_minimal() + theme(legend.position = "bottom")

g2 <- ggplot(nivel_modalidad, aes(x = reorder(NIVEL_FORMACION, -matriculados),
                                  y = matriculados, fill = MODALIDAD_FORMACION)) +
  geom_col(position = "fill") +
  scale_fill_manual(values = c("PRESENCIAL" = "#466B3F", "VIRTUAL" = "#A61C31", "A DISTANCIA" = "#AFB1B2")) +
  scale_y_continuous(labels = scales::percent) +
  labs(title = "Distribución de modalidad por nivel de formación", x = NULL, y = "Proporción", fill = "Modalidad") +
  theme_minimal() + theme(axis.text.x = element_text(angle = 45, hjust = 1), legend.position = "bottom")

g3 <- ggplot(duracion_data, aes(x = duracion_meses)) +
  geom_histogram(fill = "#466B3F", color = "white", bins = 20) +
  facet_wrap(~ NIVEL_FORMACION, scales = "free_y") +
  labs(title = "Distribución de duración de programas por nivel", x = "Duración (meses)", y = "Número de fichas") +
  theme_minimal()

g5 <- ggplot(regionales, aes(x = reorder(NOMBRE_REGIONAL, tasa), y = tasa)) +
  geom_segment(aes(xend = NOMBRE_REGIONAL, y = 0, yend = tasa), color = "#565A5C") +
  geom_point(size = 3, color = "#466B3F") +
  geom_hline(yintercept = tasa_global, linetype = "dashed", color = "#A61C31") +
  annotate("text", x = 3, y = tasa_global + 0.5, label = paste0("Media nacional: ", round(tasa_global, 1), "%"),
           color = "#A61C31", size = 3) +
  coord_flip() +
  labs(title = "Tasa de deserción por regional", x = NULL, y = "Tasa de deserción (%)") +
  theme_minimal()

ggsave("graficas/g1_top_programas.png", g1, width = 10, height = 7)
ggsave("graficas/g2_modalidad_nivel.png", g2, width = 8, height = 6)
ggsave("graficas/g3_duracion_nivel.png", g3, width = 10, height = 6)
ggsave("graficas/g5_desercion_regional.png", g5, width = 8, height = 8)

cat("4 gráficas guardadas en graficas/\n")
