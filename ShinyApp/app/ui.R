library(shiny)
library(shinyjs)
library(shinydashboard)

sidebar <- dashboardSidebar(collapsed = TRUE,
    hr(),

    sidebarMenu(id = "tabs",
                menuItem("Introduccion", tabName = "introduccion", icon = icon("info-circle")),
                menuItem("Datos", tabName = "datos", icon = icon("table")),
                menuItem("Simulacion", tabName = "simulacion", icon = icon("desktop")),
                menuItem("Sobre nosotros", tabName = "about_us", icon = icon("users"))
    ),
    conditionalPanel(condition = 'input.simulacion_basica',
                     sidebarMenu(
                         menuItem("Resultados (Sin turnos)", tabName = "resultados", icon = icon("poll"))
                     )
    ),
    conditionalPanel(condition = 'input.simulacion_con_turnos',
                     sidebarMenu(
                         menuItem("Resultados (Turnos: facultad)", tabName = "resultadosTFAC", icon = icon("poll"))
                     )
    ),
    conditionalPanel(condition = 'input.simulacion_tcan',
                     sidebarMenu(
                         menuItem("Resultados (Turnos: cantidad)", tabName = "resultadosTCAN", icon = icon("poll"))
                     )
    ),
    conditionalPanel(condition = 'input.simulacion_basica && input.simulacion_con_turnos || input.simulacion_con_turnos && input.simulacion_tcan || input.simulacion_basica && input.simulacion_tcan',
                     sidebarMenu(
                         menuItem("Comparacion", tabName = "comparacion", icon = icon("chart-line"))
                     )
    ),
    conditionalPanel(condition = 'input.tabs === "datos"',
                     hr(),
                     sidebarMenu(id = "tabla",
                                 menuItem("Tabla a mostrar", icon = icon("chevron-circle-right"),
                                          fluidRow(
                                              column(1),
                                              column(10, selectInput("table", "", choices = c(read.csv("lista.csv"))))
                                          )
                                 )
                     )
    )
)

simulacion <- tabItem(tabName = "simulacion",
                      box(includeMarkdown("data/Markdowns/simulacion.Rmd"), solidHeader = TRUE, title = "Simulaciones", status = "primary", width = 40),
                      fluidRow(
                          box(
                              sliderInput("cantCajas", "Cantidad de cajas", min = 1, max = 3, value = 2),
                              sliderInput("tiempoCaja", "Tiempo de caja", min = 0, max = 1, value = 0.5),
                              sliderInput("cantAC", "Cantidad de cajas automaticas", min = 1, max = 3, value = 1),
                              sliderInput("cantServidores", "Cantidad de mozos", min = 1, max = 5, value = 2),
                              sliderInput("cantAsientos", "Cantidad de asientos", min = 1, max = 500, value = 400),
                              sliderInput("tiempoCocina", "Intervalo de cocina", min = 0, max = 60, value = 10),
                              sliderInput("cantMenus", "Cantidad de menus por intervalo", min = 1, max = 100, value = 30),
                              actionButton("simulacion_basica", "Simular"),
                              solidHeader = TRUE, title = "Seleccion de parametros", status = "primary"
                          ),
                          box(
                              selectInput("primerTurno", "11hs - 12 hs", choices = c("Veterinarias", "Exactas", "Economicas", "Humanas"), selected = "Veterinarias"),
                              selectInput("segundoTurno", "12hs - 13 hs", choices = c("Veterinarias", "Exactas", "Economicas", "Humanas"), selected = "Exactas"),
                              selectInput("tercerTurno", "13hs - 14 hs", choices = c("Veterinarias", "Exactas", "Economicas", "Humanas"), selected = "Economicas"),
                              selectInput("cuartoTurno", "14hs - 15 hs", choices = c("Veterinarias", "Exactas", "Economicas", "Humanas"), selected = "Humanas"),
                              actionButton("simulacion_con_turnos", "Simular"),
                              solidHeader = TRUE, title = "Facultades por turno", status = "warning"
                          ),
                          box(solidHeader = TRUE, title = "Personas por turno", status = "success",
                              sliderInput("cantPersonas", "", min = 0, max = 1000, value = 400),
                              actionButton("simulacion_tcan", "Simular")
                          )
                      )
)

resultados_sin_turnos <- tabItem(tabName = "resultados",
                                 uiOutput("loading"),
                                 fluidRow(
                                     box(checkboxGroupInput("monthSelection", label = "",
                                                            choices = list("Febrero" = 2, "Marzo" = 3, "Abril" = 4, "Mayo" = 5, "Junio" = 6, "Julio" = 7, "Agosto" = 8,
                                                                           "Septiembre" = 9, "Octubre" = 10, "Noviembre" = 11, "Diciembre" = 12),
                                                            selected = c(2, 3, 4, 5)),
                                         width = 3, height = 370, solidHeader = TRUE, title = "Seleccion de meses:", status = "primary"),
                                     box(div(style = "overflow-y: auto; height: 310px", uiOutput("info")),
                                         height = 370, width = 9, solidHeader = TRUE, title = "Tiempos de espera por recurso", status = "primary")
                                 ),
                                 fluidRow(
                                    column(3, box(valueBox(uiOutput("total_waiting_time"), subtitle = "Tiempo total de espera", icon=icon("clock"), width = NULL), width = NULL),
                                              box(valueBox(uiOutput("cant_atendidos"), subtitle = "Cantidad de clientes", icon=icon("users"), width = NULL), width = NULL)),
                                    column(6, box(plotOutput("pieTiempoUtil"), width = NULL, solidHeader = TRUE, title = "Tiempo util vs. Tiempo de espera", status = "primary")),
                                    column(3, box(uiOutput("parametros"), width = NULL, status = "primary"))
                                 ),
                                 fluidRow(box(plotOutput("wt_mensual"), width = 13, solidHeader = TRUE, title = "Tiempo de espera por mes", status = "primary"))
)

resultados_tfac <- tabItem(tabName = "resultadosTFAC",
                           uiOutput("loading_t"),
                           fluidRow(
                               box(checkboxGroupInput("monthSelection_tfac", label = "",
                                                      choices = list("Febrero" = 2, "Marzo" = 3, "Abril" = 4, "Mayo" = 5, "Junio" = 6, "Julio" = 7, "Agosto" = 8,
                                                                     "Septiembre" = 9, "Octubre" = 10, "Noviembre" = 11, "Diciembre" = 12),
                                                      selected = c(2, 3, 4, 5)),
                                   width = 3, height = 370, solidHeader = TRUE, title = "Seleccion de meses:", status = "primary"),
                               box(div(style = "overflow-y: auto; height: 310px", uiOutput("info_tfac")),
                                   height = 370, width = 9, solidHeader = TRUE, title = "Tiempos de espera por recurso", status = "primary")
                           ),
                           fluidRow(
                               column(3, box(valueBox(uiOutput("total_waiting_time_tfac"), subtitle = "Tiempo total de espera", icon=icon("clock"), width = NULL), width = NULL),
                                      box(valueBox(uiOutput("cant_atendidos_tfac"), subtitle = "Cantidad de clientes", icon=icon("users"), width = NULL), width = NULL)),
                               column(6, box(plotOutput("pieTiempoUtil_tfac"), width = NULL, solidHeader = TRUE, title = "Tiempo util vs. Tiempo de espera", status = "primary")),
                               column(3, box(uiOutput("parametros_tfac"), width = NULL, status = "primary"))
                           ),
                           fluidRow(box(plotOutput("wt_mensual_tfac"), width = 13, solidHeader = TRUE, title = "Tiempo de espera por mes", status = "primary"))

)

resultados_tcan <- tabItem(tabName = "resultadosTCAN",
                           uiOutput("loading_tcan"),
                           fluidRow(
                               box(checkboxGroupInput("monthSelection_tcan", label = "",
                                                      choices = list("Febrero" = 2, "Marzo" = 3, "Abril" = 4, "Mayo" = 5, "Junio" = 6, "Julio" = 7, "Agosto" = 8,
                                                                     "Septiembre" = 9, "Octubre" = 10, "Noviembre" = 11, "Diciembre" = 12),
                                                      selected = c(2, 3, 4, 5)),
                                   width = 3, height = 370, solidHeader = TRUE, title = "Seleccion de meses:", status = "primary"),
                               box(div(style = "overflow-y: auto; height: 310px", uiOutput("info_tcan")),
                                   height = 370, width = 9, solidHeader = TRUE, title = "Tiempos de espera por recurso", status = "primary")
                           ),
                           fluidRow(
                               column(3, box(valueBox(uiOutput("total_waiting_time_tcan"), subtitle = "Tiempo total de espera", icon=icon("clock"), width = NULL), width = NULL),
                                      box(valueBox(uiOutput("cant_atendidos_tcan"), subtitle = "Cantidad de clientes", icon=icon("users"), width = NULL), width = NULL)),
                               column(6, box(plotOutput("pieTiempoUtil_tcan"), width = NULL, solidHeader = TRUE, title = "Tiempo util vs. Tiempo de espera", status = "primary")),
                               column(3, box(uiOutput("parametros_tcan"), width = NULL, status = "primary"))
                           ),
                           fluidRow(box(plotOutput("wt_mensual_tcan"), width = 13, solidHeader = TRUE, title = "Tiempo de espera por mes", status = "primary"))
)

comparacion <- tabItem(tabName = "comparacion",
                       uiOutput("loading_c"),
                       fluidRow(column(4, box(checkboxGroupInput("monthSelection_c", label = "",
                                                       choices = list("Febrero" = 2, "Marzo" = 3, "Abril" = 4, "Mayo" = 5, "Junio" = 6, "Julio" = 7, "Agosto" = 8,
                                                                      "Septiembre" = 9, "Octubre" = 10, "Noviembre" = 11, "Diciembre" = 12),
                                                       selected = c(2, 3, 4, 5)), solidHeader = TRUE, title = "Seleccion de meses", status = "primary", width = NULL, height = 460)),
                                column(4, box(plotOutput("twt_c"), solidHeader = TRUE, title = "Tiempos de espera", status = "primary", width = NULL, height = 460)),
                                column(4, box(div(style = "overflow-y: auto; height: 370px", uiOutput("parametros_c")), solidHeader = TRUE, title = "Parametros", status = "primary", width = NULL, height = 460))

                       ),
                       fluidRow(
                           column(6, box(uiOutput("performance_table"), solidHeader = TRUE, title = "Medidas de performance", status = "primary", width = NULL, height = 300)),
                           column(6, box(uiOutput("resources_table"), solidHeader = TRUE, title = "Tiempos de espera por recurso", status = "primary", width = NULL, height = 300))
                       )
)

about_us <- tabItem(tabName = "about_us",
    box(HTML('<div class="box box-widget widget-user">
                <!-- Add the bg color to the header using any of the bg-* classes -->
                <div class="widget-user-header bg-aqua-active">
                    <h3 class="widget-user-username"><b>Severino, Natalia</b></h3>
                    <h5 class="widget-user-desc">nseverino@alumnos.exa.unicen.edu.ar</h5>
                </div>
                <div class="widget-user-image">
                    <img class="img-circle" src="Nati.png" alt="User Avatar">
                </div>
                <div class="box-footer">
                    <div class="row">
                        <div class="col-sm-4 border-right">
                            <div class="description-block">

                            </div>
                        </div>

                </div>
             </div>
             </div>')),
    box(HTML('<div class="box box-widget widget-user">
                <!-- Add the bg color to the header using any of the bg-* classes -->
                <div class="widget-user-header bg-aqua-active">
                    <h3 class="widget-user-username"><b>Lopez, Catriel</b></h3>
                    <h5 class="widget-user-desc">jlopez@alumnos.exa.unicen.edu.ar</h5>
                </div>
                <div class="widget-user-image">
                    <img class="img-circle" src="Catriel.png" alt="User Avatar">
                </div>
                <div class="box-footer">
                    <div class="row">
                        <div class="col-sm-4 border-right">
                            <div class="description-block">

                            </div>
                        </div>

                </div>
             </div>
             </div>'))

)

body <- dashboardBody(tags$script(HTML("$('body').addClass('sidebar-mini');")),
    tags$head(
        tags$link(rel = "stylesheet", type = "text/css", href = "custom.css")
    ),
    tabItems(
        tabItem(tabName = "introduccion",
                box(includeMarkdown("data/Markdowns/introduccion.Rmd"), solidHeader = TRUE, title = "Problematica actual", status = "primary", width = 40),
                fluidRow(
                    box(includeMarkdown("data/Markdowns/comedor.Rmd"), solidHeader = TRUE, title = "El comedor", status = "warning"),
                    box(imageOutput("diagrama_comedor"), solidHeader = TRUE, status = "success", width=6, height=470)
                )),
        tabItem(tabName = "datos",
                fluidRow(
                    box(column(10, DT::dataTableOutput("mainTable")), solidHeader = TRUE, title = textOutput("table"), status = "primary", width = 12)
                )
        ),
        simulacion,
        resultados_sin_turnos,
        resultados_tfac,
        resultados_tcan,
        comparacion,
        about_us
    )
)

# runApp("app", host = getOption("shiny.host", "0.0.0.0"))
dashboardPage(
    dashboardHeader(title = tagList(
        tags$span(
            class = "logo-mini", icon("chalkboard")
        ),
        tags$span(
            class = "logo-lg", "Simulacion"
        )
    )
    ),
    sidebar,
    body
)