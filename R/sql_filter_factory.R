#' Create a DT funcFilter for SQL connections.
#'
#' Given a DBI connection and a query function return a funcFilter function
#' as required by DT::renderDT.
#'
#' The \code{con} is enclosed so we don't have to recreate a database connection
# for every query.
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
