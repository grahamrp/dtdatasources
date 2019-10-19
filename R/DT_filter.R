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
  n = nrow(data)
  q = params

  # users may be updating the table too frequently
  if (cols_out_of_sync(data, params)) return(empty_payload(n, params$draw))

  i <- seq_len(n)  # i is created as part of filtering above, which we're ignoring for now
  iAll = i  # row indices of filtered data

  # paging
  if (q$length != '-1') {
    len = as.integer(q$length)
    # I don't know why this can happen, but see https://github.com/rstudio/DT/issues/164
    if (is.na(len)) {
      warning("The DataTables parameter 'length' is '", q$length, "' (invalid).")
      len = 0
    }
    i = seq(as.integer(q$start) + 1L, length.out = len)
    i = i[i <= nrow(data)]
    fdata = data[i, , drop = FALSE]  # filtered data
    iCurrent = iAll[i]
  } else {
    fdata = data
    iCurrent = iAll
  }

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
    recordsFiltered = n,
    data = cleanDataFrame(fdata),  # fdata is the paged data
    DT_rows_all = iAll,
    DT_rows_current = iCurrent
  )
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

# when both ignore.case and fixed are TRUE, we use grep(ignore.case = FALSE,
# fixed = TRUE) to do lower-case matching of pattern on x; assume value = FALSE
grep2 = function(pattern, x, ignore.case = FALSE, fixed = FALSE, ...) {
  if (fixed && ignore.case) {
    pattern = tolower(pattern)
    x = tolower(x)
    ignore.case = FALSE
  }
  # when the user types in the search box, the regular expression may not be
  # complete before it is sent to the server, in which case we do not search
  if (!fixed && inherits(try(grep(pattern, ''), silent = TRUE), 'try-error'))
    return(seq_along(x))
  grep(pattern, x, ignore.case = ignore.case, fixed = fixed, ...)
}

# filter a numeric/date/time vector using the search string "lower ... upper"
filterRange = function(d, string) {
  if (!grepl('[.]{3}', string) || length(r <- strsplit(string, '[.]{3}')[[1]]) > 2)
    stop('The range of a numeric / date / time column must be of length 2')
  if (length(r) == 1) r = c(r, '')  # lower,
  r = gsub('^\\s+|\\s+$', '', r)
  r1 = r[1]; r2 = r[2]
  if (is.numeric(d)) {
    r1 = as.numeric(r1); r2 = as.numeric(r2)
  } else if (inherits(d, 'Date')) {
    if (r1 != '') r1 = as.Date(r1)
    if (r2 != '') r2 = as.Date(r2)
  } else {
    if (r1 != '') r1 = as.POSIXct(r1, tz = 'GMT', '%Y-%m-%dT%H:%M:%S')
    if (r2 != '') r2 = as.POSIXct(r2, tz = 'GMT', '%Y-%m-%dT%H:%M:%S')
  }
  if (r[1] == '') return(d <= r2)
  if (r[2] == '') return(d >= r1)
  d >= r1 & d <= r2
}

