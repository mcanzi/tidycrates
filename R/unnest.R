#' Unnest release data
#'
#' Turns the list columns of [dig_release()] into tibbles with one row per
#' track, credit, format or identifier. Each row keeps the ID of its
#' release.
#'
#' `dig_tracklist()` also accepts the output of [dig_master()]. Headings
#' and index tracks are kept with their `type`, and the tracks of an index
#' follow it. `seconds` is the duration converted to seconds.
#'
#' `dig_credits()` combines the credits of the whole release with those of
#' single tracks. `credited_as` is the name printed on the release, if it
#' differs from the artist name, and `tracks` gives the positions a credit
#' applies to.
#'
#' @param x A tibble returned by [dig_release()] or, for `dig_tracklist()`,
#'   [dig_master()]. Release IDs or codes such as `"[r249504]"` are also
#'   accepted and fetched first.
#'
#' @return A tibble, or `NULL` invisibly if the API cannot be reached.
#'
#' @examplesIf interactive()
#' release <- dig_release(249504)
#' dig_tracklist(release)
#' dig_credits(release)
#' dig_formats(release)
#' dig_identifiers(release)
#'
#' @name unnest_release
NULL

#' @rdname unnest_release
#' @export
dig_tracklist <- function(x) {
  unnest_column(x, "tracklist")
}

#' @rdname unnest_release
#' @export
dig_credits <- function(x) {
  unnest_column(x, "credits")
}

#' @rdname unnest_release
#' @export
dig_formats <- function(x) {
  unnest_column(x, "formats")
}

#' @rdname unnest_release
#' @export
dig_identifiers <- function(x) {
  unnest_column(x, "identifiers")
}

unnest_column <- function(x, column, call = rlang::caller_env()) {
  if (is.null(x)) {
    return(invisible(NULL))
  }
  if (!is.data.frame(x)) {
    x <- dig_release(check_ids(x, "r", "x", call))
    if (is.null(x)) {
      return(invisible(NULL))
    }
  }
  id <- intersect(c("release_id", "master_id"), names(x))[1]
  if (is.na(id) || !column %in% names(x)) {
    cli::cli_abort(
      "{.arg x} must be the output of {.fn dig_release} or a vector of release IDs.",
      call = call
    )
  }
  template <- switch(column,
    tracklist = tracklist_tibble(list()),
    credits = credits_tibble(list()),
    formats = formats_tibble(list()),
    identifiers = identifiers_tibble(list())
  )
  nested <- purrr::map(x[[column]], \(t) if (is.data.frame(t)) t else template)
  ids <- rep(x[[id]], purrr::map_int(nested, nrow))
  out <- dplyr::bind_rows(c(list(template), nested))
  out[[id]] <- ids
  dplyr::relocate(out, dplyr::all_of(id))
}

flatten_tracks <- function(tracks) {
  as_items(tracks) |>
    purrr::map(\(t) c(list(t), as_items(t[["sub_tracks"]]))) |>
    purrr::list_flatten()
}

tracklist_tibble <- function(tracks) {
  tracks <- flatten_tracks(tracks)
  duration <- chr(tracks, "duration")
  tibble::tibble(
    position = chr(tracks, "position"),
    type = chr(tracks, "type_"),
    title = chr(tracks, "title"),
    artist = purrr::map_chr(tracks, \(t) artist_names(t[["artists"]])),
    duration = duration,
    seconds = as_seconds(duration)
  )
}

credits_tibble <- function(body) {
  track_credits <- flatten_tracks(pluck_list(body, "tracklist")) |>
    purrr::map(\(t) {
      position <- as_chr(t[["position"]])
      purrr::map(as_items(t[["extraartists"]]), \(a) utils::modifyList(a, list(tracks = position)))
    }) |>
    purrr::list_flatten()
  credits <- c(as_items(pluck_list(body, "extraartists")), track_credits)
  tibble::tibble(
    name = chr(credits, "name"),
    credited_as = chr(credits, "anv"),
    role = chr(credits, "role"),
    tracks = chr(credits, "tracks"),
    artist_id = int(credits, "id")
  )
}

formats_tibble <- function(formats) {
  formats <- as_items(formats)
  tibble::tibble(
    format = chr(formats, "name"),
    quantity = int(formats, "qty"),
    text = chr(formats, "text"),
    descriptions = chr(formats, "descriptions")
  )
}

identifiers_tibble <- function(identifiers) {
  identifiers <- as_items(identifiers)
  tibble::tibble(
    type = chr(identifiers, "type"),
    value = chr(identifiers, "value"),
    description = chr(identifiers, "description")
  )
}

companies_tibble <- function(body) {
  companies <- c(as_items(pluck_list(body, "labels")), as_items(pluck_list(body, "companies")))
  tibble::tibble(
    name = chr(companies, "name"),
    role = chr(companies, "entity_type_name"),
    catno = chr(companies, "catno"),
    label_id = int(companies, "id")
  )
}
