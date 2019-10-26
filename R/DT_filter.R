# filter a data frame according to the DataTables request parameters
#' @param data data.frame. Everything goes in and out as a data.frame.
#' @param params list of current datatable filters/searches/sorts, etc.
#' @return list something like list(
#' draw = as.integer(q$draw),  # some sort of draw counter/sync
#' recordsTotal = n,  # total records of dataset
#' recordsFiltered = 0,  # how many records are in the filtered dataset (could be on multi pages)
#' data = list(),  # the dataframe, as a raw (no colnames) data.frame
#' DT_rows_all = seq_len(n),  # the row indices of the filtered dataset (don't know why)
#' DT_rows_current = list()  # the row indices of the data on the current page
#' )
#' @importFrom htmltools htmlEscape
myFilter <- function(data, params) {
  n <- get_total_rows(con, tbl)

  # users may be updating the table too frequently
  if (cols_out_of_sync(data, params)) return(empty_payload(n, params$draw))

  page <- get_page(con, "mtcars", params)

  page <- escape_data(page, params$escape)

  format_payload(page, n, params$draw)
}



format_payload <- function(page, n, draw) {
  list(
    draw = as.integer(draw),
    recordsTotal = n,
    recordsFiltered = n,  # We're not filtering, so same as recordsTotal
    data = cleanDataFrame(page),
    DT_rows_all = NULL,
    DT_rows_current = NULL  # What input$<tbl>_rows_selected returns
  )
}

escape_data <- function(data, escape) {
  if (escape != 'false') {
    k = seq_len(ncol(data))
    if (escape != 'true') {
      # escape might be negative indices, e.g. c(-1, -5)
      k = k[as.integer(strsplit(escape, ',')[[1]])]
    }
    for (j in k) if (maybe_character(data[, j])) data[, j] = htmlEscape(data[, j])
  }
  data
}

get_total_rows <- function(con, tbl) {

}

# Get the page of data given the current indices
# USER DEFINED FUNCTION, it will always be called with get_page(con, params, ...)
get_page <- function(con, params, tbl) {
  # Translate dt query params into a sql query
  query <- glue::glue_sql("SELECT * FROM {`tbl`} ",
                    query_to_order_by(params),
                    " LIMIT {params$length} OFFSET {params$start}",
                    .con = con)
  print(query)
  dbGetQuery(con, query)
}

# USER DEFINED FUNCTION, always called with get_count(con, ...)
get_count <- function(con, tbl) {
    query <- glue::glue_sql("SELECT COUNT (*) AS n FROM {tbl}", .con = con)
    result <- dbGetQuery(con, query)
    result$n
}

# Return ORDER BY clause or "", accounting for zero-based col indexing of q
query_to_order_by <- function(q) {
  order <- q$order
  if (is.null(order)) return("")

  orderings <- purrr::map_chr(order, ~paste(as.integer(.x$column) + 1, .x$dir))
  orderings <- paste(orderings, collapse = ", ")

  paste("ORDER BY", orderings)
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
