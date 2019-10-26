#' Sqlite implementation of a query_fun.
#'
#' Simple implementation showing how to implement a \code{query_fun} for a sqlite DB.
#'
#' This function can be provided to sql_filter_factory to describe how to
#' fetch a datatable payload from a sqlite table.
#'
#' Use as a template to implement other backends.
#'
#' Will be called via \code{sql_filter_factory} with arguments
#' \code{con}, \code{page}, and \code{...} where \code{...} are extra arguments
#' passed to \code{sql_filter_factory}.
#'
#' @param con DBI database connection
#' @param params named list provided by a datatable containing sorting, filtering
#'   and pagination data.
#' @param tbl string, the table/view in sqlite.
#' @export
#' @examples
#' \dontrun{
#' sql_filter_factory(con, query_sqlite, tbl = "mtcars")
#' }
query_sqlite <- function(con, params, tbl) {

  recordsTotal = get_sqlite_count(con, tbl)
  recordsFiltered = recordsTotal  # Not implemented
  data = get_sqlite_page(con, params, tbl)
  DT_rows_all = NULL  # Not implemented
  DT_rows_current = NULL  # Not implemented

  list(
    recordsTotal = recordsTotal,
    recordsFiltered = recordsFiltered,
    data = data,
    DT_rows_all = DT_rows_all,
    DT_rows_current = DT_rows_current
  )
}

# Get rows from tbl for the visible datatable page
get_sqlite_page <- function(con, params, tbl) {
  # Translate dt query params into a sql query
  query <- glue::glue_sql("SELECT * FROM {`tbl`} ",
                    order_by_clause(params),
                    " LIMIT {params$length} OFFSET {params$start}",
                    .con = con)
  message(query)
  DBI::dbGetQuery(con, query)
}

# Get the total record count in tbl
get_sqlite_count <- function(con, tbl) {
    query <- glue::glue_sql("SELECT COUNT (*) AS n FROM {tbl}", .con = con)
    result <- DBI::dbGetQuery(con, query)
    result$n
}

# Return ORDER BY clause or "", accounting for zero-based col indexing of q
order_by_clause <- function(params) {
  order <- params$order
  if (is.null(order)) return("")

  orderings <- purrr::map_chr(order, ~paste(as.integer(.x$column) + 1, .x$dir))
  orderings <- paste(orderings, collapse = ", ")

  paste("ORDER BY", orderings)
}

