#' List the releases of an artist
#'
#' Lists the releases and master releases an artist appears on, with the
#' role of the artist on each.
#'
#' 'Discogs' returns up to 100 items per page and sometimes fewer than
#' `per_page`. With `all = TRUE`, every page is fetched, which takes one
#' request for each 100 items. If this takes more than a minute, a message
#' gives the expected time.
#'
#' @param id An artist ID, as a number or as a code copied from 'Discogs'
#'   such as `"a1"` or `"[a1]"`.
#' @param sort The column to sort by: `"year"`, `"title"` or `"format"`.
#' @param order The sort order: `"asc"` or `"desc"`.
#' @param all If `TRUE`, all pages are fetched and `page` and `per_page`
#'   are ignored.
#' @param page The page to fetch.
#' @param per_page The number of items per page, from 1 to 100.
#'
#' @return A tibble with one row per release or master release, or `NULL`
#'   invisibly if the API cannot be reached. `type` tells releases and
#'   master releases apart, and `id` is the ID of either. `have` and `want`
#'   are the numbers of users with the item in their collection or
#'   wantlist.
#'
#' @examplesIf interactive()
#' dig_artist_releases(1, all = TRUE)
#'
#' @export
dig_artist_releases <- function(id, sort = c("year", "title", "format"),
                                order = c("asc", "desc"), all = FALSE,
                                page = 1, per_page = 50) {
  id <- check_id(id, "a")
  sort <- rlang::arg_match(sort)
  order <- rlang::arg_match(order)
  check_page(page, per_page, all)
  items <- dig_get_pages(
    paste0("artists/", id, "/releases"), "releases",
    query = list(sort = sort, sort_order = order),
    all = all, page = page, per_page = per_page
  )
  if (is.null(items)) {
    return(invisible(NULL))
  }
  items <- as_items(items)
  tibble::tibble(
    id = int(items, "id"),
    type = chr(items, "type"),
    title = chr(items, "title"),
    artist = chr(items, "artist"),
    role = chr(items, "role"),
    year = as_year(int(items, "year")),
    format = chr(items, "format"),
    label = chr(items, "label"),
    status = chr(items, "status"),
    main_release = int(items, "main_release"),
    have = int(items, "stats", "community", "in_collection"),
    want = int(items, "stats", "community", "in_wantlist")
  )
}

#' List the releases of a label
#'
#' Lists the releases of a label or other company.
#'
#' @inheritParams dig_artist_releases
#' @param id A label ID, as a number or as a code copied from 'Discogs'
#'   such as `"l1"` or `"[l1]"`.
#'
#' @return A tibble with one row per release, or `NULL` invisibly if the API
#'   cannot be reached.
#'
#' @examplesIf interactive()
#' dig_label_releases(1)
#'
#' @export
dig_label_releases <- function(id, all = FALSE, page = 1, per_page = 50) {
  id <- check_id(id, "l")
  check_page(page, per_page, all)
  items <- dig_get_pages(
    paste0("labels/", id, "/releases"), "releases",
    all = all, page = page, per_page = per_page
  )
  if (is.null(items)) {
    return(invisible(NULL))
  }
  items <- as_items(items)
  tibble::tibble(
    release_id = int(items, "id"),
    title = chr(items, "title"),
    artist = chr(items, "artist"),
    catno = chr(items, "catno"),
    format = chr(items, "format"),
    year = as_year(int(items, "year")),
    status = chr(items, "status")
  )
}

#' List the versions of a master release
#'
#' Lists the releases that belong to a master release, such as reissues
#' and editions in other countries. The versions can be filtered by
#' format, label, year and country.
#'
#' @inheritParams dig_artist_releases
#' @param id A master release ID, as a number or as a code copied from
#'   'Discogs' such as `"m96559"` or `"[m96559]"`.
#' @param format,label,released,country Values to filter the versions by,
#'   for example `format = "Vinyl"` or `released = 1997`.
#' @param sort The column to sort by: `"released"`, `"title"`, `"format"`,
#'   `"label"`, `"catno"` or `"country"`.
#'
#' @return A tibble with one row per version, or `NULL` invisibly if the API
#'   cannot be reached. `have` and `want` are the numbers of users with the
#'   version in their collection or wantlist.
#'
#' @examplesIf interactive()
#' dig_master_versions(1000, format = "CD")
#'
#' @export
dig_master_versions <- function(id, format = NULL, label = NULL, released = NULL,
                                country = NULL,
                                sort = c("released", "title", "format", "label", "catno", "country"),
                                order = c("asc", "desc"), all = FALSE, page = 1,
                                per_page = 50) {
  id <- check_id(id, "m")
  sort <- rlang::arg_match(sort)
  order <- rlang::arg_match(order)
  check_page(page, per_page, all)
  check_filter(format)
  check_filter(label)
  check_filter(released)
  check_filter(country)
  query <- list(
    format = format, label = label, released = released, country = country,
    sort = sort, sort_order = order
  )
  items <- dig_get_pages(
    paste0("masters/", id, "/versions"), "versions",
    query = purrr::compact(query), all = all, page = page, per_page = per_page
  )
  if (is.null(items)) {
    return(invisible(NULL))
  }
  items <- as_items(items)
  tibble::tibble(
    release_id = int(items, "id"),
    title = chr(items, "title"),
    label = chr(items, "label"),
    catno = chr(items, "catno"),
    country = chr(items, "country"),
    released = as_released(chr(items, "released")),
    format = chr(items, "format"),
    major_formats = chr(items, "major_formats"),
    status = chr(items, "status"),
    have = int(items, "stats", "community", "in_collection"),
    want = int(items, "stats", "community", "in_wantlist")
  )
}
