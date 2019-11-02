
test_that("order_by_clause converts a DT order list to a sqlite ORDER BY statement", {
  q <- list(
    order =
      list(`0` = list(column = "0", dir = "asc"),
           `1` = list(column = "2", dir = "desc"))
  )
  result <- order_by_clause(q)
  expected <- "ORDER BY 1 asc, 3 desc"
  expect_equal(result, expected)

  # Case when no ordering specified
  q <- list()
  expect_equal(order_by_clause(q), "")
})



