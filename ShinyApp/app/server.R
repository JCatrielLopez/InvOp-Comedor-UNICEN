library(shiny)
library(DT)
library(data.table)
library(reticulate)
library(RPostgreSQL)
library(ggplot2)
library(radarchart)
library(reshape2)
library(plyr)
library(gridExtra)
library(stats)

use_python("/usr/bin/python3")

shinyServer(function(input, output) {

    output$diagrama_comedor <- renderImage(list(src = "data/Markdowns/comedor_2.png", alt = "Diagrama del comedor", width = 510, height = 450), deleteFile = FALSE)

    # res <- NULL
    # res_t <- NULL
    # res_tcan <- NULL

    blank_theme <- theme_minimal()+
        theme(
            axis.title.x = element_blank(),
            axis.title.y = element_blank(),
            panel.border = element_blank(),
            panel.grid=element_blank(),
            axis.ticks = element_blank(),
            plot.title=element_text(size=14, face="bold")
        )

    output$loading <- renderUI({withProgress(message = 'Graficando', value = 0, {
        incProgress(1/3, detail = "Terminando ...")
        Sys.sleep(0.3)
        incProgress(1/3, detail = "Terminando ...")
        Sys.sleep(0.3)
        incProgress(1/3, detail = "Terminando ...")
        Sys.sleep(0.3)

    })})

    output$loading_t <- renderUI({withProgress(message = 'Graficando', value = 0, {
        incProgress(1/3, detail = "Terminando ...")
        Sys.sleep(0.3)
        incProgress(1/3, detail = "Terminando ...")
        Sys.sleep(0.3)
        incProgress(1/3, detail = "Terminando ...")
        Sys.sleep(0.3)

    })})

    output$loading_tcan <- renderUI({withProgress(message = 'Graficando', value = 0, {
        incProgress(1/3, detail = "Terminando ...")
        Sys.sleep(0.3)
        incProgress(1/3, detail = "Terminando ...")
        Sys.sleep(0.3)
        incProgress(1/3, detail = "Terminando ...")
        Sys.sleep(0.3)

    })})

    output$loading_c <- renderUI({withProgress(message = 'Graficando', value = 0, {
        incProgress(1/3, detail = "Terminando ...")
        Sys.sleep(0.3)
        incProgress(1/3, detail = "Terminando ...")
        Sys.sleep(0.3)
        incProgress(1/3, detail = "Terminando ...")
        Sys.sleep(0.3)

    })})

    observeEvent(input$simulacion_basica,{
        source_python("simulations.py")

        cantCajas <-input$cantCajas
        tiempoCaja <- input$tiempoCaja
        cantServidores <- input$cantServidores
        cantAsientos <- input$cantAsientos
        tiempoCocina <- input$tiempoCocina
        cantMenus <- input$cantMenus
        cantAC <- input$cantAC

        # name | month | facultad | start_time | end_time | clerk_queue | automatic_clerk_queue | delivery_queue | seating_queue | total_waiting_time | activity_time
            resultados <- simular(cantCajas, tiempoCaja, cantServidores, cantAsientos, tiempoCocina, cantMenus, cantAC)
            # # Save an object to a file
            saveRDS(resultados, file = "res_basic.rds")
            # # Restore the object
            # readRDS(file = "res_basic.rds")
        # resource | avg_queue_length | max_queue_length | avg_count
            recursos <- get_resources()
            saveRDS(recursos, file = "resources_basic.rds")
            total <- get_total()


            output$pieTiempoUtil <- renderPlot({
                df <- resultados[resultados$month %in% input$monthSelection,]
                avg_rt <- c(mean(df$end_time - df$start_time))
                tiempo_util <- c(mean(df$activity_time) / avg_rt)

                valores <- c(1 - tiempo_util[[1]], tiempo_util[[1]])
                tiempos <- c("Tiempo esperando", "Tiempo util")
                ggplot(data.frame(tiempos, valores), aes(x="", y=valores, fill=tiempos))+
                    geom_bar(width = 1, stat = "identity")+
                    coord_polar("y", start=0)+
                    blank_theme

            })

            output$wt_mensual <- renderPlot({
                df <- resultados[resultados$month %in% input$monthSelection,]
                results <- aggregate(total_waiting_time ~ month, df, FUN = mean)
                ggplot(results, aes(x=month, y=total_waiting_time, fill=month))+
                    geom_bar(stat="identity")+
                    guides(fill=FALSE)+
                    geom_text(aes(label=strtrim(total_waiting_time, 5)), vjust=1.6, color="black", size=3.5)+
                    theme(legend.position="none")+
                    blank_theme

            })

            output$parametros <- renderUI(HTML(paste("<B>", "Cantidad de cajas:", "</B>", cantCajas, "<br><br><B>", "Tiempo en la caja:", "</B>", tiempoCaja, "<br><br><B>", "Cantidad de mozos:", "</B>", cantServidores,
                                                  "<br><br><B>", "Cantidad de asientos:", "</B>", cantAsientos, "<br><br><B>", "Tiempo de cocina:", "</B>", tiempoCocina, "<br><br><B>", "Cantidad de menus por tiempo:", "</B>", cantMenus,
                                                  "<br><br><B>", "Cantidad de cajas automaticas:", "</B>", cantAC)))

            output$total_waiting_time <- renderUI({
                df <- resultados[resultados$month %in% input$monthSelection,]
                paste(strtrim(mean(df$total_waiting_time), 5), "minutos", sep=" ")
            })

            output$cant_atendidos <- renderUI({
                df <- resultados[resultados$month %in% input$monthSelection,]
                paste(strtrim(nrow(df)/11, 5), "personas", sep=" ")
            })

            output$info <- renderUI({
                # name | month | facultad | start_time | end_time | clerk_queue | automatic_clerk_queue | delivery_queue | seating_queue | total_waiting_time | activity_time
                df_febrero <- resultados[resultados$month == 2,]
                df_marzo <- resultados[resultados$month == 3,]
                df_abril <- resultados[resultados$month == 4,]
                df_mayo <- resultados[resultados$month == 5,]
                df_junio <- resultados[resultados$month == 6,]
                df_julio <- resultados[resultados$month == 7,]
                df_agosto <- resultados[resultados$month == 8,]
                df_septiembre <- resultados[resultados$month == 9,]
                df_octubre <- resultados[resultados$month == 10,]
                df_noviembre <- resultados[resultados$month == 11,]
                df_diciembre <- resultados[resultados$month == 12,]
                obj <- HTML(
                    paste('<table class="table table-striped">
                          <tr>
                              <th style="width: 10px">#</th>
                              <th>Mes</th>
                              <th>Caja</th>
                              <th style="width: 150px">Caja automatica</th>
                              <th>Delivery</th>
                              <th>Asientos</th>
                          </tr>
                          <tr>
                          <td>1.</td>
                          <td>Febrero</td>
                          <td>',strtrim(mean(df_febrero$clerk_queue), 5) ,'</td>
                          <td>',strtrim(mean(df_febrero$automatic_clerk_queue), 5) ,'</td>
                          <td>',strtrim(mean(df_febrero$delivery_queue), 5) ,'</td>
                          <td>',strtrim(mean(df_febrero$seating_queue), 5) ,'</td>
                          </tr>
                          <tr>
                          <td>2.</td>
                          <td>Marzo</td>
                          <td>',strtrim(mean(df_marzo$clerk_queue), 5) ,'</td>
                          <td>',strtrim(mean(df_marzo$automatic_clerk_queue), 5) ,'</td>
                          <td>',strtrim(mean(df_marzo$delivery_queue), 5) ,'</td>
                          <td>',strtrim(mean(df_marzo$seating_queue), 5) ,'</td>
                          <tr>
                          <td>3.</td>
                          <td>Abril</td>
                          <td>',strtrim(mean(df_marzo$clerk_queue), 5) ,'</td>
                          <td>',strtrim(mean(df_marzo$automatic_clerk_queue), 5) ,'</td>
                          <td>',strtrim(mean(df_marzo$delivery_queue), 5) ,'</td>
                          <td>',strtrim(mean(df_marzo$seating_queue), 5) ,'</td>
                          </tr>
                          <tr>
                          <td>4.</td>
                          <td>Mayo</td>
                          <td>',strtrim(mean(df_mayo$clerk_queue), 5) ,'</td>
                          <td>',strtrim(mean(df_mayo$automatic_clerk_queue), 5) ,'</td>
                          <td>',strtrim(mean(df_mayo$delivery_queue), 5) ,'</td>
                          <td>',strtrim(mean(df_mayo$seating_queue), 5) ,'</td>
                          </tr>
                          <tr>
                          <td>5.</td>
                          <td>Junio</td>
                          <td>',strtrim(mean(df_junio$clerk_queue), 5) ,'</td>
                          <td>',strtrim(mean(df_junio$automatic_clerk_queue), 5) ,'</td>
                          <td>',strtrim(mean(df_junio$delivery_queue), 5) ,'</td>
                          <td>',strtrim(mean(df_junio$seating_queue), 5) ,'</td>
                          </tr>
                          <tr>
                          <td>6.</td>
                          <td>Julio</td>
                          <td>',strtrim(mean(df_julio$clerk_queue), 5) ,'</td>
                          <td>',strtrim(mean(df_julio$automatic_clerk_queue), 5) ,'</td>
                          <td>',strtrim(mean(df_julio$delivery_queue), 5) ,'</td>
                          <td>',strtrim(mean(df_julio$seating_queue), 5) ,'</td>
                          </tr>
                          <tr>
                          <td>7.</td>
                          <td>Agosto</td>
                          <td>',strtrim(mean(df_agosto$clerk_queue), 5) ,'</td>
                          <td>',strtrim(mean(df_agosto$automatic_clerk_queue), 5) ,'</td>
                          <td>',strtrim(mean(df_agosto$delivery_queue), 5) ,'</td>
                          <td>',strtrim(mean(df_agosto$seating_queue), 5) ,'</td>
                          </tr>
                          <tr>
                          <td>8.</td>
                          <td>Septiembre</td>
                          <td>',strtrim(mean(df_septiembre$clerk_queue), 5) ,'</td>
                          <td>',strtrim(mean(df_septiembre$automatic_clerk_queue), 5) ,'</td>
                          <td>',strtrim(mean(df_septiembre$delivery_queue), 5) ,'</td>
                          <td>',strtrim(mean(df_septiembre$seating_queue), 5) ,'</td>
                          </tr>
                          <tr>
                          <td>9.</td>
                          <td>Octubre</td>
                          <td>',strtrim(mean(df_octubre$clerk_queue), 5) ,'</td>
                          <td>',strtrim(mean(df_octubre$automatic_clerk_queue), 5) ,'</td>
                          <td>',strtrim(mean(df_octubre$delivery_queue), 5) ,'</td>
                          <td>',strtrim(mean(df_octubre$seating_queue), 5) ,'</td>
                          </tr>
                          <tr>
                          <td>10.</td>
                          <td>Noviembre</td>
                          <td>',strtrim(mean(df_noviembre$clerk_queue), 5) ,'</td>
                          <td>',strtrim(mean(df_noviembre$automatic_clerk_queue), 5) ,'</td>
                          <td>',strtrim(mean(df_noviembre$delivery_queue), 5) ,'</td>
                          <td>',strtrim(mean(df_noviembre$seating_queue), 5) ,'</td>
                          </tr>
                          <tr>
                          <td>11.</td>
                          <td>Diciembre</td>
                          <td>',strtrim(mean(df_diciembre$clerk_queue), 5) ,'</td>
                          <td>',strtrim(mean(df_diciembre$automatic_clerk_queue), 5) ,'</td>
                          <td>',strtrim(mean(df_diciembre$delivery_queue), 5) ,'</td>
                          <td>',strtrim(mean(df_diciembre$seating_queue), 5) ,'</td>
                          </tr>
                          </table>', sep = ""
                    )
                )
                return(obj)
            })


    })

    observeEvent(input$simulacion_con_turnos,{
        source_python("simulations.py")

        cantCajas <-input$cantCajas
        tiempoCaja <- input$tiempoCaja
        cantServidores <- input$cantServidores
        cantAsientos <- input$cantAsientos
        tiempoCocina <- input$tiempoCocina
        cantMenus <- input$cantMenus
        cantAC <- input$cantAC

        f1 <- input$primerTurno
        f2 <- input$segundoTurno
        f3 <- input$tercerTurno
        f4 <- input$cuartoTurno

        # name | month | facultad | start_time | end_time | clerk_queue | automatic_clerk_queue | delivery_queue | seating_queue | total_waiting_time | activity_time
        resultados <- simular_conturnos(cantCajas, tiempoCaja, cantServidores, cantAsientos, tiempoCocina, cantMenus, cantAC, f1, f2, f3, f4)
        saveRDS(resultados, file = "res_t.rds")
        # resource | avg_queue_length | max_queue_length | avg_count
        recursos <- get_resources()
        saveRDS(recursos, file = "resources_t.rds")
        # Calculamos las medidas de performance

        output$wt_mensual_tfac <- renderPlot({
            df <- resultados[resultados$month %in% input$monthSelection_tfac,]
            results <- aggregate(total_waiting_time ~ month, df, FUN = mean)
            ggplot(results, aes(x=month, y=total_waiting_time, fill=month))+
                geom_bar(stat="identity")+
                guides(fill=FALSE)+
                geom_text(aes(label=strtrim(total_waiting_time, 5)), vjust=1.6, color="black", size=3.5)+
                theme(legend.position="none")+
                blank_theme

        })


        output$pieTiempoUtil_tfac <- renderPlot({
            df <- resultados[resultados$month %in% input$monthSelection_tfac,]
            avg_rt <- c(mean(df$end_time - df$start_time))
            tiempo_util <- c(mean(df$activity_time) / avg_rt)

            valores <- c(1 - tiempo_util[[1]], tiempo_util[[1]])
            tiempos <- c("Tiempo esperando", "Tiempo util")
            ggplot(data.frame(tiempos, valores), aes(x="", y=valores, fill=tiempos))+
                geom_bar(width = 1, stat = "identity")+
                coord_polar("y", start=0)+
                blank_theme

        })

        output$parametros_tfac <- renderUI(HTML(paste("<B>", "Cantidad de cajas:", "</B>", cantCajas, "<br><br><B>", "Tiempo en la caja:", "</B>", tiempoCaja, "<br><br><B>", "Cantidad de mozos:", "</B>", cantServidores,
                                                 "<br><br><B>", "Cantidad de asientos:", "</B>", cantAsientos, "<br><br><B>", "Tiempo de cocina:", "</B>", tiempoCocina, "<br><br><B>", "Cantidad de menus por tiempo:", "</B>", cantMenus,
                                                 "<br><br><B>", "Cantidad de cajas automaticas:", "</B>", cantAC,
                                                 "<br><br><B>", "Primer turno:", "</B>", f1,
                                                 "<br><br><B>", "Segundo turno:", "</B>", f2,
                                                 "<br><br><B>", "Tercer turno:", "</B>", f3,
                                                 "<br><br><B>", "Cuarto turno:", "</B>", f4)))


        output$total_waiting_time_tfac <- renderUI({
            df <- resultados[resultados$month %in% input$monthSelection_tfac,]
            paste(strtrim(mean(df$total_waiting_time), 5), "minutos", sep=" ")
        })

        output$cant_atendidos_tfac <- renderUI({
            df <- resultados[resultados$month %in% input$monthSelection_tfac,]
            paste(strtrim(nrow(df)/11, 5), "personas", sep=" ")
        })

        output$info_tfac <- renderUI({
            # name | month | facultad | start_time | end_time | clerk_queue | automatic_clerk_queue | delivery_queue | seating_queue | total_waiting_time | activity_time
            df_febrero <- resultados[resultados$month == 2,]
            df_marzo <- resultados[resultados$month == 3,]
            df_abril <- resultados[resultados$month == 4,]
            df_mayo <- resultados[resultados$month == 5,]
            df_junio <- resultados[resultados$month == 6,]
            df_julio <- resultados[resultados$month == 7,]
            df_agosto <- resultados[resultados$month == 8,]
            df_septiembre <- resultados[resultados$month == 9,]
            df_octubre <- resultados[resultados$month == 10,]
            df_noviembre <- resultados[resultados$month == 11,]
            df_diciembre <- resultados[resultados$month == 12,]
            obj <- HTML(
                paste('<table class="table table-striped">
                      <tr>
                      <th style="width: 10px">#</th>
                      <th>Mes</th>
                      <th>Caja</th>
                      <th style="width: 150px">Caja automatica</th>
                      <th>Delivery</th>
                      <th>Asientos</th>
                      </tr>
                      <tr>
                      <td>1.</td>
                      <td>Febrero</td>
                      <td>',strtrim(mean(df_febrero$clerk_queue), 5) ,'</td>
                      <td>',strtrim(mean(df_febrero$automatic_clerk_queue), 5) ,'</td>
                      <td>',strtrim(mean(df_febrero$delivery_queue), 5) ,'</td>
                      <td>',strtrim(mean(df_febrero$seating_queue), 5) ,'</td>
                      </tr>
                      <tr>
                      <td>2.</td>
                      <td>Marzo</td>
                      <td>',strtrim(mean(df_marzo$clerk_queue), 5) ,'</td>
                      <td>',strtrim(mean(df_marzo$automatic_clerk_queue), 5) ,'</td>
                      <td>',strtrim(mean(df_marzo$delivery_queue), 5) ,'</td>
                      <td>',strtrim(mean(df_marzo$seating_queue), 5) ,'</td>
                      <tr>
                      <td>3.</td>
                      <td>Abril</td>
                      <td>',strtrim(mean(df_marzo$clerk_queue), 5) ,'</td>
                      <td>',strtrim(mean(df_marzo$automatic_clerk_queue), 5) ,'</td>
                      <td>',strtrim(mean(df_marzo$delivery_queue), 5) ,'</td>
                      <td>',strtrim(mean(df_marzo$seating_queue), 5) ,'</td>
                      </tr>
                      <tr>
                      <td>4.</td>
                      <td>Mayo</td>
                      <td>',strtrim(mean(df_mayo$clerk_queue), 5) ,'</td>
                      <td>',strtrim(mean(df_mayo$automatic_clerk_queue), 5) ,'</td>
                      <td>',strtrim(mean(df_mayo$delivery_queue), 5) ,'</td>
                      <td>',strtrim(mean(df_mayo$seating_queue), 5) ,'</td>
                      </tr>
                      <tr>
                      <td>5.</td>
                      <td>Junio</td>
                      <td>',strtrim(mean(df_junio$clerk_queue), 5) ,'</td>
                      <td>',strtrim(mean(df_junio$automatic_clerk_queue), 5) ,'</td>
                      <td>',strtrim(mean(df_junio$delivery_queue), 5) ,'</td>
                      <td>',strtrim(mean(df_junio$seating_queue), 5) ,'</td>
                      </tr>
                      <tr>
                      <td>6.</td>
                      <td>Julio</td>
                      <td>',strtrim(mean(df_julio$clerk_queue), 5) ,'</td>
                      <td>',strtrim(mean(df_julio$automatic_clerk_queue), 5) ,'</td>
                      <td>',strtrim(mean(df_julio$delivery_queue), 5) ,'</td>
                      <td>',strtrim(mean(df_julio$seating_queue), 5) ,'</td>
                      </tr>
                      <tr>
                      <td>7.</td>
                      <td>Agosto</td>
                      <td>',strtrim(mean(df_agosto$clerk_queue), 5) ,'</td>
                      <td>',strtrim(mean(df_agosto$automatic_clerk_queue), 5) ,'</td>
                      <td>',strtrim(mean(df_agosto$delivery_queue), 5) ,'</td>
                      <td>',strtrim(mean(df_agosto$seating_queue), 5) ,'</td>
                      </tr>
                      <tr>
                      <td>8.</td>
                      <td>Septiembre</td>
                      <td>',strtrim(mean(df_septiembre$clerk_queue), 5) ,'</td>
                      <td>',strtrim(mean(df_septiembre$automatic_clerk_queue), 5) ,'</td>
                      <td>',strtrim(mean(df_septiembre$delivery_queue), 5) ,'</td>
                      <td>',strtrim(mean(df_septiembre$seating_queue), 5) ,'</td>
                      </tr>
                      <tr>
                      <td>9.</td>
                      <td>Octubre</td>
                      <td>',strtrim(mean(df_octubre$clerk_queue), 5) ,'</td>
                      <td>',strtrim(mean(df_octubre$automatic_clerk_queue), 5) ,'</td>
                      <td>',strtrim(mean(df_octubre$delivery_queue), 5) ,'</td>
                      <td>',strtrim(mean(df_octubre$seating_queue), 5) ,'</td>
                      </tr>
                      <tr>
                      <td>10.</td>
                      <td>Noviembre</td>
                      <td>',strtrim(mean(df_noviembre$clerk_queue), 5) ,'</td>
                      <td>',strtrim(mean(df_noviembre$automatic_clerk_queue), 5) ,'</td>
                      <td>',strtrim(mean(df_noviembre$delivery_queue), 5) ,'</td>
                      <td>',strtrim(mean(df_noviembre$seating_queue), 5) ,'</td>
                      </tr>
                      <tr>
                      <td>11.</td>
                      <td>Diciembre</td>
                      <td>',strtrim(mean(df_diciembre$clerk_queue), 5) ,'</td>
                      <td>',strtrim(mean(df_diciembre$automatic_clerk_queue), 5) ,'</td>
                      <td>',strtrim(mean(df_diciembre$delivery_queue), 5) ,'</td>
                      <td>',strtrim(mean(df_diciembre$seating_queue), 5) ,'</td>
                      </tr>
                      </table>', sep = ""
                    )
                )
                return(obj)
            })
    })

    observeEvent(input$simulacion_tcan,{
        source_python("simulations.py")

        cantCajas <-input$cantCajas
        tiempoCaja <- input$tiempoCaja
        cantServidores <- input$cantServidores
        cantAsientos <- input$cantAsientos
        tiempoCocina <- input$tiempoCocina
        cantMenus <- input$cantMenus
        cantAC <- input$cantAC
        cantPersonas <- input$cantPersonas

        # name | month | facultad | start_time | end_time | clerk_queue | automatic_clerk_queue | delivery_queue | seating_queue | total_waiting_time | activity_time
        resultados <- simular_turnoscapacidad(cantCajas, tiempoCaja, cantServidores, cantAsientos, tiempoCocina, cantMenus, cantAC, cantPersonas)
        saveRDS(resultados, file = "res_tcan.rds")
        # resource | avg_queue_length | max_queue_length | avg_count
        recursos <- get_resources()
        saveRDS(recursos, file = "resources_tcan.rds")


        output$wt_mensual_tcan <- renderPlot({
            df <- resultados[resultados$month %in% input$monthSelection_tcan,]
            results <- aggregate(total_waiting_time ~ month, df, FUN = mean)
            ggplot(results, aes(x=month, y=total_waiting_time, fill=month))+
                geom_bar(stat="identity")+
                guides(fill=FALSE)+
                geom_text(aes(label=strtrim(total_waiting_time, 5)), vjust=1.6, color="black", size=3.5)+
                theme(legend.position="none")+
                blank_theme

        })

        output$pieTiempoUtil_tcan <- renderPlot({
            df <- resultados[resultados$month %in% input$monthSelection_tcan,]
            avg_rt <- c(mean(df$end_time - df$start_time))
            tiempo_util <- c(mean(df$activity_time) / avg_rt)

            valores <- c(1 - tiempo_util[[1]], tiempo_util[[1]])
            tiempos <- c("Tiempo esperando", "Tiempo util")
            ggplot(data.frame(tiempos, valores), aes(x="", y=valores, fill=tiempos))+
                geom_bar(width = 1, stat = "identity")+
                coord_polar("y", start=0)+
                blank_theme

        })

        output$parametros_tcan <- renderUI(HTML(paste("<B>", "Cantidad de cajas:", "</B>", cantCajas, "<br><br><B>", "Tiempo en la caja:", "</B>", tiempoCaja, "<br><br><B>", "Cantidad de mozos:", "</B>", cantServidores,
                                                 "<br><br><B>", "Cantidad de asientos:", "</B>", cantAsientos, "<br><br><B>", "Tiempo de cocina:", "</B>", tiempoCocina, "<br><br><B>", "Cantidad de menus por tiempo:", "</B>", cantMenus,
                                                 "<br><br><B>", "Cantidad de cajas automaticas:", "</B>", cantAC, "<br><br><B>", "Cantidad de personas:", "</B>", cantPersonas)))

        output$total_waiting_time_tcan <- renderUI({
            df <- resultados[resultados$month %in% input$monthSelection_tcan,]
            paste(strtrim(mean(df$total_waiting_time), 5), "minutos", sep=" ")
        })

        output$cant_atendidos_tcan <- renderUI({
            df <- resultados[resultados$month %in% input$monthSelection_tcan,]
            paste(strtrim(nrow(df)/11, 5), "personas", sep=" ")
        })

        output$info_tcan <- renderUI({
            # name | month | facultad | start_time | end_time | clerk_queue | automatic_clerk_queue | delivery_queue | seating_queue | total_waiting_time | activity_time
            df_febrero <- resultados[resultados$month == 2,]
            df_marzo <- resultados[resultados$month == 3,]
            df_abril <- resultados[resultados$month == 4,]
            df_mayo <- resultados[resultados$month == 5,]
            df_junio <- resultados[resultados$month == 6,]
            df_julio <- resultados[resultados$month == 7,]
            df_agosto <- resultados[resultados$month == 8,]
            df_septiembre <- resultados[resultados$month == 9,]
            df_octubre <- resultados[resultados$month == 10,]
            df_noviembre <- resultados[resultados$month == 11,]
            df_diciembre <- resultados[resultados$month == 12,]
            obj <- HTML(
                paste('<table class="table table-striped">
                      <tr>
                      <th style="width: 10px">#</th>
                      <th>Mes</th>
                      <th>Caja</th>
                      <th style="width: 150px">Caja automatica</th>
                      <th>Delivery</th>
                      <th>Asientos</th>
                      </tr>
                      <tr>
                      <td>1.</td>
                      <td>Febrero</td>
                      <td>',strtrim(mean(df_febrero$clerk_queue), 5) ,'</td>
                      <td>',strtrim(mean(df_febrero$automatic_clerk_queue), 5) ,'</td>
                      <td>',strtrim(mean(df_febrero$delivery_queue), 5) ,'</td>
                      <td>',strtrim(mean(df_febrero$seating_queue), 5) ,'</td>
                      </tr>
                      <tr>
                      <td>2.</td>
                      <td>Marzo</td>
                      <td>',strtrim(mean(df_marzo$clerk_queue), 5) ,'</td>
                      <td>',strtrim(mean(df_marzo$automatic_clerk_queue), 5) ,'</td>
                      <td>',strtrim(mean(df_marzo$delivery_queue), 5) ,'</td>
                      <td>',strtrim(mean(df_marzo$seating_queue), 5) ,'</td>
                      <tr>
                      <td>3.</td>
                      <td>Abril</td>
                      <td>',strtrim(mean(df_marzo$clerk_queue), 5) ,'</td>
                      <td>',strtrim(mean(df_marzo$automatic_clerk_queue), 5) ,'</td>
                      <td>',strtrim(mean(df_marzo$delivery_queue), 5) ,'</td>
                      <td>',strtrim(mean(df_marzo$seating_queue), 5) ,'</td>
                      </tr>
                      <tr>
                      <td>4.</td>
                      <td>Mayo</td>
                      <td>',strtrim(mean(df_mayo$clerk_queue), 5) ,'</td>
                      <td>',strtrim(mean(df_mayo$automatic_clerk_queue), 5) ,'</td>
                      <td>',strtrim(mean(df_mayo$delivery_queue), 5) ,'</td>
                      <td>',strtrim(mean(df_mayo$seating_queue), 5) ,'</td>
                      </tr>
                      <tr>
                      <td>5.</td>
                      <td>Junio</td>
                      <td>',strtrim(mean(df_junio$clerk_queue), 5) ,'</td>
                      <td>',strtrim(mean(df_junio$automatic_clerk_queue), 5) ,'</td>
                      <td>',strtrim(mean(df_junio$delivery_queue), 5) ,'</td>
                      <td>',strtrim(mean(df_junio$seating_queue), 5) ,'</td>
                      </tr>
                      <tr>
                      <td>6.</td>
                      <td>Julio</td>
                      <td>',strtrim(mean(df_julio$clerk_queue), 5) ,'</td>
                      <td>',strtrim(mean(df_julio$automatic_clerk_queue), 5) ,'</td>
                      <td>',strtrim(mean(df_julio$delivery_queue), 5) ,'</td>
                      <td>',strtrim(mean(df_julio$seating_queue), 5) ,'</td>
                      </tr>
                      <tr>
                      <td>7.</td>
                      <td>Agosto</td>
                      <td>',strtrim(mean(df_agosto$clerk_queue), 5) ,'</td>
                      <td>',strtrim(mean(df_agosto$automatic_clerk_queue), 5) ,'</td>
                      <td>',strtrim(mean(df_agosto$delivery_queue), 5) ,'</td>
                      <td>',strtrim(mean(df_agosto$seating_queue), 5) ,'</td>
                      </tr>
                      <tr>
                      <td>8.</td>
                      <td>Septiembre</td>
                      <td>',strtrim(mean(df_septiembre$clerk_queue), 5) ,'</td>
                      <td>',strtrim(mean(df_septiembre$automatic_clerk_queue), 5) ,'</td>
                      <td>',strtrim(mean(df_septiembre$delivery_queue), 5) ,'</td>
                      <td>',strtrim(mean(df_septiembre$seating_queue), 5) ,'</td>
                      </tr>
                      <tr>
                      <td>9.</td>
                      <td>Octubre</td>
                      <td>',strtrim(mean(df_octubre$clerk_queue), 5) ,'</td>
                      <td>',strtrim(mean(df_octubre$automatic_clerk_queue), 5) ,'</td>
                      <td>',strtrim(mean(df_octubre$delivery_queue), 5) ,'</td>
                      <td>',strtrim(mean(df_octubre$seating_queue), 5) ,'</td>
                      </tr>
                      <tr>
                      <td>10.</td>
                      <td>Noviembre</td>
                      <td>',strtrim(mean(df_noviembre$clerk_queue), 5) ,'</td>
                      <td>',strtrim(mean(df_noviembre$automatic_clerk_queue), 5) ,'</td>
                      <td>',strtrim(mean(df_noviembre$delivery_queue), 5) ,'</td>
                      <td>',strtrim(mean(df_noviembre$seating_queue), 5) ,'</td>
                      </tr>
                      <tr>
                      <td>11.</td>
                      <td>Diciembre</td>
                      <td>',strtrim(mean(df_diciembre$clerk_queue), 5) ,'</td>
                      <td>',strtrim(mean(df_diciembre$automatic_clerk_queue), 5) ,'</td>
                      <td>',strtrim(mean(df_diciembre$delivery_queue), 5) ,'</td>
                      <td>',strtrim(mean(df_diciembre$seating_queue), 5) ,'</td>
                      </tr>
                      </table>', sep = ""
                    )
                )
                return(obj)
            })
    })

    output$twt_c <- renderPlot({
        if (file.exists("res_basic.rds"))
            resultados_basicos <- readRDS("res_basic.rds")
        if (file.exists("res_t.rds"))
            resultados_tfac <- readRDS("res_t.rds")
        if (file.exists("res_tcan.rds"))
            resultados_tcan <- readRDS("res_tcan.rds")

        resultados_basicos <- resultados_basicos[resultados_basicos$month %in% input$monthSelection_c,]
        resultados_tfac <- resultados_tfac[resultados_tfac$month %in% input$monthSelection_c,]
        resultados_tcan <- resultados_tcan[resultados_tcan$month %in% input$monthSelection_c,]

        tiempos <- c(mean(resultados_basicos$total_waiting_time), mean(resultados_tfac$total_waiting_time), mean(resultados_tcan$total_waiting_time))
        simulaciones <- c("Basica", "Turnos por facultad", "Turnos por cantidad")

        ggplot(data.frame(simulaciones, tiempos), aes(x=simulaciones, y=tiempos, fill=simulaciones))+
            geom_bar(stat="identity")+
            guides(fill=FALSE)+
            geom_text(aes(label=strtrim(tiempos, 5)), vjust=1.6, color="black", size=3.5)+
            theme(legend.position="none")+
            blank_theme

    })

    output$resources_table <- renderUI({

        if (file.exists("res_basic.rds"))
            resultados_basicos <- readRDS("res_basic.rds")
        if (file.exists("res_t.rds"))
            resultados_tfac <- readRDS("res_t.rds")
        if (file.exists("res_tcan.rds"))
            resultados_tcan <- readRDS("res_tcan.rds")

        resultados_basicos <- resultados_basicos[resultados_basicos$month %in% input$monthSelection_c,]
        resultados_tfac <- resultados_tfac[resultados_tfac$month %in% input$monthSelection_c,]
        resultados_tcan <- resultados_tcan[resultados_tcan$month %in% input$monthSelection_c,]

        obj <- HTML(
            paste('<table class="table table-striped">
                  <tr>
                  <th style="width: 10px">#</th>
                  <th>Simulacion</th>
                  <th>Caja</th>
                  <th >Caja automatica</th>
                  <th>Delivery</th>
                  <th>Asientos</th>
                  </tr>
                  <tr>
                  <td>1.</td>
                  <td>Simulacion basica</td>
                  <td>',strtrim(mean(resultados_basicos$clerk_queue), 5) ,'</td>
                  <td>',strtrim(mean(resultados_basicos$automatic_clerk_queue), 5) ,'</td>
                  <td>',strtrim(mean(resultados_basicos$delivery_queue), 5) ,'</td>
                  <td>',strtrim(mean(resultados_basicos$seating_queue), 5) ,'</td>
                  </tr>
                  <tr>
                  <td>2.</td>
                  <td>Turnos (Facultad)</td>
                  <td>',strtrim(mean(resultados_tfac$clerk_queue), 5) ,'</td>
                  <td>',strtrim(mean(resultados_tfac$automatic_clerk_queue), 5) ,'</td>
                  <td>',strtrim(mean(resultados_tfac$delivery_queue), 5) ,'</td>
                  <td>',strtrim(mean(resultados_tfac$seating_queue), 5) ,'</td>
                  <tr>
                  <td>3.</td>
                  <td>Turnos (Cantidad)</td>
                  <td>',strtrim(mean(resultados_tcan$clerk_queue), 5) ,'</td>
                  <td>',strtrim(mean(resultados_tcan$automatic_clerk_queue), 5) ,'</td>
                  <td>',strtrim(mean(resultados_tcan$delivery_queue), 5) ,'</td>
                  <td>',strtrim(mean(resultados_tcan$seating_queue), 5) ,'</td>
                  </tr>
                  </table>', sep = ""
                    )
                )
                return(obj)




    })

    output$parametros_c <- renderUI({
        HTML(paste("<B>", "Cantidad de cajas:", "</B>", input$cantCajas,
                   "<br><br><B>", "Tiempo en la caja:", "</B>", input$tiempoCaja,
                   "<br><br><B>", "Cantidad de mozos:", "</B>", input$cantServidores,
                   "<br><br><B>", "Cantidad de asientos:", "</B>", input$cantAsientos,
                   "<br><br><B>", "Tiempo de cocina:", "</B>", input$tiempoCocina,
                   "<br><br><B>", "Cantidad de menus por tiempo:", "</B>", input$cantMenus,
                   "<br><br><B>", "Cantidad de cajas automaticas:", "</B>", input$cantAC,
                   "<br><br><B>", "Primer turno:", "</B>", input$primerTurno,
                   "<br><br><B>", "Segundo turno:", "</B>", input$segundoTurno,
                   "<br><br><B>", "Tercer turno:", "</B>", input$tercerTurno,
                   "<br><br><B>", "Cuarto turno:", "</B>", input$cuartoTurno,
                   "<br><br><B>", "Cantidad de personas:", "</B>", input$cantPersonas))
    })


    output$performance_table <- renderUI({
        if (file.exists("res_basic.rds"))
            resultados_basicos <- readRDS("res_basic.rds")
        if (file.exists("res_t.rds"))
            resultados_tfac <- readRDS("res_t.rds")
        if (file.exists("res_tcan.rds"))
            resultados_tcan <- readRDS("res_tcan.rds")

        resultados_basicos <- resultados_basicos[resultados_basicos$month %in% input$monthSelection_c,]
        resultados_tfac <- resultados_tfac[resultados_tfac$month %in% input$monthSelection_c,]
        resultados_tcan <- resultados_tcan[resultados_tcan$month %in% input$monthSelection_c,]

        tiempo_util_basico <- (mean(resultados_basicos$activity_time) * 100) /(mean(resultados_basicos$total_waiting_time) + mean(resultados_basicos$activity_time))
        tiempo_util_tfac <- (mean(resultados_tfac$activity_time) * 100) /(mean(resultados_tfac$total_waiting_time) + mean(resultados_tfac$activity_time))
        tiempo_util_tcan <- (mean(resultados_tcan$activity_time) * 100) /(mean(resultados_tcan$total_waiting_time) + mean(resultados_tcan$activity_time))

        obj <- HTML(
            paste('<table class="table table-striped">
                  <tr>
                      <th style="width: 10px">#</th>
                      <th>Performance</th>
                      <th>Simple</th>
                      <th >Turnos (Facultad)</th>
                      <th>Turnos (Cantidad)</th>
                  </tr>
                  <tr>
                      <td>1.</td>
                      <td>Tiempo de espera por persona</td>
                      <td>',strtrim(mean(resultados_basicos$total_waiting_time), 5) ,'</td>
                      <td>',strtrim(mean(resultados_tfac$total_waiting_time), 5) ,'</td>
                      <td>',strtrim(mean(resultados_tcan$total_waiting_time), 5) ,'</td>
                  </tr>
                  <tr>
                      <td>2.</td>
                      <td>Promedio de clientes atendidos por hora</td>
                      <td>',strtrim(nrow(resultados_basicos)/11, 5) ,'</td>
                      <td>',strtrim(nrow(resultados_tfac)/11, 5) ,'</td>
                      <td>',strtrim(nrow(resultados_tcan)/11, 5) ,'</td>
                  <tr>
                      <td>3.</td>
                      <td>Tiempo de respuesta</td>
                      <td>',strtrim(mean(resultados_basicos$end_time - resultados_basicos$start_time), 5) ,'</td>
                      <td>',strtrim(mean(resultados_tfac$end_time - resultados_tfac$start_time), 5) ,'</td>
                      <td>',strtrim(mean(resultados_tcan$end_time - resultados_tcan$start_time), 5) ,'</td>
                  </tr>
                  <tr>
                      <td>4.</td>
                      <td>Porcentaje de tiempo util</td>
                      <td>',strtrim(tiempo_util_basico, 5) ,'</td>
                      <td>',strtrim(tiempo_util_tfac, 5) ,'</td>
                      <td>',strtrim(tiempo_util_tcan, 5) ,'</td>
                      </tr>
                  <tr>
                  </table>', sep = ""
                    )
                )
                return(obj)
    })

    output$table <- renderText(paste("Tabla:", input$table))

    output$mainTable = DT::renderDataTable({
        drv <- dbDriver("PostgreSQL")
        con <- dbConnect(drv, dbname = "comedor",
                         host = "localhost", port = 5432,
                         user = "postgres", password = "postgres")
        on.exit(dbDisconnect(con))
        rs <- dbGetQuery(con, paste("SELECT * FROM", toString(input$table), "LIMIT 1000", sep=" "))

        DT::datatable(data.table(rs), rownames = FALSE, extensions = 'Responsive',
                      options = list(dom = 'Brtip', filter = 'top'))
    })

    onStop(function(){
        if (file.exists("res_basic.rds"))
            file.remove("res_basic.rds")
        if (file.exists("res_t.rds"))
            file.remove("res_t.rds")
        if (file.exists("res_tcan.rds"))
            file.remove("res_tcan.rds")
        if (file.exists("resources_tcan.rds"))
            file.remove("resources_tcan.rds")
        if (file.exists("resources_t.rds"))
            file.remove("resources_t.rds")
        if (file.exists("resources_basic.rds"))
            file.remove("resources_basic.rds")
        if (file.exists("performances.csv"))
            file.remove("performances.csv")
    })
})
