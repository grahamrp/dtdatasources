library(shiny)
library(DT)
library(DBI)

ui <- fluidPage(
  DTOutput("tbl"),
  h4("Selected rows:"),
  verbatimTextOutput("row_selections")
)

server <- function(input, output, session) {

  output$tbl <- renderDT(
    empty_election_df(),  # Initial (empty) df, with expected columns
    server = TRUE,  # Must be TRUE to perform processing in R, not in the browser
    rownames = FALSE,  # Must be FALSE
    funcFilter = election_filter  # Provide the function filter
  )

  output$row_selections <- renderPrint({
    input$tbl_rows_selected
  })
}

shinyApp(ui, server)
