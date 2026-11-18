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

test_that("requests are sent at once while the window has room", {
  clock <- local_dig_state()
  httr2::local_mocked_responses(function(req) discogs_response(list(id = 1L)))
  for (i in 1:24) dig_get("releases/1")
  expect_equal(clock$time, 0)
  expect_message(dig_get("releases/1"), "Waiting 60 seconds for the 'Discogs' rate limit.", fixed = TRUE)
  expect_equal(clock$time, 60)
})

test_that("waits under a second give no message", {
  clock <- local_dig_state()
  httr2::local_mocked_responses(function(req) {
    clock$time <- clock$time + 2.6
    discogs_response(list(id = 1L))
  })
  for (i in 1:24) dig_get("releases/1")
  expect_no_message(dig_get("releases/1"))
  expect_equal(clock$pauses, 0.2, tolerance = 1e-8)
})

test_that("the window holds 59 requests with a token and 24 without", {
  expect_equal(window_size(NULL), 24)
  expect_equal(window_size("abc"), 59)
})

test_that("no 60 seconds hold more requests than the window", {
  clock <- local_dig_state(token = "abc")
  sent <- numeric()
  httr2::local_mocked_responses(function(req) {
    sent <<- c(sent, clock$time)
    clock$time <- clock$time + 0.3
    discogs_response(list(id = 1L))
  })
  msgs <- testthat::capture_messages(for (i in 1:150) dig_get("releases/1"))
  expect_length(msgs, 2)
  busiest <- max(purrr::map_int(sent, \(t) sum(sent >= t & sent < t + 60)))
  expect_lte(busiest, 59)
  expect_lt(max(sent), 130)
})

test_that("the windows with and without a token are kept apart", {
  clock <- local_dig_state()
  httr2::local_mocked_responses(function(req) discogs_response(list(id = 1L)))
  for (i in 1:24) dig_get("releases/1")
  dig_env$token <- "abc"
  for (i in 1:59) dig_get("releases/1")
  expect_equal(clock$time, 0)
})

test_that("a rate limit that is still exceeded gives a message and returns NULL", {
  local_dig_state()
  httr2::local_mocked_responses(function(req) discogs_response(list(message = "Too many requests."), status = 429L))
  local_mocked_bindings(retry_backoff = \(attempt) 0)
  expect_message(out <- dig_get("releases/1"), "rate limit")
  expect_null(out)
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
  clock <- local_dig_state()
  tries <- 0
  httr2::local_mocked_responses(function(req) {
    tries <<- tries + 1
    discogs_response(list(), status = 503L)
  })
  msgs <- testthat::capture_messages(dig_get("releases/1"))
  expect_match(msgs[1:3], "Retrying in (10|20|40) seconds after HTTP 503.")
  expect_match(msgs[4], "not available")
  expect_equal(tries, 4)
  expect_equal(clock$pauses, c(10, 20, 40))
  expect_equal(retry_backoff(1), 10)
  expect_equal(sum(purrr::map_dbl(1:3, retry_backoff)), 70)
  expect_equal(retry_backoff(10), 60)
})

test_that("retries wait as long as Retry-After asks and count towards the window", {
  clock <- local_dig_state()
  responses <- list(
    httr2::response(429L, headers = list(`Retry-After` = "7")),
    discogs_response(list(id = 1L))
  )
  httr2::local_mocked_responses(responses)
  expect_message(out <- dig_get("releases/1"), "Retrying in 7 seconds after HTTP 429.", fixed = TRUE)
  expect_equal(out, list(id = 1L))
  expect_equal(clock$pauses, 7)
  expect_length(recent_requests(NULL), 2)
})

test_that("client errors other than 429 are not retried", {
  local_dig_state()
  tries <- 0
  httr2::local_mocked_responses(function(req) {
    tries <<- tries + 1
    discogs_response(list(message = "Not found."), status = 404L)
  })
  expect_error(dig_get("releases/1"), class = "tidycrates_http_error")
  expect_equal(tries, 1)
})

test_that("failed connections count towards the window", {
  local_dig_state()
  httr2::local_mocked_responses(function(req) {
    rlang::abort("Could not resolve host", class = "httr2_failure")
  })
  expect_message(dig_get("releases/1"))
  expect_length(recent_requests(NULL), 1)
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

test_that("a body of null is read as an empty record", {
  local_dig_state()
  httr2::local_mocked_responses(list(
    httr2::response(200L, headers = list(`Content-Type` = "application/json"), body = charToRaw("null"))
  ))
  out <- dig_release(1)
  expect_equal(nrow(out), 1)
  expect_true(is.na(out$release_id))
})

test_that("errors for one of several IDs are not wrapped in an index", {
  local_dig_state()
  httr2::local_mocked_responses(function(req) {
    if (stringr::str_ends(req$url, "/2")) {
      return(discogs_response(list(message = "Release not found."), status = 404L))
    }
    discogs_response(fixture("release-1001"))
  })
  err <- expect_error(dig_release(c(1, 2)), class = "tidycrates_http_error")
  expect_false(inherits(err, "purrr_error_indexed"))
  expect_match(conditionMessage(err), "/releases/2")
  expect_equal(deparse(err$call), "dig_release(c(1, 2))")
})
