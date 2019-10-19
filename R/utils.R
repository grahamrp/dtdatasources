
# Check if the columns are out of sync between params and data
cols_out_of_sync <- function(data, params) {
  length(params$columns) != ncol(data)
}

empty_payload <- function(n, draw) {
  list(
    draw = as.integer(draw),
    recordsTotal = n,
    recordsFiltered = 0,
    data = list(),
    DT_rows_all = seq_len(n),
    DT_rows_current = list()
  )
}
