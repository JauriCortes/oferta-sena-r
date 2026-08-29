library(shiny)
library(shinydashboard)
library(ggplot2)
library(readr)
library(dplyr)
library(leaflet)

source("app/funciones.R")
desercion <- read_csv("data/sena_limpio.csv")
centros_geo <- read_csv("data/centros_geo.csv")

ui <- dashboardPage(
  dashboardHeader(title = "Oferta SENA"),
  dashboardSidebar(
    sidebarMenu(
      menuItem("Oferta Formativa", tabName = "oferta"),
      menuItem("Mapa", tabName = "mapa"),
      menuItem("Datos", tabName = "datos")
    ),
    selectInput("regional", "Regional:",
                choices = sort(unique(desercion$NOMBRE_REGIONAL)),
                selected = "REGIONAL DISTRITO CAPITAL"),
    checkboxGroupInput("nivel", "Nivel de formación:",
                       choices = unique(desercion$NIVEL_FORMACION),
                       selected = unique(desercion$NIVEL_FORMACION)),
    radioButtons("modalidad", "Modalidad:",
                 choices = c("PRESENCIAL", "VIRTUAL", "A DISTANCIA"),
                 selected = "PRESENCIAL")
  ),
  dashboardBody(
    tabItems(
      tabItem(tabName = "oferta",
        fluidRow(
          box(title = "Estadísticas", width = 4, textOutput("stats")),
          box(title = "Top 10 programas", width = 8, plotOutput("grafico_top"))
        )
      ),
      tabItem(tabName = "mapa",
        fluidRow(
          box(title = "Centros de formación SENA", width = 12,
              leafletOutput("mapa_centros", height = "500px"))
        )
      ),
      tabItem(tabName = "datos",
        fluidRow(
          box(title = "Dataset filtrado", width = 12,
              dataTableOutput("tabla_datos"))
        )
      )
    )
  )
)

server <- function(input, output, session) {
  datos_filtrados <- reactive({
    req(input$nivel)
    filtrar_datos(desercion, input$regional, input$nivel, input$modalidad)
  })

  output$stats <- renderText({
    s <- stats_resumen(datos_filtrados())
    paste0("Fichas: ", s$fichas,
           "\nMatriculados: ", s$matriculados,
           "\nDesertores: ", s$desertores,
           "\nTasa deserción: ", s$tasa, "%",
           "\nProgramas: ", s$programas)
  })

  output$grafico_top <- renderPlot({
    top <- top_programas(datos_filtrados())
    ggplot(top, aes(x = reorder(NOMBRE_PROGRAMA_FORMACION, matriculados),
                    y = matriculados)) +
      geom_col(fill = "#466B3F") +
      coord_flip() +
      scale_y_continuous(labels = scales::comma) +
      labs(x = NULL, y = "Matriculados") +
      theme_minimal()
  }, res = 96)

  output$mapa_centros <- renderLeaflet({
    centros_stats <- desercion |>
      group_by(CODIGO_CENTRO, NOMBRE_CENTRO) |>
      summarise(
        matriculados = sum(TOTAL_APRENDICES_MATRICULADOS),
        programas = length(unique(NOMBRE_PROGRAMA_FORMACION)),
        .groups = "drop"
      )

    centros_mapa <- merge(centros_stats, centros_geo,
                          by = "CODIGO_CENTRO", all.x = FALSE)

    top5_por_centro <- desercion |>
      group_by(CODIGO_CENTRO, NOMBRE_PROGRAMA_FORMACION) |>
      summarise(mat = sum(TOTAL_APRENDICES_MATRICULADOS), .groups = "drop") |>
      arrange(CODIGO_CENTRO, desc(mat)) |>
      group_by(CODIGO_CENTRO) |>
      slice_head(n = 5) |>
      summarise(top_prog = paste0("• ", NOMBRE_PROGRAMA_FORMACION, " (", mat, ")", collapse = "<br>"))

    centros_mapa <- merge(centros_mapa, top5_por_centro, by = "CODIGO_CENTRO", all.x = TRUE)

    leaflet(centros_mapa) |>
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
  })

  output$tabla_datos <- renderDataTable({
    datos_filtrados()[, c("NOMBRE_CENTRO", "NOMBRE_PROGRAMA_FORMACION",
                          "NIVEL_FORMACION", "MODALIDAD_FORMACION",
                          "TOTAL_APRENDICES_MATRICULADOS", "DESERTORES_AÑO_ACTUAL",
                          "duracion_meses")]
  })
}

shinyApp(ui, server)
