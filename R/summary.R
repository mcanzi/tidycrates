#' Tally releases
#'
#' Counts the rows of a tibble returned by tidycrates, such as the copies
#' in a collection or the releases of a label, by genre, style, format,
#' label, artist, role, country, year, decade or month added. Only the
#' columns of `x` are used, so no requests are sent.
#'
#' Which values of `by` work depends on where `x` comes from:
#'
#' | `x` from | `by` |
#' |---|---|
#' | [dig_collection()], [dig_wantlist()] | genre, style, format, label, artist, decade, year, added |
#' | [dig_release()] | genre, style, format, label, artist, country, decade, year, added |
#' | [dig_master()] | genre, style, artist, decade, year |
#' | [dig_artist_releases()] | format, label, artist, role, decade, year |
#' | [dig_label_releases()] | format, artist, decade, year |
#' | [dig_master_versions()] | format, label, country, decade, year |
#' | [dig_search()] | genre, style, format, label, country, decade, year |
#'
#' A row with several genres, styles, formats or labels counts once for
#' each of them, so the shares can add up to more than 1. Rows without a
#' value, such as releases with an unknown year, are left out.
#'
#' The lists of [dig_artist_releases()] and [dig_label_releases()] give
#' formats as descriptions such as `2x12", Comp`. Only the first part is
#' counted, without the number of items, so vinyl is counted by size, for
#' example `12"`. [dig_search()] gives the format of a release followed by
#' its descriptions, and only the format is counted. Master releases in
#' [dig_artist_releases()] stand for all their versions and have no format
#' or label. For [dig_release()], `added` is the month the release was
#' added to 'Discogs'.
#'
#' Collections and wantlists have no country, because 'Discogs' does not
#' return it for them. To tally a collection by country, get its releases
#' first with `dig_release(collection$release_id)`. This sends one request
#' for each release.
#'
#' Tallies of a collection or wantlist are still Restricted Data, see
#' [dig_collection()].
#'
#' @param x A tibble returned by one of the functions listed in Details.
#' @param by What to count by: `"genre"`, `"style"`, `"format"`, `"label"`,
#'   `"artist"`, `"role"`, `"country"`, `"decade"`, `"year"` or `"added"`,
#'   the month a copy was added.
#' @param n The number of values to keep for all but years, decades and
#'   months. The rest are counted together as `"Other"`. `Inf` keeps all
#'   values.
#' @param unique If `TRUE`, each release counts once, however many copies
#'   of it there are.
#'
#' @return A tibble with a column named after `by`, `n`, the number of
#'   rows, and `share`, the share of all rows. For `by = "added"`, `total`
#'   gives the running number of rows at the end of each month, such as the
#'   size of a collection. Years, decades and months are in order, and
#'   other values are sorted from most to least common. `"Other"` counts
#'   the rows with at least one value outside the top `n`. It is called
#'   `"All other"` if one of the values is `"Other"`. `NULL` is returned
#'   invisibly if `x` is `NULL`.
#'
#' @examplesIf interactive()
#' collection <- dig_collection("username", all = TRUE)
#' dig_tally(collection, "genre")
#' dig_tally(collection, "added")
#' dig_tally(dig_label_releases(1, all = TRUE), "decade")
#'
#' @export
dig_tally <- function(x,
                      by = c("genre", "style", "format", "label", "artist", "role", "country",
                             "decade", "year", "added"),
                      n = 10, unique = FALSE) {
  by <- rlang::arg_match(by)
  tally_collection(x, by, n, unique)
}

tally_collection <- function(x, by, n, unique, call = rlang::caller_env()) {
  if (is.null(x)) {
    return(invisible(NULL))
  }
  check_flag(unique, call = call)
  if (!identical(n, Inf) && !(rlang::is_scalar_integerish(n, finite = TRUE) && n >= 1)) {
    cli::cli_abort("{.arg n} must be a positive whole number or `Inf`.", call = call)
  }
  if (!is.data.frame(x)) {
    cli::cli_abort("{.arg x} must be a tibble returned by a tidycrates function.", call = call)
  }
  if (unique) {
    x <- dplyr::distinct(x, dplyr::across(dplyr::all_of(release_key(x, call))), .keep_all = TRUE)
  }
  values <- tally_values(x, by, call)
  long <- if (is.list(values)) {
    tibble::tibble(
      copy = rep(seq_along(values), lengths(values)),
      value = purrr::list_c(values, ptype = character())
    )
  } else {
    tibble::tibble(copy = seq_along(values), value = values)
  }
  long <- dplyr::filter(long, !is.na(.data$value))
  if (is.character(long$value)) {
    long <- dplyr::filter(long, .data$value != "")
  }
  counts <- dplyr::summarise(long, n = dplyr::n_distinct(.data$copy), .by = "value")
  if (by %in% c("decade", "year", "added")) {
    counts <- dplyr::arrange(counts, .data$value)
  } else {
    counts <- dplyr::arrange(counts, dplyr::desc(.data$n), .data$value)
    if (nrow(counts) > n) {
      top <- counts$value[seq_len(n)]
      rest <- long |>
        dplyr::filter(!.data$value %in% top) |>
        dplyr::pull("copy") |>
        dplyr::n_distinct()
      other <- if ("Other" %in% counts$value) "All other" else "Other"
      counts <- dplyr::bind_rows(counts[seq_len(n), ], tibble::tibble(value = other, n = rest))
    }
  }
  counts$share <- counts$n / max(nrow(x), 1L)
  if (by == "added") {
    counts$total <- cumsum(counts$n)
  }
  names(counts)[1] <- by
  counts
}

tally_by <- c("genre", "style", "format", "label", "artist", "role", "country", "decade", "year", "added")

tally_column <- function(x, by) {
  has <- \(column) column %in% names(x)
  switch(by,
    genre = "genres",
    style = "styles",
    added = "date_added",
    format = if (has("major_formats")) "major_formats" else "format",
    year = ,
    decade = if (has("year")) "year" else "released",
    by
  )
}

tally_values <- function(x, by, call) {
  has <- \(column) column %in% names(x)
  column <- tally_column(x, by)
  if (!has(column)) {
    usable <- purrr::keep(tally_by, \(b) has(tally_column(x, b)))
    from_releases <- has("release_id") && !by %in% c("role", "added")
    cli::cli_abort(
      c(
        "{.arg x} has no {.field {column}} column, so it cannot be tallied by {.val {by}}.",
        i = if (length(usable) > 0) "{.arg x} can be tallied by {.or {.val {usable}}}.",
        i = if (length(usable) == 0) "{.arg x} has no column that can be tallied.",
        i = if (from_releases) "To tally by {.val {by}}, get the releases first: {.code dig_release(x$release_id)}."
      ),
      call = call
    )
  }
  values <- x[[column]]
  if (by %in% c("year", "decade") && column == "released") {
    values <- as_year(suppressWarnings(as.integer(stringr::str_sub(values, 1, 4))))
  }
  switch(by,
    format = if (column == "major_formats") {
      stringr::str_split(values, ", ")
    } else {
      values |>
        stringr::str_split("; ") |>
        purrr::map(\(v) v |> stringr::str_extract("^[^,]+") |> stringr::str_remove("^[0-9]+x"))
    },
    label = stringr::str_split(values, "; "),
    decade = values %/% 10L * 10L,
    added = as.Date(format(values, "%Y-%m-01", tz = "UTC")),
    values
  )
}

release_key <- function(x, call = rlang::caller_env()) {
  if ("release_id" %in% names(x)) {
    return("release_id")
  }
  if (all(c("type", "id") %in% names(x))) {
    return(c("type", "id"))
  }
  if ("master_id" %in% names(x)) {
    return("master_id")
  }
  cli::cli_abort("{.arg x} has no ID column, so {.code unique = TRUE} cannot be used.", call = call)
}
