test_that("make_sort_parameter", {
  params <- list(
    order = list(`0` = list(column = "0", dir = "asc"))
  )
  col_index <-  c("0" = "electionType", "1" = "label")
  result <- make_sort_parameter(params, col_index)
  expected <- "electionType"
  expect_equal(result, expected)
})

test_that("make_sort_parameter with multiple sorts", {
  params <- list(
    order = list(`0` = list(column = "0", dir = "asc"),
                 `1` = list(column = "2", dir = "desc"))
  )
  col_index <-  c("0" = "electionType", "1" = "label")
  result <- make_sort_parameter(params, col_index)
  # only first order parameter should be used
  expected <- "electionType"
  expect_equal(result, expected)
})

# Conversion of a single param$order term
test_that("to_sort_param", {
  col_index <- c("0" = "col_a", "1" = "col_b")
  order_term <- list(column = "1", dir = "asc")
  result <- to_sort_param(order_term, col_index)
  expect_equal(result, "col_b")
})

test_that("to_sort_param descending", {
  col_index <- c("0" = "col_a", "1" = "col_b")
  order_term <- list(column = "1", dir = "desc")
  result <- to_sort_param(order_term, col_index)
  expect_equal(result, "-col_b")
})
