test_that("requests carry the user agent, query and token", {
  local_dig_state()
  req <- dig_request("database/search", list(q = "Kaos", type = NULL), token = "abc")
  expect_equal(req$url, "https://api.discogs.com/database/search?q=Kaos")
  headers <- httr2::req_get_headers(req, "reveal")
  expect_equal(headers$Authorization, "Discogs token=abc")
  expect_equal(req$options$useragent, user_agent())
})

test_that("requests without a token send no authorization header", {
  local_dig_state()
  req <- dig_request("releases/1", token = NULL)
  expect_null(httr2::req_get_headers(req)$Authorization)
})

test_that("the throttle follows the rate limit for the token", {
  local_dig_state()
  expect_equal(dig_request("x", token = NULL)$policies$throttle_realm, "discogs")
  expect_equal(dig_request("x", token = "abc")$policies$throttle_realm, "discogs-token")
})

test_that("dig_get returns the parsed body", {
  local_dig_state()
  httr2::local_mocked_responses(list(discogs_response(list(id = 1L, title = "Kaos"))))
  expect_equal(dig_get("releases/1"), list(id = 1L, title = "Kaos"))
})

test_that("client errors stop with the message from Discogs", {
  local_dig_state()
  httr2::local_mocked_responses(list(
    discogs_response(list(message = "That release does not exist."), status = 404L)
  ))
  f <- function() dig_get("releases/0")
  err <- expect_error(f(), class = "tidycrates_http_error")
  expect_equal(err$status, 404L)
  expect_match(conditionMessage(err), "That release does not exist.")
  expect_equal(deparse(err$call), "f()")
})

test_that("server errors give a message and return NULL", {
  local_dig_state()
  httr2::local_mocked_responses(list(discogs_response(list(), status = 500L)))
  expect_message(out <- dig_get("releases/1"), "not available")
  expect_null(out)
})

test_that("connection failures give a message and return NULL", {
  local_dig_state()
  httr2::local_mocked_responses(function(req) {
    rlang::abort("Could not resolve host", class = "httr2_failure")
  })
  expect_message(out <- dig_get("releases/1"), "internet connection")
  expect_null(out)
})

test_that("requests are retried with a capped backoff", {
  local_dig_state()
  policies <- dig_request("releases/1", token = NULL)$policies
  expect_equal(policies$retry_max_tries, 4)
  expect_equal(retry_backoff(1), 10)
  expect_equal(sum(purrr::map_dbl(1:3, retry_backoff)), 70)
  expect_equal(retry_backoff(10), 60)
})

test_that("requests time out", {
  local_dig_state()
  expect_equal(dig_request("releases/1", token = NULL)$options$timeout_ms, 60000)
})

test_that("responses that are not JSON give a message and return NULL", {
  local_dig_state()
  httr2::local_mocked_responses(function(req) {
    httr2::response(200, headers = list(`Content-Type` = "text/html"), body = charToRaw("<html></html>"))
  })
  expect_message(out <- dig_get("releases/1"), "could not be read")
  expect_null(out)
})

test_that("server messages with braces or other types are shown as text", {
  local_dig_state()
  httr2::local_mocked_responses(list(
    discogs_response(list(message = "Bad {id} here"), status = 404L),
    discogs_response(list(message = list(a = 1)), status = 404L)
  ))
  err <- expect_error(dig_get("releases/1"), class = "tidycrates_http_error")
  expect_match(conditionMessage(err), "Bad {id} here", fixed = TRUE)
  expect_match(conditionMessage(err), "/releases/1", fixed = TRUE)
  err <- expect_error(dig_get("releases/1"), class = "tidycrates_http_error")
  expect_match(conditionMessage(err), "HTTP 404 Not Found.")
})

test_that("the offline message leaves out the internal cause", {
  local_dig_state()
  httr2::local_mocked_responses(function(req) {
    rlang::abort("Could not resolve host", class = "httr2_failure")
  })
  msg <- expect_message(dig_get("releases/1"), "internet connection")
  expect_no_match(conditionMessage(msg), "resolve host")
})
