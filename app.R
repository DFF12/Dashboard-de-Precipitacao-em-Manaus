library(shiny)
library(leaflet)
library(tidyverse)
library(shinyWidgets)
library(mapview)
library(sf)
library(gstat)
library(dplyr)
require(stars)
library(ggfortify)
library(ggplot2)
library(shinyjs)
library(plotly)
library(jsonlite)

# Carregar os dados
manaus_setores <- readRDS("/Users/daniel/Documents/Dados/AM_Setores_2021/manaus_setores_2021.rds") %>% st_as_sf()
manaus_acm.path <- "/Users/daniel/Documents/Dados/manaus_acumulado2.csv"
manaus <- read.csv2(file = manaus_acm.path, sep = ";")

dados_CEMADEM_dashboard <- read.csv2(
  file = "/Users/daniel/Documents/Dados/CEMADEM_acumulado2024.csv",
  sep = ";", header = T
)
dados_CEMADEM_dashboard %>%
  mutate(data_acumulada = ymd(data_acumulada)) -> dados_CEMADEM_dashboard

dados_CEMADEM_dashboard %>%
  group_by(nomeEstacao) %>%
  summarise(
    municipio = last(municipio), codEstacao = last(codEstacao), uf = last(uf),
    latitude = last(latitude), longitude = last(longitude),
    valorMedida = sum(valorMedida, na.rm = T)
  ) -> estacoes_CEMADEM

dados_CEMADEM_dashboard %>%
  group_by(nomeEstacao, ANO, MES, DIA) %>%
  summarise(
    municipio = last(municipio), uf = last(uf),
    valorMedida = sum(valorMedida, na.rm = T), data_acumulada
  ) -> dados_CEMADEM_dia

dados_CEMADEM_dia %>%
  pivot_wider(
    names_from = nomeEstacao,
    values_from = valorMedida
  ) -> dados_CEMADEM_wider_dia

dados_CEMADEM_wider_dia %>%
  arrange(ANO, MES) -> dados_CEMADEM_wider_dia

dados_CEMADEM_dashboard %>%
  group_by(nomeEstacao, ANO, MES) %>%
  summarise(
    municipio = last(municipio), uf = last(uf),
    valorMedida = sum(valorMedida, na.rm = T)
  ) -> dados_CEMADEM_wider_mes

dados_CEMADEM_wider_mes %>%
  pivot_wider(
    names_from = nomeEstacao,
    values_from = valorMedida
  ) -> dados_CEMADEM_wider_mes

dados_CEMADEM_wider_mes %>%
  arrange(ANO, MES) -> dados_CEMADEM_wider_mes

ui <- fluidPage(
  useShinyjs(),
  tags$head(
    tags$script(src = "script.js"),
    tags$script(src = "https://cdn.jsdelivr.net/npm/apexcharts"),
    tags$link(rel = "stylesheet", type = "text/css", href = "styles.css")
  ),
  div(
    class = "sidebar-tabs",
    div(
      id = "header-text",
      "Análise Espacial para a cidade de Manaus"
    ),
    div(
      class = "sidebar",
      div(
        class = "coluna",
        div(id = "item1", class = "linha", "Estações"),
        div(id = "item2", class = "linha", "Monitoramento"),
        div(id = "item3", class = "linha", "Interpolação")
      )
    )
  ),
  div(
    id = "caixa",
    div(
      id = "tela1", class = "tabcontent",
      div(
        id = "tela_mapa",
        leafletOutput("plot", height = 600)
      )
    ),
    div(
      id = "tela2", class = "tabcontent",
      div(
        id = "tela_graficos",
        div(
          class = "sidePanel", dateRangeInput("multiple", "Selecione o período de tempo:",
            start = "2021-01-01", end = "2021-01-31"
          ),
          selectInput(
            inputId = "selecione_estacoes", label = "Estação",
            choices = unique(estacoes_CEMADEM$nomeEstacao), selected = "Cidade de Deus",
            multiple = F
          )
        ),
        div(id = "estacao_plot", class = "card"),
        div(
          class = "sidePanel",
          dateRangeInput("datas_manaus", "Selecione o período de tempo:",
            start = "2019-01-01", end = "2021-12-31"
          )
        ),
        div(id = "manaus_plot", class = "card")
      )
    ),
    div(
      id = "tela3", class = "tabcontent",
      div(
        id = "tela_krigagem",
        leafletOutput("plot3", height = "100%", width = "auto")
      )
    )
  )
)

server <- function(input, output, session) {
  output$plot <- renderLeaflet({
    leaflet() %>%
      addTiles() %>%
      setView(lng = -60.021731, lat = -3.113583, zoom = 12)
  })

  dados_estacoes <- reactive({
    data_dia_inicio <- ymd(as.character(input$multiple)[1])
    data_dia_fim <- ymd(as.character(input$multiple)[2])
    dados_CEMADEM_dia %>%
      filter(nomeEstacao == input$selecione_estacoes, between(data_acumulada, data_dia_inicio, data_dia_fim)) %>%
      ungroup() %>%
      select(y = valorMedida, x = data_acumulada)
  })

  dados_manaus <- reactive({
    data_inicio <- ymd(as.character(input$datas_manaus[1]))
    data_fim <- ymd(as.character(input$datas_manaus[2]))

    manaus %>%
      select(-X) %>%
      mutate(data = ymd(paste(ANO, MES, 01, sep = "-")), manaus_mm = round(manaus_mm, 2)) %>%
      filter(between(data, ymd(data_inicio), ymd(data_fim))) %>%
      select(y = manaus_mm, x = data)
  })

  observe({
    df <- dados_estacoes()
    df_json <- list(
      dados = df,
      estacao = input$selecione_estacoes
    )
    shiny_json <- toJSON(df_json, pretty = TRUE)

    session$sendCustomMessage("dataMessage", shiny_json)
  })

  observe({
    df_manaus <- dados_manaus()
    df_json <- list(
      dados = df_manaus
    )
    shiny_json <- toJSON(df_json, pretty = TRUE)

    session$sendCustomMessage("data_manaus", shiny_json)
  })
}

shinyApp(ui, server)
