#' DT Filter for UK Elections
#'
#' Example of REST API implementation of a DT filter for a UK Elections API
#'
#' Data is fetched from lda.data.parliament.uk/elections.json
#'
#' The API provides pagination and sorting, which are supported by this custom
#' DT filter.
#' @param data,params Standard parameters required for a funcFilter
#' @export
election_filter <- function(data, params) {

  # "data" parameter is unused, all data is got from the API

  # Make a colname to index lookup (indexed at zero)
  col_index <- names(data)
  names(col_index) <- as.character(seq_along(data) - 1)

  base_url <- "http://lda.data.parliament.uk/elections.json?_view=Elections"
  url <- make_query_url(base_url, params, col_index)
  message(paste("Requesting", url))
  req <- httr::GET(url)
  httr::stop_for_status(req)

  payload <- parse_response(req)
  format_payload(payload, draw = params$draw, escape = params$escape)
}

# Parse httr response object into payload suitable for DT
parse_response <- function(req) {
  txt <- httr::content(req, as = "text", encoding = "UTF-8")
  parsed <- jsonlite::fromJSON(txt)

  # Extract required data from response
  recordsTotal = parsed$result$totalResults

  data <- get_data_from_response(parsed)

  list(
    recordsTotal = recordsTotal,
    recordsFiltered = recordsTotal,  # Not implemented
    data = data,
    DT_rows_all = NULL,  # Not implemented
    DT_rows_current = data$about  # "about" field will be unique id for a row
  )
}


# Pick out the bits we want from the nested list
get_data_from_response <- function(parsed) {
  data.frame(
    electionType = parsed$result$items$electionType,
    date = parsed$result$items$date$`_value`,
    label = parsed$result$items$label$`_value`,
    about = parsed$result$items$`_about`,
    stringsAsFactors = FALSE
  )
}

# Make a full url to query the API, based on the data table parameters for
# page size/which page we're on, and any requested sort ordering.
make_query_url <- function(base_url, params, col_index) {
  query <- list(
    `_pageSize` = params$length,
    # API wants "page" number but params only provides page size and start index
    `_page` = as.integer(params$start) / as.integer(params$length),
    `_sort` = make_sort_parameter(params, col_index)
  )

  httr::modify_url(base_url, query = query)
}

# Convert params$order into a sort term suitable for the API
make_sort_parameter <- function(params, col_index) {
  default_sort <- "-date"
  if (is.null(params$order)) return(default_sort)
  # The api only supports sorting by 1 field
  order_term <- purrr::pluck(params$order, 1)
  sort_param <- to_sort_param(order_term, col_index)

  # Can only sort by following 3 fields
  if (grepl("electionType|date|label", sort_param)) sort_param else default_sort
}

# Given a single params$order element, turn it into a sort string for the API
to_sort_param <- function(order_term, col_index) {
  # Lookup the column name from the index
  col_name <- unname(col_index[order_term$column])
  direction <- if(order_term$dir == "desc") "-" else ""
  paste0(direction, col_name)
}

# Create an empty dataframe matching the expected table structure from
# election_filter. Used to initialise a DT.
empty_election_df <- function() {
  data.frame(
    electionType = character(),
    date = character(),
    label = character(),
    about = character(),
    stringsAsFactors = FALSE
  )
}
