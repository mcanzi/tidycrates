test_that("dig_price_stats returns prices and copies for sale", {
  local_dig_state()
  local_fixtures()
  out <- dig_price_stats(c(1001, "[r1002]", "r1003"))
  expect_named(out, c("release_id", "lowest_price", "currency", "for_sale", "blocked"))
  expect_equal(out$release_id, c(1001L, 1002L, 1003L))
  expect_equal(out$lowest_price, c(4.5, NA, NA))
  expect_equal(out$currency, c("EUR", NA, NA))
  expect_equal(out$for_sale, c(12L, 0L, NA))
  expect_equal(out$blocked, c(FALSE, FALSE, TRUE))
})

test_that("dig_price_stats keeps the order of repeated IDs and fetches them once", {
  local_dig_state()
  calls <- 0L
  httr2::local_mocked_responses(function(req) {
    calls <<- calls + 1L
    discogs_response(fixture("price-stats-1001"))
  })
  out <- dig_price_stats(c(1001, 1001))
  expect_equal(calls, 1L)
  expect_equal(nrow(out), 2)
})

test_that("dig_price_stats sends the currency only when given", {
  local_dig_state()
  query <- NULL
  httr2::local_mocked_responses(function(req) {
    query <<- httr2::url_parse(req$url)$query
    discogs_response(fixture("price-stats-1001"))
  })
  dig_price_stats(1001, currency = " eur ")
  expect_equal(query$curr_abbr, "EUR")
  dig_price_stats(1001)
  expect_null(query$curr_abbr)
})

test_that("dig_price_stats checks its arguments", {
  expect_error(dig_price_stats(1001, currency = "EURO"), "must be one of")
  expect_error(dig_price_stats(1001, currency = c("EUR", "USD")), "must be one of")
  expect_error(dig_price_stats(1001, currency = NA), "must be one of")
  expect_error(dig_price_stats(1001, currency = 1), "must be one of")
  expect_error(dig_price_stats("[m2001]"), "is a master release code")
  expect_error(dig_price_stats(numeric()), "positive whole numbers")
  expect_error(dig_price_stats(-1), "positive whole numbers")
})

test_that("broken statistics give NA instead of errors", {
  out <- parse_price_stats(list(lowest_price = "broken", num_for_sale = "many", blocked_from_sale = "maybe"), 1L)
  expect_equal(nrow(out), 1)
  expect_true(is.na(out$lowest_price))
  expect_true(is.na(out$currency))
  expect_true(is.na(out$for_sale))
  expect_true(is.na(out$blocked))
  expect_equal(nrow(parse_price_stats("broken", 2L)), 1)
  expect_equal(parse_price_stats(list(), 3L)$release_id, 3L)
})

test_that("dig_price_suggestions returns one row per condition from best to worst", {
  local_dig_state(token = "abc")
  local_fixtures()
  out <- dig_price_suggestions(1001)
  expect_named(out, c("release_id", "condition", "price", "currency"))
  expect_equal(as.character(out$condition), conditions)
  expect_s3_class(out$condition, "factor")
  expect_equal(out$price[1:2], c(14.32, 12.81))
  expect_true(all(out$currency == "EUR"))
})

test_that("releases without suggestions have no rows", {
  local_dig_state(token = "abc")
  local_fixtures()
  expect_equal(nrow(dig_price_suggestions(1002)), 0)
  out <- dig_price_suggestions(c(1002, 1001))
  expect_equal(nrow(out), 8)
  expect_true(all(out$release_id == 1001L))
  expect_named(dig_price_suggestions(1002), c("release_id", "condition", "price", "currency"))
})

test_that("unknown conditions and broken suggestions are handled", {
  out <- parse_price_suggestions(
    list(
      `Mint (M)` = list(currency = "EUR", value = "a lot"),
      `Sealed` = list(currency = "EUR", value = 20),
      `Poor (P)` = "broken",
      list(currency = "EUR", value = 1)
    ),
    1L
  )
  expect_equal(as.character(out$condition), c("Mint (M)", "Sealed"))
  expect_true(is.na(out$price[1]))
  expect_equal(out$price[2], 20)
  expect_equal(nrow(parse_price_suggestions("broken", 1L)), 0)
  expect_equal(nrow(parse_price_suggestions(list(1, 2), 1L)), 0)
})

test_that("price suggestions and collection values need a token", {
  local_dig_state()
  expect_error(dig_price_suggestions(1001), "personal access token")
  expect_error(dig_collection_value("example"), "personal access token")
  expect_error(dig_collection_value(), "personal access token")
})

test_that("dig_collection_value turns formatted values into numbers", {
  local_dig_state(token = "abc")
  httr2::local_mocked_responses(function(req) raw_response("collection-value-example"))
  out <- dig_collection_value(" example ")
  expect_named(out, c("username", "minimum", "median", "maximum", "currency"))
  expect_equal(out$username, "example")
  expect_equal(c(out$minimum, out$median, out$maximum), c(75.5, 480.25, 1250))
  expect_equal(out$currency, "€")
})

test_that("dig_collection_value handles broken bodies and checks the username", {
  local_dig_state(token = "abc")
  httr2::local_mocked_responses(function(req) discogs_response(list(minimum = "n/a", median = list(), maximum = 5)))
  out <- dig_collection_value("example")
  expect_true(is.na(out$minimum))
  expect_true(is.na(out$median))
  expect_equal(out$maximum, 5)
  expect_true(is.na(out$currency))
  expect_error(dig_collection_value(""), "single username")
  expect_error(dig_collection_value(c("a", "b")), "single username")
  expect_error(dig_collection_value(NA_character_), "single username")
})

test_that("values in many formats are read", {
  money <- parse_money(c(
    "$250.00", "€1.234,56", "1 234,56 kr", "¥12,345", "CA$1,000.50", "", NA, "N/A",
    "$0.00", "CHF 1’234.50", "$12.5", "1 234,5 €"
  ))
  expect_equal(money$value, c(250, 1234.56, 1234.56, 12345, 1000.5, NA, NA, NA, 0, 1234.5, 12.5, 1234.5))
  expect_equal(
    money$currency,
    c("$", "€", "kr", "¥", "CA$", NA, NA, NA, "$", "CHF", "$", "€")
  )
})

test_that("an owner check from Discogs stops with its message", {
  local_dig_state(token = "abc")
  httr2::local_mocked_responses(function(req) {
    discogs_response(list(message = "You don't have permission to access this resource."), status = 403L)
  })
  expect_error(dig_collection_value("someone"), "permission", class = "tidycrates_http_error")
  expect_error(dig_price_suggestions(1001), "permission", class = "tidycrates_http_error")
})

test_that("marketplace data are never cached", {
  skip_if_not_installed("memoise")
  skip_if_not_installed("cachem")
  local_dig_state(token = "abc")
  withr::local_options(tidycrates.cache = TRUE)
  calls <- 0L
  httr2::local_mocked_responses(function(req) {
    calls <<- calls + 1L
    discogs_response(fixture("price-stats-1001"))
  })
  dig_price_stats(1001)
  dig_price_stats(1001)
  expect_equal(calls, 2L)
})

test_that("marketplace functions return NULL when the API cannot be reached", {
  local_dig_state(token = "abc")
  httr2::local_mocked_responses(function(req) discogs_response(list(), status = 503L))
  local_mocked_bindings(retry_backoff = \(attempt) 0)
  expect_message(out <- dig_price_stats(1001))
  expect_null(out)
  expect_message(out <- dig_price_suggestions(1001))
  expect_null(out)
  expect_message(out <- dig_collection_value("example"))
  expect_null(out)
})

test_that("negative values keep their sign", {
  money <- parse_money(c("-$5.00", "$-5.00", "−€1.250,00", "-", "$1,250.00"))
  expect_equal(money$value, c(-5, -5, -1250, NA, 1250))
  expect_equal(money$currency, c("$", "$", "€", NA, "$"))
})

test_that("dig_collection_value reads the value of the token owner", {
  local_dig_state(token = "abc")
  local_fixtures()
  out <- dig_collection_value()
  expect_equal(out$username, "example")
  expect_equal(out$maximum, 1250)
})
