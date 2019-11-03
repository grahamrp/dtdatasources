library(shiny)
library(DT)
library(DBI)

# Setup example database and table
con <- dbConnect(RSQLite::SQLite(), ":memory:")
dbWriteTable(con, "mtcars", mtcars)

ui <- fluidPage(
  DTOutput("tbl")
)

server <- function(input, output, session) {

  # Create an initial dataframe. This only needs to contain column names, and
  # need not have any rows.
  initial_df <- dbGetQuery(con, "SELECT * FROM mtcars LIMIT 0;")

  # Create a funcFilter function describing how to get data for a datatable
  mtcars_filter <- sql_filter_factory(
    con,  # Use the connection created above
    query_sqlite,  # Use the query_sqlite implementation (or provide your own)
    tbl = "mtcars"  # Optional, additional args are passed into query_sqlite
  )

  output$tbl <- renderDT(
    initial_df,
    server = TRUE,  # Must be TRUE to perform processing in R, not in the browser
    rownames = FALSE,  # Must be FALSE
    funcFilter = mtcars_filter  # Provide the sqlite function filter
  )
}

shinyApp(ui, server)

