
<!-- README.md is generated from README.Rmd. Please edit that file -->

# dtdatasources: Data Sources for Shiny Datatables

<!-- badges: start -->

<!-- badges: end -->

## Overview

`dtdatasources` provides Shiny [server-side
datatables](https://rstudio.github.io/DT/server.html) backends for the
DT package, allowing you to connect your datatables directly to
databases or APIs, in addition to the standard dataframes.

## Installation

You can install the development version from
[GitHub](https://github.com/) with:

``` r
# install.packages("devtools")
devtools::install_github("grahamrp/dtdatasources")
```

## Available Data Sources

  - SQLite
      - \[x\] paging
      - \[x\] sorting
      - \[x\] row selection
      - \[ \] filtering

### Contributing

So far I’ve only written a basic SQLite implementation, but would like
to create more. Feedback, bug reports, fixes, and feature requests are
welcome, see the [current
issues](http://github.com/grahamrp/dtdatasources/issues).

## About Custom DT Data Sources

When you want to use `DT::renderDataTables`/`DT::renderDT` with large
datasets you can choose to render the table on the server with
`renderDT(big_dataset, server = TRUE)`. This will perform the dataset
filtering/sorting/paging on the server where Shiny is running, instead
of in the user’s web browser, making the table more responsive.

The default DT implementation of server-side processing still requires
the data to be in a *dataframe* on the server. Sometimes we don’t want
to put the entire dataset into a dataframe, for example if it is very
big, or if it naturally belongs in a database or behind an API.

For this reason, `renderDT` provides a `funcFilter` parameter to supply
our own function that describes how to fetch, filter, sort, and page our
dataset, regardless of where the data resides.

The `dtdatasources` package will provide implementations of `funcFilter`
for various datasources, for you to use directly, or as examples to
adapt to your own implementations.

## SQLite Example

This example shows how to connect a server-side datatable to a table in
a SQLite database. Take a look at
[inst/app.R](https://github.com/grahamrp/dtdatasources/blob/master/inst/app.R)
for the shiny app, or run `shiny::runApp(system.file("app.R", package =
"dtdatasources"))`.

``` r
library(shiny)
library(DT)
library(DBI)
library(dtdatasources)

# Setup an example database and table
con <- dbConnect(RSQLite::SQLite(), ":memory:")
dbWriteTable(con, "mtcars", mtcars)

ui <- fluidPage(
  DTOutput("tbl")
)

server <- function(input, output, session) {

  # Create an initial dataframe. This only needs to contain column names, and
  # need not have any rows.
  initial_df <- dbGetQuery(con, "SELECT * FROM mtcars LIMIT 0;")

  # Create a funcFilter function describing how to get data for a datatable.
  mtcars_filter <- dtdatasources::sql_filter_factory(
    # Use the sqlite connection created above
    con = con,
    # Set the query_fun to query_sqlite, or implement your own version
    query_fun = dtdatasources::query_sqlite,
    # Any additional args are passed into query_sqlite. In query_sqlite's case
    # it accepts a `tbl` parameter for which table to use.
    tbl = "mtcars"  
  )

  # Call renderDT with our custom filter function
  output$tbl <- renderDT(
    initial_df,
    server = TRUE,  # Must be TRUE to perform processing in R, not in the browser
    rownames = FALSE,  # Must be FALSE for the query_sqlite implementation
    funcFilter = mtcars_filter  # Provide the sqlite function filter created above
  )
}

shinyApp(ui, server)
```

## Making New Data Sources

If you want to use this example to create your own implementations of DT
data sources, take a look at `sqlite.R` and provide your own version of
the `query_sqlite` function for different databases. This function
adapts the `DT:::dataTablesFilter` code on
[GitHub](https://github.com/rstudio/DT/blob/master/R/shiny.R), which is
the default `funcFilter` for filtering/sorting/paging dataframes on the
server.

## Some References for `funcFilter`

| Description                                                   | URL                                                                                                         |
| ------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------- |
| Description of the overall problem                            | [Google Groups shiny-discuss](https://groups.google.com/forum/#!msg/shiny-discuss/zaPqkMdhwy4/jHGFwBfEBQAJ) |
| Open issue to make a funcFilter example                       | <https://github.com/rstudio/DT/issues/194>                                                                  |
| Custom filtering problem with filter ranges and `filterRow()` | <https://github.com/rstudio/DT/issues/50>                                                                   |
| Row selection                                                 | <https://github.com/rstudio/DT/issues/75>                                                                   |
