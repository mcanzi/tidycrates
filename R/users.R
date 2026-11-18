#' List the collection of a user
#'
#' Lists the releases in the collection of a 'Discogs' user. Anyone can
#' read a public collection. A private collection can only be read with
#' the token of its owner, see [dig_auth()].
#'
#' A release that is in the collection more than once has one row per
#' copy, each with its own `instance_id`. Custom fields, such as the media
#' condition, are left out. Collections are never cached, so changes show
#' up at once.
#'
#' @section Restricted Data:
#' Collections, wantlists and usernames are Restricted Data under the
#' 'Discogs' API Terms of Use. 'Discogs' grants a limited, personal licence
#' to use them. They may not be passed on to anyone else or used for
#' commercial purposes, and their use must respect the privacy of their
#' owners. Only publish a collection or wantlist, or tallies and plots of
#' it, if it is your own or its owner has agreed, and never for commercial
#' purposes.
#'
#' @inheritParams dig_artist_releases
#' @param username A 'Discogs' username.
#' @param folder The ID of a collection folder. The default, `0`, holds the
#'   whole collection and is the only folder other users can read.
#' @param sort The column to sort by: `"added"`, `"artist"`, `"title"`,
#'   `"label"`, `"catno"`, `"format"`, `"rating"` or `"year"`.
#'
#' @return A tibble with one row per copy of a release, or `NULL`
#'   invisibly if the API cannot be reached. The columns are `release_id`,
#'   `instance_id`, `folder_id`, `title`, `artist`, `year`, `label`,
#'   `catno`, `format`, `genres` and `styles` as list columns, `master_id`,
#'   `rating` and `date_added`. `rating` is `NA` if the user gave none.
#'
#' @examplesIf interactive()
#' collection <- dig_collection("username", all = TRUE)
#' dplyr::count(collection, format, sort = TRUE)
#'
#' @export
dig_collection <- function(username, folder = 0,
                           sort = c("added", "artist", "title", "label", "catno", "format", "rating", "year"),
                           order = c("asc", "desc"), all = FALSE, page = 1,
                           per_page = 50) {
  username <- check_username(username)
  if (!rlang::is_scalar_integerish(folder, finite = TRUE) || folder < 0) {
    cli::cli_abort("{.arg folder} must be a whole number from 0.")
  }
  sort <- rlang::arg_match(sort)
  order <- rlang::arg_match(order)
  check_page(page, per_page, all)
  items <- dig_get_pages(
    paste0("users/", username, "/collection/folders/", format(folder, scientific = FALSE), "/releases"),
    "releases",
    query = list(sort = sort, sort_order = order),
    all = all, page = page, per_page = per_page, cache = FALSE
  )
  if (is.null(items)) {
    return(invisible(NULL))
  }
  items <- as_items(items)
  basic_tibble(items) |>
    tibble::add_column(
      instance_id = int(items, "instance_id"),
      folder_id = int(items, "folder_id"),
      .after = "release_id"
    )
}

#' List the wantlist of a user
#'
#' Lists the releases in the wantlist of a 'Discogs' user. Anyone can read
#' a public wantlist. A private wantlist can only be read with the token of
#' its owner, see [dig_auth()]. Wantlists are never cached, so changes
#' show up at once.
#'
#' @inheritSection dig_collection Restricted Data
#' @inheritParams dig_collection
#'
#' @return A tibble with one row per release, or `NULL` invisibly if the
#'   API cannot be reached. The columns are `release_id`, `title`,
#'   `artist`, `year`, `label`, `catno`, `format`, `genres` and `styles` as
#'   list columns, `master_id`, `rating`, `date_added` and `notes`.
#'   `rating` is `NA` if the user gave none.
#'
#' @examplesIf interactive()
#' dig_wantlist("username", all = TRUE)
#'
#' @export
dig_wantlist <- function(username,
                         sort = c("added", "artist", "title", "label", "catno", "format", "rating", "year"),
                         order = c("asc", "desc"), all = FALSE, page = 1,
                         per_page = 50) {
  username <- check_username(username)
  sort <- rlang::arg_match(sort)
  order <- rlang::arg_match(order)
  check_page(page, per_page, all)
  items <- dig_get_pages(
    paste0("users/", username, "/wants"), "wants",
    query = list(sort = sort, sort_order = order),
    all = all, page = page, per_page = per_page, cache = FALSE
  )
  if (is.null(items)) {
    return(invisible(NULL))
  }
  items <- as_items(items)
  basic_tibble(items) |>
    tibble::add_column(notes = chr(items, "notes"))
}

check_username <- function(x, arg = rlang::caller_arg(x), call = rlang::caller_env()) {
  if (!rlang::is_string(x) || is.na(x) || !nzchar(stringr::str_trim(x))) {
    cli::cli_abort("{.arg {arg}} must be a single username.", call = call)
  }
  utils::URLencode(stringr::str_trim(x), reserved = TRUE)
}

basic_tibble <- function(items) {
  info <- purrr::map(items, \(i) pluck_list(i, "basic_information") %||% list())
  tibble::tibble(
    release_id = int(items, "id"),
    title = chr(info, "title"),
    artist = purrr::map_chr(info, \(i) artist_names(pluck_list(i, "artists"))),
    year = as_year(int(info, "year")),
    label = purrr::map_chr(info, \(i) paste_unique(chr(as_items(pluck_list(i, "labels")), "name"))),
    catno = purrr::map_chr(info, \(i) paste_unique(chr(as_items(pluck_list(i, "labels")), "catno"))),
    format = purrr::map_chr(info, \(i) paste_unique(chr(as_items(pluck_list(i, "formats")), "name"))),
    genres = purrr::map(info, \(i) strings(pluck_list(i, "genres"))[[1]]),
    styles = purrr::map(info, \(i) strings(pluck_list(i, "styles"))[[1]]),
    master_id = dplyr::na_if(int(info, "master_id"), 0L),
    rating = dplyr::na_if(int(items, "rating"), 0L),
    date_added = as_datetime(chr(items, "date_added"))
  )
}
