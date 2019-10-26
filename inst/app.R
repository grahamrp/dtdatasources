library(shiny)
library(DT)
library(DBI)

ui <- fluidPage(
  verbatimTextOutput("debug"),
  DTOutput("tbl")
)

server <- function(input, output, session) {

  output$debug <- renderPrint({
    input$tbl_rows_selected
  })

  con <- dbConnect(RSQLite::SQLite(), ":memory:")
  dbWriteTable(con, "mtcars", mtcars)

  initial_df <- dbGetQuery(con, "SELECT * FROM mtcars LIMIT 0;")


  myF <- sql_filter_factory(con, get_page, get_count, tbl = "mtcars")

  output$tbl <- renderDT(initial_df, server = TRUE,
                         rownames = T, funcFilter = myF)

}

shinyApp(ui, server)

