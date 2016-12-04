source("R/helper.R")

shinyServer(function(input, output, session){

  vals <- reactiveValues(name1 = NULL, nvote1 = 0, ncut1 = 0, run1 = 0,
                         name2 = NULL, nvote2 = 0, ncut2 = 0, run2 = 0)
  
  observe({
    player <- input$player
    mode   <- input$mode
    
    if (!is.null(player) & !is.null(mode)){
      vals$name1 <- getname1(con, player, mode)
      vals$name2 <- getname( con, player, mode)
    }
  })
  
  observe({
    input$vote1
    input$vote2
    input$cut1
    input$cut2
    
    name1 <- isolate(vals$name1)
    name2 <- isolate(vals$name2)
    player <- isolate(input$player)
    mode <- isolate(input$mode)
    
    if (input$vote1 > vals$nvote1){
      logbattle(con, player, mode, name1, name2, 1L)
      name <- getname(con, player, mode)
      while(name%in%c(name1, name2) | is.na(name)) name <- getname(con, player, mode)
      vals$name2 <- name
      vals$nvote1 <- input$vote1
      vals$run1 <- vals$run1 + 1
      vals$run2 <- 0
      if (vals$run1 >= input$term){
        vals$run1 <- 0
        name <- getname1(con, input$player, input$mode)
        while(name%in%c(name1, vals$name2) | is.na(name)) name <- getname1(con, player, mode)
        vals$name1 <- name
      }
    }
    else if (input$vote2 > vals$nvote2){
      logbattle(con, player, mode, name1, name2, 2L)
      name <- getname1(con, player, mode)
      while(name%in%c(name1, name2) | is.na(name)) name <- getname1(con, player, mode)
      vals$name1 <- name
      vals$nvote2 <- input$vote2
      vals$run2 <- vals$run2 + 1
      vals$run1 <- 0
      if (vals$run2 >= input$term){
        vals$run2 <- 0
        name <- getname(con, player, mode)
        while(name%in%c(vals$name1, name2) | is.na(name)) name <- getname(con, player, mode)
        vals$name2 <- name
      }
    }
    else if (input$cut1 > vals$ncut1){
      vals$run1 <- 0
      cut0(con, player, mode, name1)
      name <- getname1(con, player, mode)
      while(name%in%c(name1, name2) | is.na(name)) name <- getname1(con, player, mode)
      vals$name1 <- name
      vals$ncut1 <- input$cut1
    }
    else if (input$cut2 > vals$ncut2){
      vals$run2 <- 0
      cut0(con, player, mode, name2)
      name <- getname(con, input$player, input$mode)
      while(name%in%c(vals$name1, vals$name2)|is.na(name)) name <- getname(con, player, mode)
      vals$name2 <- name
      vals$ncut2 <- input$cut2
    }

    output$name1 <- renderText(vals$name1)
    output$name2 <- renderText(vals$name2)
   })
  
  observeEvent(input$standings, {
    showModal(modalDialog(
      title = "STANDINGS",
      DT::renderDataTable(getbattlesummary(con, input$player, input$mode)[1:10,.(name, `win percent`)],
                          rownames = FALSE,
                          options=list(paging = FALSE, searching = FALSE)),
      size = "l",
      easyClose = TRUE,
      footer = modalButton("Close")
    ), session)
  })

  observe({
    if (is.null(input$restore)) return()
    player <- isolate(input$player)
    mode <- isolate(input$mode)
    name <- input$restore$name
    restore(con, player, mode, name)
    dt <- getscratched(con, player, mode)[, .(name, `win percent`)]
    dt$action <- paste0('<a class="restore" href="" data-name="', dt$name, '">restore</a>')
    showModal(modalDialog(
      title = "REVIEW",
      DT::renderDataTable(dt, escape = FALSE, rownames = FALSE),
      size = "l",
      easyClose = TRUE,
      footer = modalButton("Close")
    ), session)
  })
   
  observeEvent(input$review, {
    input$cut1
    input$cut2
    player <- isolate(input$player)
    mode <- isolate(input$mode)
    dt <- getscratched(con, player, mode)[, .(name, `win percent`)]
    dt$action <- paste0('<a class="restore" href="" data-name="', dt$name, '">restore</a>')
    showModal(modalDialog(
      title = "REVIEW",
      DT::renderDataTable(dt, escape = FALSE, rownames = FALSE),
      size = "l",
      easyClose = TRUE,
      footer = modalButton("Close")
    ), session)
  })
})