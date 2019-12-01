#' Create a DT funcFilter for SQL connections.
#'
#' Given a DBI connection and a query function return a funcFilter function
#' as required by DT::renderDT.
#'
#' The main purpose of this function is to keep a reference to the database
#' connection so as to prevent the need to set up a new connection every time
#' data is accessed by the funcFilter.
#'
#' It also allows for different implementations of \code{query_fun} so as not
#' to be limited to just the current sqlite implementation.
#'
#' @return function conforming to a DT funcFilter interface.
#' @param con DBI database connection for \code{query_fun} to use.
#' @param query_fun function that takes \code{con} and \code{params} parameters
#'   and returns payload for a datatable. See \code{query_sqlite} for an example.
#' @param ... Additional arguments passed to \code{query_fun}.
#' @export
#' @examples
#' \dontrun{
#' con <- dbConnect(RSQLite::SQLite(), ":memory:")
#' dbWriteTable(con, "mtcars", mtcars)
#' myFuncFilter <- sql_filter_factory(con, query_sqlite, tbl = "mtcars")
#' }
sql_filter_factory <- function(con, query_fun, ...) {

  con <- force(con)
  query_fun <- force(query_fun)

  function(data, params) {
    # Note, "data" argument is ignored as we're getting records from a database.

    if (cols_out_of_sync(data, params)) return(empty_payload(params$draw))

    payload <- query_fun(con = con, params = params, ...)
    format_payload(payload, draw = params$draw, escape = params$escape)
  }
}
