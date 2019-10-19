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
  n = nrow(data)
  q = params
  ci = q$search[['caseInsensitive']] == 'true'
  # users may be updating the table too frequently
  if (length(q$columns) != ncol(data)) return(list(
    draw = as.integer(q$draw),
    recordsTotal = n,
    recordsFiltered = 0,
    data = list(),
    DT_rows_all = seq_len(n),
    DT_rows_current = list()
  ))

  # global searching
  # for some reason, q$search might be NULL, leading to error `if (logical(0))`
  if (length(v <- q$search[['value']]) > 0) {
    if (!identical(q$search[['smart']], 'false')) {
      v = unlist(strsplit(gsub('^\\s+|\\s+$', '', v), '\\s+'))
    }
  }
  if (length(v) == 0) v = ''
  m = if ((nv <- length(v)) > 1) array(FALSE, c(dim(data), nv)) else logical(n)
  # TODO: this searching method may not be efficient and need optimization
  i = if (!identical(v, '')) {
    for (j in seq_len(ncol(data))) {
      if (q$columns[[j]][['searchable']] != 'true') next
      for (k in seq_len(nv)) {
        i0 = grep2(
          v[k], as.character(data[, j]), fixed = q$search[['regex']] == 'false',
          ignore.case = ci
        )
        if (nv > 1) m[i0, j, k] = TRUE else m[i0] = TRUE
      }
    }
    which(if (nv > 1) apply(m, 1, function(z) all(colSums(z) > 0)) else m)
  } else seq_len(n)

  # search by columns
  if (length(i)) for (j in names(q$columns)) {
    col = q$columns[[j]]
    # if the j-th column is not searchable or the search string is "", skip it
    if (col[['searchable']] != 'true') next
    if ((k <- col[['search']][['value']]) == '') next
    j = as.integer(j)
    dj = data[, j + 1]
    ij = if (is.numeric(dj) || is.Date(dj)) {
      which(filterRange(dj, k))
    } else if (is.factor(dj)) {
      which(dj %in% fromJSON(k))
    } else if (is.logical(dj)) {
      which(dj %in% as.logical(fromJSON(k)))
    } else {
      grep2(k, as.character(dj), fixed = col[['search']][['regex']] == 'false',
            ignore.case = ci)
    }
    i = intersect(ij, i)
    if (length(i) == 0) break
  }
  if (length(i) != n) data = data[i, , drop = FALSE]
  iAll = i  # row indices of filtered data

  # sorting
  oList = list()
  for (ord in q$order) {
    k = ord[['column']]  # which column to sort
    d = ord[['dir']]     # direction asc/desc
    if (q$columns[[k]][['orderable']] != 'true') next
    col = data[, as.integer(k) + 1]
    oList[[length(oList) + 1]] = (if (d == 'asc') identity else `-`)(
      if (is.numeric(col)) col else xtfrm(col)
    )
  }
  if (length(oList)) {
    i = do.call(order, oList)
    data = data[i, , drop = FALSE]
    iAll = iAll[i]
  }
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
    recordsFiltered = nrow(data),
    data = cleanDataFrame(fdata),
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

