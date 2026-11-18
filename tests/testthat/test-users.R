test_that("dig_collection returns one row per copy", {
  local_dig_state()
  local_fixtures()
  out <- dig_collection("example", per_page = 3)
  expect_equal(out$release_id, c(1001L, 1001L, 1002L))
  expect_equal(out$instance_id, c(101L, 102L, 103L))
  expect_equal(names(out)[1:3], c("release_id", "instance_id", "folder_id"))
  expect_equal(out$artist[1], "Juniper Static")
  expect_equal(out$format[1], "Vinyl")
  expect_equal(out$label[3], "Fernhollow Records")
  expect_equal(out$genres[[1]], c("Electronic", "Pop"))
  expect_equal(out$styles[[3]], character())
  expect_equal(out$rating, c(4L, NA, 5L))
  expect_equal(out$master_id, c(2001L, 2001L, NA))
  expect_true(is.na(out$year[3]))
  expect_s3_class(out$date_added, "POSIXct")
  expect_false("notes" %in% names(out))
})

test_that("dig_collection sends folder, sort and page settings", {
  local_dig_state()
  url <- NULL
  httr2::local_mocked_responses(function(req) {
    url <<- httr2::url_parse(req$url)
    discogs_response(fixture("collection-example"))
  })
  dig_collection(" some.user ", folder = 3, sort = "year", order = "desc", page = 2, per_page = 10)
  expect_equal(url$path, "/users/some.user/collection/folders/3/releases")
  expect_equal(url$query[c("sort", "sort_order", "page", "per_page")],
               list(sort = "year", sort_order = "desc", page = "2", per_page = "10"))
})

test_that("dig_wantlist returns releases with notes", {
  local_dig_state()
  local_fixtures()
  out <- dig_wantlist("example")
  expect_equal(out$release_id, c(1003L, 1002L))
  expect_equal(out$notes, c("Only the first pressing.", NA))
  expect_equal(out$rating, c(NA, 3L))
  expect_equal(out$styles[[1]], c("Downtempo", "Electro"))
  expect_equal(names(out)[ncol(out)], "notes")
})

test_that("collections and wantlists are not cached", {
  local_dig_state()
  withr::local_options(tidycrates.cache = TRUE)
  dig_env$cached_fetch <- NULL
  calls <- 0L
  httr2::local_mocked_responses(function(req) {
    calls <<- calls + 1L
    discogs_response(fixture("wantlist-example"))
  })
  dig_wantlist("example")
  dig_wantlist("example")
  expect_equal(calls, 2L)
})

test_that("private collections stop with the API message", {
  local_dig_state()
  httr2::local_mocked_responses(function(req) {
    discogs_response(
      list(message = "You are not allowed to view this resource. Please authenticate as the owner to view this content."),
      status = 403L
    )
  })
  expect_error(dig_collection("someone"), "authenticate as the owner", class = "tidycrates_http_error")
})

test_that("user functions check their arguments", {
  expect_error(dig_collection(""), "single username")
  expect_error(dig_collection(c("a", "b")), "single username")
  expect_error(dig_wantlist(NA_character_), "single username")
  expect_error(dig_wantlist(1), "single username")
  expect_error(dig_collection("a", folder = -1), "from 0")
  expect_error(dig_collection("a", folder = 1.5), "from 0")
  expect_error(dig_wantlist("a", sort = "released"), "must be one of")
  expect_error(dig_wantlist("a", per_page = 101), "1 to 100")
})
