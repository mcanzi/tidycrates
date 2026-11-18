test_that("dig_search returns releases, masters and artists", {
  local_dig_state(token = "abc")
  local_fixtures()
  out <- dig_search("Juniper Static")
  expect_named(out, c(
    "id", "type", "title", "year", "country", "label", "catno", "format", "barcode",
    "genres", "styles", "master_id", "have", "want", "uri"
  ))
  expect_equal(out$id, c(1001L, 2001L, 3001L))
  expect_equal(out$type, c("release", "master", "artist"))
  expect_equal(out$year, c(1994L, 1994L, NA))
  expect_equal(out$label, c("Fernhollow Records", "Fernhollow Records; Mossbank Tapes", NA))
  expect_equal(out$format[1], "Vinyl, 7\", 45 RPM, Single")
  expect_equal(out$barcode[1], "5000000000017; LC 00007")
  expect_equal(out$genres[[1]], c("Electronic", "Pop"))
  expect_equal(out$styles[[3]], character())
  expect_equal(out$master_id, c(2001L, NA, NA))
  expect_equal(out$have, c(120L, 70L, NA))
  expect_equal(out$uri[3], "https://www.discogs.com/artist/3001-Juniper-Static")
  expect_false(any(c("thumb", "cover_image") %in% names(out)))
})

test_that("dig_search sends the query, the filters given and the settings", {
  local_dig_state(token = "abc")
  query <- NULL
  httr2::local_mocked_responses(function(req) {
    query <<- httr2::url_parse(req$url)$query
    discogs_response(fixture("search-juniper"))
  })
  dig_search("lantern", type = "release", artist = "Juniper Static", year = 1994,
             sort = "year", order = "asc", page = 2, per_page = 10)
  expect_equal(
    query,
    list(q = "lantern", artist = "Juniper Static", year = "1994", type = "release",
         sort = "year", sort_order = "asc", page = "2", per_page = "10")
  )
})

test_that("dig_search works with filters only", {
  local_dig_state(token = "abc")
  query <- NULL
  httr2::local_mocked_responses(function(req) {
    query <<- httr2::url_parse(req$url)$query
    discogs_response(fixture("search-juniper"))
  })
  dig_search(catno = "FHR 007")
  expect_equal(query$catno, "FHR 007")
  expect_null(query$q)
  expect_null(query$type)
})

test_that("dig_search needs a token", {
  local_dig_state()
  expect_error(dig_search("lantern"), "personal access token")
})

test_that("dig_search checks its arguments", {
  local_dig_state(token = "abc")
  expect_error(dig_search(), "query")
  expect_error(dig_search("lantern", type = "track"), "must be one of")
  expect_error(dig_search("lantern", sort = "rating"), "must be one of")
  expect_error(dig_search(c("a", "b")), "single value")
  expect_error(dig_search(artist = ""), "artist")
  expect_error(dig_search("lantern", per_page = 101), "1 to 100")
})

test_that("search results are tallied by genre, label and format", {
  local_dig_state(token = "abc")
  local_fixtures()
  out <- dig_search("Juniper Static")
  expect_equal(dig_tally(out, "genre")$n, c(2L, 2L))
  expect_equal(dig_tally(out, "label")$label, c("Fernhollow Records", "Mossbank Tapes"))
  expect_equal(dig_tally(out, "format")$format, "Vinyl")
})

test_that("broken search results give NA instead of errors", {
  local_dig_state(token = "abc")
  httr2::local_mocked_responses(list(
    discogs_response(list(results = list(list(id = 1, year = "", label = list(), master_id = 0, uri = NULL)))),
    discogs_response(list(pagination = list(pages = 1), results = setNames(list(), character()))),
    discogs_response(list(results = "broken"))
  ))
  out <- dig_search("x")
  expect_equal(out$id, 1L)
  expect_true(is.na(out$year))
  expect_true(is.na(out$label))
  expect_true(is.na(out$master_id))
  expect_true(is.na(out$uri))
  expect_equal(out$genres, list(character()))
  empty <- dig_search("x")
  expect_equal(nrow(empty), 0)
  expect_null(names(empty$genres))
  expect_equal(nrow(dig_search("x")), 0)
})

test_that("plots of search results with artists or labels count results", {
  skip_if_not_installed("ggplot2")
  local_dig_state(token = "abc")
  local_fixtures()
  out <- dig_search("Juniper Static")
  labs <- ggplot2::get_labs(dig_plot(out, "genre"))
  expect_equal(labs$title, "Results by genre")
  expect_equal(labs$subtitle, "3 results. A result can have more than one genre.")
  releases <- ggplot2::get_labs(dig_plot(out[out$type == "release", ], "genre"))
  expect_equal(releases$title, "Releases by genre")
})
