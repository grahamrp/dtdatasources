library(shiny)
library(DT)
library(DBI)

# Setup example database and table. Add mtcars rownames as a primary key.
con <- dbConnect(RSQLite::SQLite(), ":memory:")
dbWriteTable(con, "mtcars", cbind(car = rownames(mtcars), mtcars))

ui <- fluidPage(
  DTOutput("tbl"),
  verbatimTextOutput("debug")
)

server <- function(input, output, session) {

  # Create an initial dataframe. This only needs to contain column names, and
  # need not have any rows.
  initial_df <- dbGetQuery(con, "SELECT * FROM mtcars LIMIT 0;")

  # Create a funcFilter function describing how to get data for a datatable.
  # The filter factory
  mtcars_filter <- dtdatasources::sql_filter_factory(
    # Use the sqlite connection created above
    con = con,
    # Set the query_fun to query_sqlite, or implement your own version
    query_fun = dtdatasources::query_sqlite,
    # Any additional args are passed into query_sqlite. In query_sqlite's case
    # it accepts a `tbl` parameter for which table to use.
    tbl = "mtcars",
    id_field = "car" # Field used to identify a row when using input$tbl_rows_selected
  )

  output$tbl <- renderDT(
    initial_df,
    server = TRUE,  # Must be TRUE to perform processing in R, not in the browser
    rownames = FALSE,  # Must be FALSE
    funcFilter = mtcars_filter  # Provide the sqlite function filter
  )

  output$debug <- renderPrint({
    input$tbl_rows_selected
  })
}

shinyApp(ui, server)

