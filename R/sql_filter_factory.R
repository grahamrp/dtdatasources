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

# Make a payload suitable for funcFilter's return value
# Provides the draw counter and formats the data
format_payload <- function(draw, payload, escape) {
  required <- c("recordsTotal", "recordsFiltered", "data",
                "DT_rows_all", "DT_rows_current")
  stopifnot(all(required %in% names(payload)))

  payload$data <- escape_data(payload$data, escape)
  payload$data <- cleanDataFrame(payload$data)

  purrr::list_modify(payload, draw = as.integer(draw))
}

# Return empty payload
# TODO: could probably implement as a call to format_payload()
empty_payload <- function(draw) {
  list(
    draw = as.integer(draw),
    recordsTotal = 0,
    recordsFiltered = 0,
    data = data.frame(),
    DT_rows_all = NULL,
    DT_rows_current = NULL
  )
}


# Functionality from DT::dataTablesFilter data.frame implementation -------

# Check if the columns are out of sync between params and data.
# Note, not sure if this is necessary for sql implementation but just copied
# from DT::dataTablesFilter, "users may be updating the table too frequently"
cols_out_of_sync <- function(data, params) {
  length(params$columns) != ncol(data)
}



# Escape html characters according to the datatable params$escape parameter
escape_data <- function(data, escape) {
  if (escape != 'false') {
    k = seq_len(ncol(data))
    if (escape != 'true') {
      # escape might be negative indices, e.g. c(-1, -5)
      k = k[as.integer(strsplit(escape, ',')[[1]])]
    }
    for (j in k) if (maybe_character(data[, j])) data[, j] = htmltools::htmlEscape(data[, j])
  }
  data
}

# treat factors as characters
maybe_character = function(x) {
  is.character(x) || is.factor(x)
}

# make sure we have a tidy data frame (no unusual structures in it)
cleanDataFrame = function(x) {
  x = unname(x)  # remove column names
  if (!is.data.frame(x)) return(x)
  for (j in seq_len(ncol(x))) {
    xj = x[, j]
    xj = unname(xj)  # remove names
    dim(xj) = NULL  # drop dimensions
    if (is.table(xj)) xj = c(xj)  # drop the table class
    x[[j]] = xj
  }
  unname(x)
}
