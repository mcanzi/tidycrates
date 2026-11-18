test_that("the helpers unnest a release", {
  local_dig_state()
  local_fixtures()
  release <- dig_release(1001)
  tracks <- dig_tracklist(release)
  expect_equal(tracks$position, c("A", "B"))
  expect_equal(tracks$seconds, c(212L, 210L))
  expect_equal(names(tracks)[1], "release_id")
  credits <- dig_credits(release)
  expect_equal(nrow(credits), 6)
  expect_equal(credits$credited_as[credits$name == "Paperweight Design"], "Paperweight")
  formats <- dig_formats(release)
  expect_equal(formats$descriptions, "7\", 45 RPM, Single, Stereo")
  identifiers <- dig_identifiers(release)
  expect_equal(identifiers$value[identifiers$type == "Barcode"][1], "5000000000017")
  companies <- dig_companies(release)
  expect_named(companies, c("release_id", "name", "role", "catno", "label_id"))
  expect_equal(companies$role[1:2], c("Label", "Phonographic Copyright (p)"))
  expect_equal(companies$catno[1], "FHR 007")
  expect_equal(nrow(companies), 7)
})

test_that("the helpers accept release IDs", {
  local_dig_state()
  local_fixtures()
  expect_equal(nrow(dig_tracklist(1001)), 2)
})

test_that("dig_tracklist accepts master releases", {
  local_dig_state()
  local_fixtures()
  tracks <- dig_tracklist(dig_master(2001))
  expect_equal(names(tracks)[1], "master_id")
  expect_equal(nrow(tracks), 2)
})

test_that("the helpers reject other input", {
  expect_error(dig_credits(tibble::tibble(master_id = 1L, tracklist = list(tibble::tibble()))), "output of")
  expect_error(dig_formats(data.frame(a = 1)), "output of")
})

test_that("index tracks, track artists and track credits are kept", {
  body <- list(
    tracklist = list(
      list(
        position = "", type_ = "index", title = "Suite",
        sub_tracks = list(
          list(position = "1a", type_ = "track", title = "Part 1", duration = "1:02:03"),
          list(position = "1b", type_ = "track", title = "Part 2", duration = "")
        )
      ),
      list(
        position = "2", type_ = "track", title = "Duet", duration = "4:00",
        artists = list(list(name = "A", join = "&"), list(name = "B", anv = "Bee", join = "")),
        extraartists = list(list(name = "C", role = "Vocals", id = 3))
      )
    ),
    extraartists = list(list(name = "D", role = "Producer", tracks = "", id = 4))
  )
  tracks <- tracklist_tibble(body$tracklist)
  expect_equal(tracks$type, c("index", "track", "track", "track"))
  expect_equal(tracks$position, c(NA, "1a", "1b", "2"))
  expect_equal(tracks$seconds, c(NA, 3723L, NA, 240L))
  expect_equal(tracks$artist, c(NA, NA, NA, "A & Bee"))
  credits <- credits_tibble(body)
  expect_equal(credits$name, c("D", "C"))
  expect_equal(credits$tracks, c(NA, "2"))
})

test_that("NULL from a failed request passes through", {
  expect_null(dig_tracklist(NULL))
})

test_that("unnesting no releases keeps the columns and types", {
  empty <- tibble::tibble(release_id = integer(), credits = list())
  out <- dig_credits(empty)
  expect_named(out, c("release_id", "name", "credited_as", "role", "tracks", "artist_id"))
  expect_type(out$artist_id, "integer")
})

test_that("releases without items are dropped and the others keep their IDs", {
  x <- tibble::tibble(
    release_id = c(1L, 2L, 3L),
    formats = list(
      formats_tibble(list(list(name = "CD", qty = "2"))),
      formats_tibble(list()),
      NULL
    )
  )
  out <- dig_formats(x)
  expect_equal(out$release_id, 1L)
  expect_equal(out$quantity, 2L)
})
