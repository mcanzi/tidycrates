test_that("dig_release returns one row with nested tibbles", {
  local_dig_state()
  local_fixtures()
  out <- dig_release(1001)
  expect_s3_class(out, "tbl_df")
  expect_equal(nrow(out), 1)
  expect_equal(out$release_id, 1001L)
  expect_equal(out$title, "Lantern Weather")
  expect_equal(out$artist, "Juniper Static")
  expect_equal(out$year, 1994L)
  expect_equal(out$label, "Fernhollow Records")
  expect_equal(out$genres[[1]], c("Electronic", "Pop"))
  expect_s3_class(out$date_added, "POSIXct")
  expect_equal(format(out$date_added, "%Y-%m-%d %H:%M"), "2004-04-30 15:10")
  expect_s3_class(out$tracklist[[1]], "tbl_df")
  expect_false(any(c("images", "thumb", "lowest_price", "num_for_sale") %in% names(out)))
})

test_that("dig_release fetches several releases", {
  local_dig_state()
  local_fixtures()
  out <- dig_release(c(1001, 1001))
  expect_equal(nrow(out), 2)
})

test_that("dig_release stops on unknown releases and invalid IDs", {
  local_dig_state()
  local_fixtures()
  expect_error(dig_release(1), class = "tidycrates_http_error")
  expect_error(dig_release("abc"), "positive whole numbers")
  expect_error(dig_release(-1), "positive whole numbers")
  expect_error(dig_release(numeric()), "positive whole numbers")
})

test_that("dig_release returns NULL when the API cannot be reached", {
  local_dig_state()
  httr2::local_mocked_responses(list(discogs_response(list(), status = 503L)))
  local_mocked_bindings(retry_backoff = \(attempt) 0)
  expect_message(out <- dig_release(1001))
  expect_null(out)
})

test_that("dig_master returns the master release", {
  local_dig_state()
  local_fixtures()
  out <- dig_master(2001)
  expect_equal(out$master_id, 2001L)
  expect_equal(out$title, "Lantern Weather")
  expect_equal(out$main_release, 1001L)
  expect_equal(nrow(out$tracklist[[1]]), 2)
})

test_that("dig_artist returns the artist", {
  local_dig_state()
  local_fixtures()
  out <- dig_artist(3001)
  expect_equal(out$name, "Juniper Static")
  expect_equal(out$real_name, "Malin Ödegaard")
  expect_equal(nrow(out$aliases[[1]]), 7)
  expect_equal(nrow(out$members[[1]]), 0)
  expect_named(out$members[[1]], c("artist_id", "name", "active"))
})

test_that("dig_label returns the label", {
  local_dig_state()
  local_fixtures()
  out <- dig_label(4001)
  expect_equal(out$name, "Fernhollow Records")
  expect_true(is.na(out$parent_label))
  expect_equal(nrow(out$sublabels[[1]]), 8)
})

test_that("IDs are checked", {
  expect_error(dig_release(TRUE), "positive whole numbers")
  expect_error(dig_release(factor("5")), "positive whole numbers")
  expect_error(dig_release(Inf), "positive whole numbers")
  expect_error(dig_release(1.5), "positive whole numbers")
  expect_error(dig_release(c(1, NA)), "positive whole numbers")
  expect_error(dig_release(3e9), "positive whole numbers")
  expect_equal(check_ids(c(" 12 ", "1000"), "r"), c("12", "1000"))
  expect_error(dig_release("0x1A"), "positive whole numbers")
  expect_error(dig_release("1e3"), "positive whole numbers")
})

test_that("codes copied from Discogs are accepted", {
  expect_equal(check_ids(c("[a514141]", "a514141", "514141", " [A514141] "), "a"), rep("514141", 4))
  expect_equal(check_ids(514141, "a"), "514141")
  expect_error(dig_release("[m1443368]"), "is a master release code")
  expect_error(dig_release("[m1443368]"), "dig_master")
  expect_error(dig_artist(c("1", "L5")), "is a label code")
  expect_error(dig_release("a1"), "is an artist code")
  expect_error(dig_master_versions("r1"), "must contain master release IDs")
  expect_error(dig_artist("[a514141"), "positive whole numbers")
  expect_error(dig_artist("[514141]"), "positive whole numbers")
  expect_error(dig_artist("aa514141"), "positive whole numbers")
  expect_error(dig_release("[r]"), "positive whole numbers")
})

test_that("repeated IDs are fetched once and keep their order", {
  local_dig_state()
  calls <- 0L
  httr2::local_mocked_responses(function(req) {
    calls <<- calls + 1L
    id <- as.integer(basename(req$url))
    discogs_response(list(id = id, title = paste("Release", id)))
  })
  out <- dig_release(c(2, 1, 2))
  expect_equal(calls, 2L)
  expect_equal(out$release_id, c(2L, 1L, 2L))
})

test_that("broken or missing fields give NA instead of errors", {
  out <- parse_release(list(
    title = list("a", "b"),
    year = "unknown",
    community = "broken",
    labels = list("broken", list(name = "Fernhollow", catno = "")),
    tracklist = list(list(position = "A", title = "Song", artists = "broken")),
    genres = list("Pop", NULL, ""),
    date_added = "2004-04-30T08:10:05Z"
  ))
  expect_equal(nrow(out), 1)
  expect_true(is.na(out$release_id))
  expect_equal(out$title, "a, b")
  expect_true(is.na(out$year))
  expect_true(is.na(out$have))
  expect_equal(out$label, "Fernhollow")
  expect_true(is.na(out$catno))
  expect_equal(out$genres[[1]], "Pop")
  expect_equal(format(out$date_added, "%H:%M"), "08:10")
  expect_equal(out$tracklist[[1]]$title, "Song")
  expect_true(is.na(out$tracklist[[1]]$artist))
})

test_that("an empty body gives one row of NA", {
  for (parse in list(parse_release, parse_master, parse_artist, parse_label)) {
    out <- parse(list())
    expect_equal(nrow(out), 1)
  }
})

test_that("artist names join correctly and skip missing names", {
  artists <- list(
    list(name = "A (2)", anv = "A", join = ","),
    list(name = "B", join = "Feat."),
    list(join = "&"),
    list(name = "C", join = "")
  )
  expect_equal(artist_names(artists), "A, B Feat. C")
  expect_equal(artist_names(list(list(name = "A"), list(name = "B"))), "A B")
  expect_true(is.na(artist_names(list())))
})
