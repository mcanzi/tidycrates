shelf <- function() {
  tibble::tibble(
    release_id = c(1L, 1L, 2L, 3L, 4L),
    instance_id = 11:15,
    artist = c("A", "A", "B", "C", NA),
    year = c(1987L, 1987L, 1995L, 1999L, NA),
    label = c("Fernhollow", "Fernhollow", "Mossbank; Tidewater", "Other", ""),
    format = c("Vinyl", "Vinyl", "CD", "Vinyl; CD", "File"),
    genres = list(c("Pop", "Electronic"), c("Pop", "Electronic"), "Electronic", character(), "Jazz"),
    styles = list("Euro-Disco", "Euro-Disco", character(), character(), character()),
    date_added = as.POSIXct(
      c("2024-01-05 10:00", "2024-01-30 23:59", "2024-03-01 00:00", "2024-03-15 12:00", "2025-02-01 08:00"),
      tz = "UTC"
    )
  )
}

test_that("copies with several values count once for each", {
  out <- dig_tally(shelf(), "genre")
  expect_equal(names(out), c("genre", "n", "share"))
  expect_equal(out$genre, c("Electronic", "Pop", "Jazz"))
  expect_equal(out$n, c(3L, 2L, 1L))
  expect_equal(out$share, c(0.6, 0.4, 0.2))
  expect_equal(dig_tally(shelf(), "format")$n, c(3L, 2L, 1L))
})

test_that("values outside the top n are counted as Other", {
  out <- dig_tally(shelf(), "format", n = 1)
  expect_equal(out$format, c("Vinyl", "Other"))
  expect_equal(out$n, c(3L, 3L))
  out <- dig_tally(shelf(), "label", n = 1)
  expect_equal(out$label, c("Fernhollow", "All other"))
  expect_equal(out$n, c(2L, 2L))
  out <- dig_tally(shelf(), "label", n = 2)
  expect_equal(out$label, c("Fernhollow", "Mossbank", "All other"))
  expect_equal(nrow(dig_tally(shelf(), "label", n = Inf)), 4)
})

test_that("missing and empty values are left out", {
  expect_equal(dig_tally(shelf(), "artist")$artist, c("A", "B", "C"))
  expect_false("" %in% dig_tally(shelf(), "label")$label)
  expect_equal(nrow(dig_tally(shelf(), "style")), 1)
})

test_that("years and decades are in order", {
  out <- dig_tally(shelf(), "year")
  expect_equal(out$year, c(1987L, 1995L, 1999L))
  expect_equal(out$n, c(2L, 1L, 1L))
  out <- dig_tally(shelf(), "decade", n = 1)
  expect_equal(out$decade, c(1980L, 1990L))
  expect_equal(out$n, c(2L, 2L))
})

test_that("added gives copies per month and a running total", {
  out <- dig_tally(shelf(), "added")
  expect_equal(out$added, as.Date(c("2024-01-01", "2024-03-01", "2025-02-01")))
  expect_equal(out$n, c(2L, 2L, 1L))
  expect_equal(out$total, c(2L, 4L, 5L))
})

test_that("unique counts each release once", {
  out <- dig_tally(shelf(), "genre", unique = TRUE)
  expect_equal(out$n, c(2L, 1L, 1L))
  expect_equal(out$share, c(0.5, 0.25, 0.25))
})

test_that("empty collections give empty tallies", {
  empty <- shelf()[0, ]
  expect_equal(nrow(dig_tally(empty, "genre")), 0)
  expect_equal(nrow(dig_tally(empty, "added")), 0)
  expect_s3_class(dig_tally(empty, "added")$added, "Date")
})

test_that("tally arguments are checked", {
  expect_null(dig_tally(NULL))
  expect_error(dig_tally(shelf(), "colour"), "must be one of")
  expect_error(dig_tally(shelf(), n = 0), "positive whole number")
  expect_error(dig_tally(shelf(), n = 1.5), "positive whole number")
  expect_error(dig_tally(shelf(), unique = NA), "TRUE")
  expect_error(dig_tally(1:3), "must be a tibble")
  expect_error(dig_tally(shelf()[c("release_id", "year")], "genre"), "no genres column")
  expect_error(dig_tally(shelf()["genres"], unique = TRUE), "no ID column")
  expect_error(dig_tally(shelf(), "role"), "cannot be tallied by \"role\"")
})

test_that("label releases are tallied by the first part of the format", {
  local_dig_state()
  local_fixtures()
  releases <- dig_label_releases(4001)
  out <- dig_tally(releases, "format")
  expect_equal(out$format, c("CD", "12\""))
  expect_equal(out$n, c(2L, 1L))
  out <- dig_tally(releases, "decade")
  expect_equal(out$decade, 1990L)
  expect_equal(out$n, 2L)
  expect_error(dig_tally(releases, "genre"), "no genres column")
})

test_that("artist releases are tallied with their masters", {
  local_dig_state()
  local_fixtures()
  releases <- dig_artist_releases(3001, per_page = 3)
  expect_equal(dig_tally(releases, "role")$n, 3L)
  expect_equal(dig_tally(releases, "format")$format, "10\"")
  expect_equal(dig_tally(releases, "label")$label, "Fernhollow Records")
  expect_equal(dig_tally(releases, "year", unique = TRUE)$n, 3L)
  expect_equal(dig_tally(releases, "role")$share, 1)
})

test_that("master versions use major formats and release dates", {
  local_dig_state()
  local_fixtures()
  versions <- dig_master_versions(2001)
  out <- dig_tally(versions, "format")
  expect_equal(out$format, c("Cassette", "CD"))
  expect_equal(out$n, c(2L, 1L))
  expect_equal(dig_tally(versions, "country")$country, c("Bulgaria", "Poland", "UK & France"))
  expect_equal(dig_tally(versions, "year")$year, 1997L)
  expect_equal(dig_tally(versions, "decade")$n, 3L)
})

test_that("releases are tallied by country and month added", {
  local_dig_state()
  local_fixtures()
  release <- dig_release(1001)
  expect_equal(dig_tally(release, "country")$country, "UK")
  expect_equal(dig_tally(release, "format")$format, "Vinyl")
  expect_equal(dig_tally(release, "added")$added, as.Date("2004-04-01"))
})

test_that("rankings are drawn as labelled lollipops", {
  skip_if_not_installed("ggplot2")
  plot <- dig_plot(shelf(), "genre")
  labs <- ggplot2::get_labs(plot)
  expect_s3_class(plot, "ggplot")
  expect_equal(
    unname(purrr::map_chr(plot$layers, \(l) class(l$geom)[1])),
    c("GeomSegment", "GeomPoint", "GeomText")
  )
  expect_equal(levels(plot$data$value), c("Jazz", "Pop", "Electronic"))
  expect_equal(plot$data$tip[1], "3 (60%)")
  expect_equal(labs$title, "Copies by genre")
  expect_equal(labs$caption, "Data provided by Discogs.")
  for (by in c("decade", "year", "added")) {
    expect_equal(ggplot2::get_labs(dig_plot(shelf(), by))$caption, "Data provided by Discogs.")
  }
  expect_equal(labs$subtitle, "5 copies. A copy can have more than one genre.")
  expect_match(ggplot2::get_alt_text(plot), "Electronic is the most common, with 3 copies (60%)", fixed = TRUE)
  lumped <- dig_plot(shelf(), "format", n = 1)
  expect_equal(lumped$layers[[2]]$aes_params$fill, c("#2a78d6", "#898781"))
  expect_match(ggplot2::get_labs(lumped)$subtitle, "the 1 most common of 3 formats shown")
})

test_that("roles are written as words", {
  skip_if_not_installed("ggplot2")
  credits <- tibble::tibble(type = "release", id = 1:3, role = c("TrackAppearance", "Main", "Main"))
  plot <- dig_plot(credits, "role")
  expect_equal(levels(plot$data$value), c("Track appearance", "Main"))
  expect_equal(ggplot2::get_labs(plot)$title, "Releases by role")
})

test_that("decades are columns with empty decades kept", {
  skip_if_not_installed("ggplot2")
  plot <- dig_plot(shelf(), "decade")
  expect_equal(ggplot2::get_labs(plot)$subtitle, "5 copies, 1 with an unknown year left out.")
  gap <- tibble::tibble(release_id = 1:3, year = c(1965L, 1987L, 1988L))
  built <- ggplot2::ggplot_build(dig_plot(gap, "decade"))
  expect_equal(built$layout$panel_params[[1]]$x$get_labels(), c("1960s", "1970s", "1980s"))
  expect_equal(built$data[[1]]$y, c(1, 0, 2))
  expect_equal(ggplot2::get_labs(dig_plot(shelf(), "decade", unique = TRUE))$title, "Releases by decade")
})

test_that("years mark the busiest year", {
  skip_if_not_installed("ggplot2")
  plot <- dig_plot(shelf(), "year")
  expect_equal(plot$layers[[2]]$aes_params$label, "1987: 2")
  expect_equal(ggplot2::get_labs(dig_plot(shelf()[-2], "year"))$title, "Releases by year")
})

test_that("growth is a line with the total at the end", {
  skip_if_not_installed("ggplot2")
  plot <- dig_plot(shelf(), "added")
  expect_equal(
    unname(purrr::map_chr(plot$layers, \(l) class(l$geom)[1])),
    c("GeomArea", "GeomLine", "GeomPoint", "GeomText")
  )
  expect_equal(ggplot2::get_labs(plot)$title, "Copies over time")
  expect_equal(ggplot2::get_labs(plot)$subtitle, "5 copies added since January 2024.")
  expect_match(ggplot2::get_alt_text(plot), "reaching 5")
})

test_that("dig_plot handles empty and missing input", {
  skip_if_not_installed("ggplot2")
  expect_equal(ggplot2::get_labs(dig_plot(shelf()[0, ], "genre"))$subtitle, "Nothing to plot.")
  expect_null(dig_plot(NULL))
  expect_error(dig_plot(shelf(), "colour"), "must be one of")
  expect_error(dig_plot(shelf(), "country"), "no country column")
})

test_that("labels that would merge are kept apart", {
  skip_if_not_installed("ggplot2")
  spaced <- tibble::tibble(release_id = 1:3, artist = c("Foo  Bar", "Foo Bar", "Baz"))
  expect_equal(levels(dig_plot(spaced, "artist")$data$value), c("Foo Bar", "Foo  Bar", "Baz"))
  long <- tibble::tibble(release_id = 1:2, artist = c(strrep("Name ", 8), "B"))
  expect_match(levels(dig_plot(long, "artist")$data$value)[1], "\n", fixed = TRUE)
  roles <- tibble::tibble(type = "release", id = 1:2, role = c("TrackAppearance", "Track appearance"))
  expect_setequal(levels(dig_plot(roles, "role")$data$value), c("TrackAppearance", "Track appearance"))
})

test_that("growth starts from zero, even for one month", {
  skip_if_not_installed("ggplot2")
  one <- shelf()[1, ]
  plot <- dig_plot(one, "added")
  expect_equal(plot$data$total, c(0L, 1L))
  expect_equal(plot$data$added, as.Date(c("2023-12-01", "2024-01-01")))
  expect_no_message(ggplot2::ggplot_build(plot))
  expect_equal(ggplot2::get_labs(plot)$subtitle, "1 copy added since January 2024.")
})

test_that("numbers and shares are formatted for reading", {
  expect_equal(count_of(1L, "copies"), "1 copy")
  expect_equal(count_of(2000L, "releases"), "2,000 releases")
  expect_equal(big_number(c(5L, 12345L)), c("5", "12,345"))
  expect_equal(percent(c(0.001, 0.5, 0)), c("<1%", "50%", "0%"))
})
