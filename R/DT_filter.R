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
myFilter = function(data, params) {
  cat(file = stderr(), "called myFilter\n")
  n = get_total_rows(con, tbl)
  q = params

  # use "data" for column names to translate beteen indices and field names
  cn <- colnames(data)


  # users may be updating the table too frequently
  if (cols_out_of_sync(data, params)) return(empty_payload(n, params$draw))

  iAll = seq_len(n)

  # paging
  iCurrent <- get_page_indices(q$start, q$length, iAll)
  fdata <- get_page(con, "mtcars", q)

  if (q$escape != 'false') {
    k = seq_len(ncol(fdata))
    if (q$escape != 'true') {
      # q$escape might be negative indices, e.g. c(-1, -5)
      k = k[as.integer(strsplit(q$escape, ',')[[1]])]
    }
    for (j in k) if (maybe_character(fdata[, j])) fdata[, j] = htmlEscape(fdata[, j])
  }

  # TODO: if iAll is just 1:n, is it necessary to pass this vector to JSON, then
  # to R? When n is large, it may not be very efficient
  list(
    draw = as.integer(q$draw),
    recordsTotal = n,
    recordsFiltered = n,  # We're not filtering, so same as recordsTotal
    data = cleanDataFrame(fdata),  # fdata is the paged data
    DT_rows_all = iAll,
    DT_rows_current = iCurrent
  )
}

get_page_indices <- function(page_start, page_len, iAll) {
  len = as.integer(page_len)
  start <- as.integer(page_start)

  # Yihui: I don't know why this can happen, but see https://github.com/rstudio/DT/issues/164
  if (is.na(len)) {
    warning("The DataTables parameter 'length' is '", page_len, "' (invalid).")
    return(integer())
  }
  # page_len of -1 indicates no pagination. Return everything
  if (len == -1L) return(iAll)

  calc_page_indices(start, len, max_index = length(iAll))
}

#' Calculate page indices from start to len, but index must be <- max_index
#' Accounts for the data.table being zero-indexed, but R indexed from one
#' @param start integer for starting index (zero-based)
#' @param len integer length of a page
#' @return integer of indices (one-based)
calc_page_indices <- function(start, len, max_index) {
  i = seq(start + 1L, length.out = len)
  i = i[i <= max_index]
  i
}

get_total_rows <- function(con, tbl) {
  query <- glue_sql("SELECT COUNT (*) AS n FROM {`tbl`}", .con = con)
  cat(file = stderr(), query, "\n")
  result <- dbGetQuery(con, query)
  result$n
}

# Get the page of data given the current indices
# TODO: work out the interface - do we need indices or start/len to query DB?
get_page <- function(con, tbl, q) {
  # Translate dt query info into a sql query
  query <- glue_sql("SELECT * FROM {`tbl`}
                    LIMIT {q$length} OFFSET {q$start};", .con = con)
  cat(file = stderr(), query, "\n")
  dbGetQuery(con, query)
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
