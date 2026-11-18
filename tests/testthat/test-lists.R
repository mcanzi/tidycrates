test_that("dig_artist_releases returns releases and masters", {
  local_dig_state()
  local_fixtures()
  out <- dig_artist_releases(3001, per_page = 3)
  expect_equal(nrow(out), 3)
  expect_equal(out$type, c("release", "master", "master"))
  expect_equal(out$have[1], 43L)
  expect_equal(out$want[1], 160L)
  expect_false("thumb" %in% names(out))
})

test_that("dig_artist_releases sends sort and page settings", {
  local_dig_state()
  query <- NULL
  httr2::local_mocked_responses(function(req) {
    query <<- httr2::url_parse(req$url)$query
    discogs_response(fixture("artist-3001-releases"))
  })
  dig_artist_releases(1, sort = "title", order = "desc", page = 2, per_page = 10)
  expect_equal(query[c("sort", "sort_order", "page", "per_page")],
               list(sort = "title", sort_order = "desc", page = "2", per_page = "10"))
})

test_that("dig_label_releases returns releases with NA for year 0", {
  local_dig_state()
  local_fixtures()
  out <- dig_label_releases(4001)
  expect_equal(out$release_id, c(1001L, 1002L, 1003L))
  expect_true(is.na(out$year[3]))
})

test_that("dig_master_versions sends only the filters given", {
  local_dig_state()
  query <- NULL
  httr2::local_mocked_responses(function(req) {
    query <<- httr2::url_parse(req$url)$query
    discogs_response(fixture("master-2001-versions"))
  })
  out <- dig_master_versions(1000, country = "Germany")
  expect_equal(query$country, "Germany")
  expect_null(query$format)
  expect_equal(out$major_formats[1], "Cassette")
})

test_that("list functions check their arguments", {
  expect_error(dig_artist_releases(c(1, 2)), "single ID")
  expect_error(dig_artist_releases(1, sort = "label"), "must be one of")
  expect_error(dig_label_releases(1, per_page = 101), "1 to 100")
  expect_error(dig_label_releases(1, page = 0), "positive whole number")
  expect_error(dig_label_releases(1, all = NA), "TRUE")
})

test_that("filters must be single values", {
  expect_error(dig_master_versions(1000, format = c("CD", "Vinyl")), "single value")
  expect_error(dig_master_versions(1000, country = NA), "single value")
  expect_error(dig_label_releases(1, page = Inf), "positive whole number")
})

test_that("empty filters are rejected", {
  expect_error(dig_master_versions(1000, format = ""), "single value")
  expect_error(dig_master_versions(1000, format = "  "), "single value")
  expect_error(dig_master_versions(1000, released = Inf), "single value")
  expect_error(dig_master_versions(1000, released = NaN), "single value")
})
