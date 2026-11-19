throttled_finish <- function(times, at, cap, n, latency) {
  start <- at
  for (i in seq_len(n)) {
    at <- at + tally_wait(times, at, cap)
    times <- c(times, at)
    at <- at + latency
  }
  at - start
}

test_that("the predicted finish matches the throttle", {
  cases <- list(
    list(times = numeric(), at = 0, n = 10, latency = 0.5),
    list(times = numeric(), at = 23, n = 92, latency = 0.33),
    list(times = seq(5, 50, length.out = 48), at = 63, n = 200, latency = 0.3),
    list(times = seq(65, 80, length.out = 46), at = 83, n = 46, latency = 0.33),
    list(times = rep(0, 59), at = 30, n = 70, latency = 0)
  )
  for (case in cases) {
    expect_equal(
      predict_finish(case$times, case$at, 58, case$n, case$latency),
      throttled_finish(case$times, case$at, 58, case$n, case$latency),
      tolerance = 1e-8
    )
  }
  expect_equal(predict_finish(numeric(), 0, 58, 0, 0.3), 0)
})

test_that("seconds are formatted for the progress bar", {
  expect_equal(format_seconds(0.2), "1s")
  expect_equal(format_seconds(38), "38s")
  expect_equal(format_seconds(75), "1m 15s")
  expect_equal(format_seconds(3725), "1h 2m")
})

test_that("waits during a progress bar count down in the bar", {
  clock <- local_dig_state(token = "abc")
  clock$time <- 30
  dig_env$requests_token <- rep(0, 59)
  statuses <- character()
  local_mocked_bindings(show_progress = \(bar, status) statuses <<- c(statuses, status))
  httr2::local_mocked_responses(\(req) discogs_response(list(id = 1L)))
  expect_no_message(map_requests(1:2, \(i) dig_get(paste0("releases/", i)), .progress = "Fetching"))
  expect_equal(statuses[1], "ETA: 33s, rate limit wait 32s")
  expect_match(statuses[32], "rate limit wait 1s", fixed = TRUE)
  expect_equal(sum(clock$pauses[1:32]), 30 + 60 * (1 - 58 / 59), tolerance = 1e-8)
  expect_null(dig_env$progress)
})

test_that("retries during a progress bar count down in the bar", {
  local_dig_state(token = "abc")
  statuses <- character()
  local_mocked_bindings(show_progress = \(bar, status) statuses <<- c(statuses, status))
  httr2::local_mocked_responses(list(
    discogs_response(list(message = "Too many requests."), status = 429L),
    discogs_response(list(id = 1L)),
    discogs_response(list(id = 2L))
  ))
  expect_no_message(map_requests(1:2, \(i) dig_get(paste0("releases/", i)), .progress = "Fetching"))
  expect_match(statuses[1], "HTTP 429, retry in 10s", fixed = TRUE)
  expect_match(statuses[10], "HTTP 429, retry in 1s", fixed = TRUE)
})
