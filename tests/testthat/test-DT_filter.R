test_that("get_page_indices edge cases", {

  # page_len -1 should return data and all indices
  iAll <- seq_len(nrow(mtcars))
  result <- get_page_indices(page_start = "0", page_len = "-1", iAll = iAll)
  expect_equal(result, iAll)

  # page_len NA should return emtpy df with no indices
  result <- suppressWarnings(
    get_page_indices(page_start = "0", page_len = "", iAll = iAll)
  )
  expect_equal(result, integer())

})

test_that("get_page_indices", {

  iAll <- seq_len(nrow(mtcars))

  # Get first page
  result <- get_page_indices(page_start = "0", page_len = "10", iAll = iAll)
  expect_equal(result, 1:10)

  # Get a page within the data
  result2 <- get_page_indices(page_start = "5", page_len = "5", iAll = iAll)
  # page_start = "5" corresponds to index 6 in R
  expect_equal(result2, 6:10)

  # Get a last page (with less than a page of rows)
  # mtcars has 32 rows
  result3 <- get_page_indices(page_start = "21", page_len = "20", iAll = iAll)
  expect_equal(result3, 22:32)

})

test_that("calc_page_indices", {

  result1 <- calc_page_indices(start = 0, len = 10, max_index = 100)
  expect_equal(result1, 1:10)

  # index should be truncated at max_index
  result2 <- calc_page_indices(start = 0, len = 10, max_index = 2)
  expect_equal(result2, 1:2)
})

