# dtdatasources: Data Sources for Shiny Datatables

## Overview

`dtdatasources` provides Shiny server-side datatables backends for the DT package.

When you want to use `DT::renderDataTables`/`DT::renderDT` with large datasets you can choose to render the table on the server with `renderDT(big_dataset, server = TRUE)`. This will perform the dataset filtering/sorting/paging on the server where Shiny
is running, instead of in the user's web browser, speeding things up for large
datasets. See [Server-side Processing](https://rstudio.github.io/DT/server.html) for 
details.

The default DT implementation of server-side processing still requires the data
to be in a *dataframe* on the server. For very large datasets, or where the data
is stored outside the Shiny process, for example in a database or API, we would
not want to copy the entire dataset into a datatable on the server, as it may
not have enough resources to hold it in memory, or enough processing power to
perform the server-side filtering/sorting/paging.

For this reason, `renderDT` provides a `funcFilter` parameter where we can provide
our own function that describes how to fetch, filter, sort, and page our dataset.
We can therefore plug datatables into wider datasources that just dataframes

The `dtdatasources` package will provide implementations of `funcFilter` for
various datasources, for you to use directly, or as examples to adapt to your
own implementations.

## Installation



## Usage







## References for `funcFilter`

https://groups.google.com/forum/#!msg/shiny-discuss/zaPqkMdhwy4/jHGFwBfEBQAJ
rstudio/DT#50
rstudio/DT#75

description | url
------------ | ---
Open issue to make a funcFilter example  | https://github.com/rstudio/DT/issues/194
Custom filtering problem with filter ranges and `filterRow()` | https://github.com/rstudio/DT/issues/50
Row selection | https://github.com/rstudio/DT/issues/75
Description of the overall problem | https://groups.google.com/forum/#!msg/shiny-discuss/zaPqkMdhwy4/jHGFwBfEBQAJ

