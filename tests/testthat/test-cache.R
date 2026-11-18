test_that("cached responses are not requested again", {
  skip_if_not_installed("memoise")
  skip_if_not_installed("cachem")
  local_dig_state()
  withr::local_options(tidycrates.cache = TRUE)
  calls <- 0L
  httr2::local_mocked_responses(function(req) {
    calls <<- calls + 1L
    discogs_response(list(id = 1L))
  })
  dig_get("releases/1")
  dig_get("releases/1")
  dig_get("releases/1", cache = FALSE)
  expect_equal(calls, 2L)
})

test_that("errors are not cached", {
  skip_if_not_installed("memoise")
  skip_if_not_installed("cachem")
  local_dig_state()
  withr::local_options(tidycrates.cache = TRUE)
  responses <- list(discogs_response(list(), status = 500L), discogs_response(list(id = 1L)))
  httr2::local_mocked_responses(responses)
  expect_message(dig_get("releases/2"))
  expect_equal(dig_get("releases/2"), list(id = 1L))
})

test_that("the cache age is checked and capped at six hours", {
  local_dig_state()
  withr::local_options(tidycrates.cache_age = 1e6)
  expect_equal(cache_age(), 21600)
  withr::local_options(tidycrates.cache_age = -1)
  expect_error(cache_age(), "positive number")
  withr::local_options(tidycrates.cache_age = "1h")
  expect_error(cache_age(), "positive number")
})

test_that("changing the cache age starts a new cache", {
  skip_if_not_installed("memoise")
  skip_if_not_installed("cachem")
  local_dig_state()
  withr::local_options(tidycrates.cache = TRUE, tidycrates.cache_age = 100)
  calls <- 0L
  httr2::local_mocked_responses(function(req) {
    calls <<- calls + 1L
    discogs_response(list(id = 1L))
  })
  dig_get("releases/1")
  options(tidycrates.cache_age = 200)
  dig_get("releases/1")
  expect_equal(calls, 2L)
})
