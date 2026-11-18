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
  urls <- list()
  httr2::local_mocked_responses(function(req) {
    urls[[length(urls) + 1]] <<- httr2::url_parse(req$url)
    discogs_response(fixture("collection-example"))
  })
  dig_collection(" some.user ", folder = 3, sort = "year", order = "desc", page = 2, per_page = 10)
  url <- urls[[1]]
  expect_equal(url$path, "/users/some.user/collection/folders/3/releases")
  expect_equal(urls[[2]]$path, "/users/some.user/collection/fields")
  expect_equal(url$query[c("sort", "sort_order", "page", "per_page")],
               list(sort = "year", sort_order = "desc", page = "2", per_page = "10"))
})

test_that("dig_collection reads the media and sleeve conditions", {
  local_dig_state()
  local_fixtures()
  out <- dig_collection("example", per_page = 3)
  expect_equal(names(out)[9:11], c("format", "media_condition", "sleeve_condition"))
  expect_equal(as.character(out$media_condition), c("Near Mint (NM or M-)", "Very Good (VG)", NA))
  expect_equal(as.character(out$sleeve_condition), c("Very Good Plus (VG+)", "Generic", NA))
  expect_equal(levels(out$media_condition), conditions)
  expect_equal(levels(out$sleeve_condition), c(conditions, "Generic", "No Cover"))
  expect_false(any(c("notes", "shelf") %in% names(out)))
})

test_that("condition fields are matched by name, not by ID", {
  local_dig_state()
  httr2::local_mocked_responses(function(req) {
    if (stringr::str_ends(httr2::url_parse(req$url)$path, "/fields")) {
      return(discogs_response(list(fields = list(
        list(name = "Notes", id = 1, type = "textarea"),
        list(name = " sleeve  condition ", id = 5, type = "dropdown"),
        list(name = "Media", id = 9, type = "dropdown")
      ))))
    }
    discogs_response(list(releases = list(list(id = 1, notes = list(
      list(field_id = 1, value = "Mint (M)"),
      list(field_id = 9, value = "Very Good Plus (VG+)"),
      list(field_id = 5, value = "Sealed")
    )))))
  })
  out <- dig_collection("example")
  expect_equal(as.character(out$media_condition), "Very Good Plus (VG+)")
  expect_equal(as.character(out$sleeve_condition), "Sealed")
  expect_equal(levels(out$sleeve_condition), c(conditions, "Generic", "No Cover", "Sealed"))
})

test_that("conditions are NA when fields are missing, private or broken", {
  local_dig_state()
  bodies <- list(
    list(fields = list(list(name = "Notes", id = 3, type = "textarea"))),
    list(fields = "broken"),
    list()
  )
  for (fields in bodies) {
    httr2::local_mocked_responses(function(req) {
      if (stringr::str_ends(httr2::url_parse(req$url)$path, "/fields")) {
        return(discogs_response(fields))
      }
      discogs_response(list(releases = list(list(id = 1, notes = list(list(field_id = 1, value = "Mint (M)"))))))
    })
    out <- dig_collection("example")
    expect_true(is.na(out$media_condition))
    expect_true(is.na(out$sleeve_condition))
  }
})

test_that("the fields are only requested when a copy has notes", {
  local_dig_state()
  calls <- 0L
  httr2::local_mocked_responses(function(req) {
    calls <<- calls + 1L
    discogs_response(list(releases = list(list(id = 1), list(id = 2, notes = list()))))
  })
  out <- dig_collection("example")
  expect_equal(calls, 1L)
  expect_equal(nrow(out), 2)
  expect_true(all(is.na(out$media_condition)))
  expect_s3_class(out$media_condition, "factor")
})

test_that("dig_collection returns NULL when the fields cannot be reached", {
  local_dig_state()
  httr2::local_mocked_responses(function(req) {
    if (stringr::str_ends(httr2::url_parse(req$url)$path, "/fields")) {
      return(discogs_response(list(message = "Server error."), status = 500L))
    }
    discogs_response(fixture("collection-example"))
  })
  expect_message(out <- dig_collection("example"), "not available")
  expect_null(out)
})

test_that("dig_wantlist returns releases without the notes of the user", {
  local_dig_state()
  local_fixtures()
  out <- dig_wantlist("example")
  expect_equal(out$release_id, c(1003L, 1002L))
  expect_false("notes" %in% names(out))
  expect_equal(out$rating, c(NA, 3L))
  expect_equal(out$styles[[1]], c("Downtempo", "Electro"))
  expect_equal(names(out)[ncol(out)], "date_added")
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
  expect_error(dig_collection(".."), "not a valid username")
  expect_error(dig_wantlist(" . "), "not a valid username")
  expect_error(dig_collection("a\nb"), "not a valid username")
  expect_error(dig_collection(c("a", "b")), "single username")
  expect_error(dig_wantlist(NA_character_), "single username")
  expect_error(dig_wantlist(1), "single username")
  expect_error(dig_collection("a", folder = -1), "from 0")
  expect_error(dig_collection("a", folder = 1.5), "from 0")
  expect_error(dig_wantlist("a", sort = "released"), "must be one of")
  expect_error(dig_wantlist("a", per_page = 101), "1 to 100")
})

test_that("condition values are trimmed and duplicate or untyped fields are read", {
  local_dig_state()
  httr2::local_mocked_responses(function(req) {
    if (stringr::str_ends(httr2::url_parse(req$url)$path, "/fields")) {
      return(discogs_response(list(fields = list(
        list(name = "Media", id = 7, type = "dropdown"),
        list(name = "Media", id = 1, type = "dropdown"),
        list(name = "Sleeve", id = 2)
      ))))
    }
    discogs_response(list(releases = list(
      list(id = 1, notes = list(list(field_id = 1, value = "  Mint  (M) "), list(field_id = 2, value = "No Cover"))),
      list(id = 2, notes = list(list(field_id = 7, value = " "), list(field_id = 1, value = "Good (G)")))
    )))
  })
  out <- dig_collection("example")
  expect_equal(as.character(out$media_condition), c("Mint (M)", "Good (G)"))
  expect_equal(as.character(out$sleeve_condition), c("No Cover", NA))
  expect_equal(levels(out$media_condition), conditions)
})

test_that("an error from the fields request keeps the collection", {
  local_dig_state()
  httr2::local_mocked_responses(function(req) {
    if (stringr::str_ends(httr2::url_parse(req$url)$path, "/fields")) {
      return(discogs_response(list(message = "Forbidden."), status = 403L))
    }
    discogs_response(fixture("collection-example"))
  })
  expect_message(out <- dig_collection("example"), "conditions are NA")
  expect_equal(nrow(out), 3)
  expect_true(all(is.na(out$media_condition)))
})

test_that("dig_collection_folders lists the folders", {
  local_dig_state()
  local_fixtures()
  out <- dig_collection_folders("example")
  expect_named(out, c("folder_id", "name", "count"))
  expect_equal(out$folder_id, 0:2)
  expect_equal(out$name, c("All", "Uncategorized", "Compilations"))
  expect_equal(out$count, c(3L, 2L, 1L))
})

test_that("dig_collection_folders returns NULL when the API cannot be reached", {
  local_dig_state()
  httr2::local_mocked_responses(function(req) discogs_response(list(), status = 503L))
  local_mocked_bindings(retry_backoff = \(attempt) 0)
  expect_message(out <- dig_collection_folders("example"))
  expect_null(out)
})

test_that("without a username the owner of the token is used, found once", {
  local_dig_state(token = "abc")
  paths <- character()
  httr2::local_mocked_responses(function(req) {
    path <- httr2::url_parse(req$url)$path
    paths <<- c(paths, path)
    if (path == "/oauth/identity") {
      return(raw_response("identity-example"))
    }
    discogs_response(fixture("wantlist-example"))
  })
  dig_wantlist()
  dig_wantlist()
  expect_equal(paths, c("/oauth/identity", "/users/example/wants", "/users/example/wants"))
  dig_cache_clear()
  dig_wantlist()
  expect_equal(sum(paths == "/oauth/identity"), 2L)
  suppressMessages(dig_auth("def"))
  dig_wantlist()
  expect_equal(sum(paths == "/oauth/identity"), 3L)
})

test_that("without a username or token the functions stop", {
  local_dig_state()
  expect_error(dig_collection(), "needed when no token is set")
  expect_error(dig_collection_folders(), "needed when no token is set")
  expect_error(dig_wantlist(), "dig_auth")
})

test_that("a missing identity is reported", {
  local_dig_state(token = "abc")
  httr2::local_mocked_responses(list(discogs_response(list(id = 1))))
  expect_error(dig_collection(), "did not return the username")
})

test_that("an unreachable identity returns NULL", {
  local_dig_state(token = "abc")
  httr2::local_mocked_responses(function(req) discogs_response(list(), status = 503L))
  local_mocked_bindings(retry_backoff = \(attempt) 0)
  expect_message(out <- dig_collection())
  expect_null(out)
})
