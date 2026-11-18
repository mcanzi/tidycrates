test_that("dig_rate_limit reports the headers of the response", {
  local_dig_state(token = "abc")
  httr2::local_mocked_responses(list(
    discogs_response(list(hello = "Welcome"), used = 3L, limit = 60L)
  ))
  out <- dig_rate_limit()
  expect_equal(
    out,
    tibble::tibble(limit = 60L, used = 3L, remaining = 57L, authenticated = TRUE)
  )
})

test_that("dig_rate_limit returns NULL when the API cannot be reached", {
  local_dig_state()
  httr2::local_mocked_responses(list(discogs_response(list(), status = 502L)))
  expect_message(out <- dig_rate_limit())
  expect_null(out)
})

test_that("dig_rate_limit does not return old values", {
  local_dig_state()
  dig_env$rate_limit <- tibble::tibble(limit = 25L, used = 1L, remaining = 24L, authenticated = FALSE)
  httr2::local_mocked_responses(list(httr2::response_json(body = list(hello = "Welcome"))))
  expect_null(dig_rate_limit())
})

test_that("missing rate limit headers give NA", {
  local_dig_state()
  httr2::local_mocked_responses(list(
    httr2::response_json(headers = list(`X-Discogs-Ratelimit` = "25"), body = list())
  ))
  out <- dig_rate_limit()
  expect_equal(out$limit, 25L)
  expect_true(is.na(out$used))
})
