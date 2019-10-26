# Given a query function and a count function, return a funcFilter
# as required by DT
sql_filter_factory <- function(con, get_page, get_count, ...) {

  con <- force(con)

  query_fun <- function(params) {
    get_page(con, params, ...)
  }

  count_fun <- function() {
    get_count(con, ...)
  }

  function(data, params) {
    n <- count_fun()

    # users may be updating the table too frequently
    if (cols_out_of_sync(data, params)) return(empty_payload(n, params$draw))

    page <- query_fun(params)
    page <- escape_data(page, params$escape)
    format_payload(page, n, params$draw)
  }

}
