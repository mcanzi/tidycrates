#' Search the 'Discogs' database
#'
#' Searches the releases, master releases, artists and labels in the
#' 'Discogs' database. Search needs a token, see [dig_auth()], but the token
#' can belong to any user.
#'
#' Give a search query, one or more filters, or both. Each filter searches
#' one field, so `artist = "Juniper Static"` finds releases by that artist
#' but not releases that only mention the name in their title. The IDs in
#' `id` can be passed to [dig_release()], [dig_master()], [dig_artist()] or
#' [dig_label()], depending on `type`.
#'
#' 'Discogs' returns up to 100 results per page. With `all = TRUE`, every
#' page is fetched, which takes one request for each 100 results.
#'
#' @inheritParams dig_artist_releases
#' @param query The search query, or `NULL` to search with filters only.
#' @param type The type of result: `"release"`, `"master"`, `"artist"` or
#'   `"label"`, or `NULL` for all types.
#' @param title The combined title, as in `"Juniper Static - Lantern Weather"`.
#' @param release_title The title of the release.
#' @param credit A name in the credits.
#' @param artist The name of the artist.
#' @param anv The name the artist is credited as on the release.
#' @param label,genre,style,country,year,format,catno,barcode Values to
#'   filter the results by, for example `format = "Vinyl"` or
#'   `year = 1994`.
#' @param track The title of a track.
#' @param sort The column to sort by: `"score"`, the relevance to the query,
#'   `"title"`, `"have"`, `"want"`, `"hot"`, `"date_added"`,
#'   `"date_changed"` or `"year"`.
#'
#' @return A tibble with one row per result, or `NULL` invisibly if the API
#'   cannot be reached. `type` tells releases, master releases, artists and
#'   labels apart, and `id` is the ID of either. `title` combines the artist
#'   and the title, and for artists and labels it is the name. `genres` and
#'   `styles` are list columns. `have` and `want` are the numbers of users
#'   with the item in their collection or wantlist. Columns that do not
#'   apply to a type, such as `catno` for artists, are `NA`.
#'
#' @examplesIf interactive()
#' dig_search("Lantern Weather", type = "release")
#' dig_search(artist = "Juniper Static", format = "Vinyl", year = 1994)
#'
#' @export
dig_search <- function(query = NULL, type = NULL, title = NULL, release_title = NULL,
                       credit = NULL, artist = NULL, anv = NULL, label = NULL, genre = NULL,
                       style = NULL, country = NULL, year = NULL, format = NULL, catno = NULL,
                       barcode = NULL, track = NULL,
                       sort = c("score", "title", "have", "want", "hot", "date_added", "date_changed", "year"),
                       order = c("desc", "asc"), all = FALSE, page = 1, per_page = 50) {
  if (!is.null(type)) {
    type <- rlang::arg_match(type, c("release", "master", "artist", "label"))
  }
  sort <- rlang::arg_match(sort)
  order <- rlang::arg_match(order)
  check_page(page, per_page, all)
  env <- rlang::current_env()
  filters <- list(
    query = query, title = title, release_title = release_title, credit = credit,
    artist = artist, anv = anv, label = label, genre = genre, style = style,
    country = country, year = year, format = format, catno = catno,
    barcode = barcode, track = track
  )
  purrr::iwalk(filters, \(x, name) check_filter(x, arg = name, call = env))
  filters <- purrr::compact(filters)
  if (length(filters) == 0) {
    cli::cli_abort("Give a search {.arg query}, a filter or both.")
  }
  check_token()
  names(filters)[names(filters) == "query"] <- "q"
  items <- dig_get_pages(
    "database/search", "results",
    query = c(filters, purrr::compact(list(type = type)), sort = sort, sort_order = order),
    all = all, page = page, per_page = per_page
  )
  if (is.null(items)) {
    return(invisible(NULL))
  }
  items <- as_items(items)
  uri <- chr(items, "uri")
  tibble::tibble(
    id = int(items, "id"),
    type = chr(items, "type"),
    title = chr(items, "title"),
    year = as_year(int(items, "year")),
    country = chr(items, "country"),
    label = purrr::map_chr(items, \(i) paste_unique(as.character(clean(pluck_list(i, "label"))))),
    catno = chr(items, "catno"),
    format = chr(items, "format"),
    barcode = purrr::map_chr(items, \(i) paste_unique(as.character(clean(pluck_list(i, "barcode"))))),
    genres = purrr::map(items, \(i) strings(pluck_list(i, "genre"))[[1]]),
    styles = purrr::map(items, \(i) strings(pluck_list(i, "style"))[[1]]),
    master_id = dplyr::na_if(int(items, "master_id"), 0L),
    have = int(items, "community", "have"),
    want = int(items, "community", "want"),
    uri = dplyr::if_else(stringr::str_starts(uri, "/"), paste0("https://www.discogs.com", uri), uri)
  )
}
