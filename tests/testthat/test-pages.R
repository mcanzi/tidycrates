test_that("one page is returned by default", {
  local_dig_state()
  httr2::local_mocked_responses(page_response)
  out <- dig_get_pages("artists/1/releases", "releases", page = 2)
  expect_equal(purrr::map_int(out, "id"), c(20L, 21L))
})

test_that("all = TRUE fetches every page with 100 items each", {
  local_dig_state()
  seen <- integer()
  httr2::local_mocked_responses(function(req) {
    query <- httr2::url_parse(req$url)$query
    expect_equal(query$per_page, "100")
    seen <<- c(seen, as.integer(query$page))
    page_response(req)
  })
  out <- dig_get_pages("artists/1/releases", "releases", page = 2, all = TRUE)
  expect_equal(seen, 1:3)
  expect_equal(purrr::map_int(out, "id"), c(10L, 11L, 20L, 21L, 30L, 31L))
})

test_that("a failed page returns NULL", {
  local_dig_state()
  httr2::local_mocked_responses(function(req) {
    if (grepl("page=2", req$url)) {
      return(discogs_response(list(), status = 500L))
    }
    page_response(req)
  })
  expect_message(out <- dig_get_pages("artists/1/releases", "releases", all = TRUE))
  expect_null(out)
})

test_that("long fetches give the expected time", {
  local_dig_state()
  httr2::local_mocked_responses(\(req) page_response(req, pages = 80L))
  expect_message(
    out <- dig_get_pages("artists/1/releases", "releases", all = TRUE),
    "80 pages takes about 4 minutes"
  )
  expect_length(out, 160)
})

test_that("pages without items or pagination are handled", {
  local_dig_state()
  httr2::local_mocked_responses(list(discogs_response(list(releases = "broken"))))
  expect_equal(dig_get_pages("artists/1/releases", "releases", all = TRUE), list())
})

test_that("max_pages stops before fetching the other pages", {
  local_dig_state()
  calls <- 0L
  httr2::local_mocked_responses(function(req) {
    calls <<- calls + 1L
    page_response(req, pages = 101L)
  })
  expect_error(dig_get_pages("database/search", "releases", all = TRUE, max_pages = 100), "101 pages")
  expect_equal(calls, 1L)
  expect_length(dig_get_pages("database/search", "releases", page = 2, max_pages = 100), 2)
})
