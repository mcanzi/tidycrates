#' Get releases
#'
#' Gets releases from the 'Discogs' database. A release is one particular
#' edition of a recording, such as the 1987 UK 7" single of a song.
#'
#' The tracklist, credits, formats, identifiers and companies are kept as
#' list columns of tibbles. [dig_tracklist()], [dig_credits()],
#' [dig_formats()], [dig_identifiers()] and [dig_companies()] turn them
#' into one row per item.
#'
#' Images are left out, because the people who upload them can hold their
#' own copyright. Prices are left out too, because they change quickly and
#' this function can be cached. [dig_price_stats()] gets them. The `uri`
#' column links to the release on the 'Discogs' website.
#'
#' @param id One or more release IDs, as numbers or as codes copied from
#'   'Discogs' such as `"r249504"` or `"[r249504]"`.
#'
#' @return A tibble with one row per release, or `NULL` invisibly if the
#'   API cannot be reached. Several labels, catalogue numbers or formats are
#'   separated by semicolons in `label`, `catno` and `format`. `genres` and
#'   `styles` are list columns of character vectors. `have` and `want` give
#'   the number of users with the release in their collection or wantlist.
#'   The tracklist, credits, formats, identifiers and companies are list
#'   columns of tibbles.
#'
#' @seealso [dig_master()] and [dig_master_versions()] for other versions of
#'   a release.
#'
#' @examplesIf interactive()
#' dig_release(249504)
#'
#' @export
dig_release <- function(id) {
  ids <- check_ids(id, "r")
  out <- fetch_rows(ids, "releases", \(body, id) parse_release(body))
  if (is.null(out)) invisible(NULL) else out
}

parse_release <- function(body) {
  body <- list(body)
  labels <- as_items(pluck_list(body[[1]], "labels"))
  formats <- as_items(pluck_list(body[[1]], "formats"))
  tibble::tibble(
    release_id = int(body, "id"),
    title = chr(body, "title"),
    artist = artist_names(pluck_list(body[[1]], "artists")),
    year = as_year(int(body, "year")),
    released = as_released(chr(body, "released")),
    country = chr(body, "country"),
    label = paste_unique(chr(labels, "name")),
    catno = paste_unique(chr(labels, "catno")),
    format = paste_unique(chr(formats, "name")),
    genres = strings(pluck_list(body[[1]], "genres")),
    styles = strings(pluck_list(body[[1]], "styles")),
    master_id = int(body, "master_id"),
    status = chr(body, "status"),
    data_quality = chr(body, "data_quality"),
    notes = chr(body, "notes"),
    have = int(body, "community", "have"),
    want = int(body, "community", "want"),
    rating_average = num(body, "community", "rating", "average"),
    rating_count = int(body, "community", "rating", "count"),
    date_added = as_datetime(chr(body, "date_added")),
    date_changed = as_datetime(chr(body, "date_changed")),
    uri = chr(body, "uri"),
    tracklist = list(tracklist_tibble(pluck_list(body[[1]], "tracklist"))),
    credits = list(credits_tibble(body[[1]])),
    formats = list(formats_tibble(formats)),
    identifiers = list(identifiers_tibble(pluck_list(body[[1]], "identifiers"))),
    companies = list(companies_tibble(body[[1]]))
  )
}

#' Get master releases
#'
#' Gets master releases from the 'Discogs' database. A master release
#' groups all versions of a release, such as the original pressing, later
#' reissues and editions in other countries.
#'
#' Images are left out, because the people who upload them can hold their
#' own copyright. [dig_master_versions()] lists the versions.
#'
#' @param id One or more master release IDs, as numbers or as codes copied
#'   from 'Discogs' such as `"m96559"` or `"[m96559]"`.
#'
#' @return A tibble with one row per master release, or `NULL` invisibly if
#'   the API cannot be reached. The columns are `master_id`, `title`,
#'   `artist`, `year`, `genres`, `styles`, `main_release`,
#'   `most_recent_release`, `data_quality`, `uri` and `tracklist`, a list
#'   column of tibbles that [dig_tracklist()] unnests.
#'
#' @examplesIf interactive()
#' dig_master(96559)
#'
#' @export
dig_master <- function(id) {
  ids <- check_ids(id, "m")
  out <- fetch_rows(ids, "masters", \(body, id) parse_master(body))
  if (is.null(out)) invisible(NULL) else out
}

parse_master <- function(body) {
  body <- list(body)
  tibble::tibble(
    master_id = int(body, "id"),
    title = chr(body, "title"),
    artist = artist_names(pluck_list(body[[1]], "artists")),
    year = as_year(int(body, "year")),
    genres = strings(pluck_list(body[[1]], "genres")),
    styles = strings(pluck_list(body[[1]], "styles")),
    main_release = int(body, "main_release"),
    most_recent_release = int(body, "most_recent_release"),
    data_quality = chr(body, "data_quality"),
    uri = chr(body, "uri"),
    tracklist = list(tracklist_tibble(pluck_list(body[[1]], "tracklist")))
  )
}

#' Get artists
#'
#' Gets artists from the 'Discogs' database. Names that several artists
#' share are told apart by a number in brackets, for example
#' `"Persuader (2)"`.
#'
#' Profiles keep the 'Discogs' markup for links, such as `[a=Carl Craig]`.
#' Images are left out, because the people who upload them can hold their
#' own copyright. [dig_artist_releases()] lists the releases of an artist.
#'
#' @param id One or more artist IDs, as numbers or as codes copied from
#'   'Discogs' such as `"a1"` or `"[a1]"`.
#'
#' @return A tibble with one row per artist, or `NULL` invisibly if the API
#'   cannot be reached. The columns are `artist_id`, `name`, `real_name`,
#'   `profile`, `data_quality`, `uri`, `urls` and `name_variations` as list
#'   columns of character vectors, and `aliases`, `members` and `groups` as
#'   list columns of tibbles.
#'
#' @examplesIf interactive()
#' dig_artist(1)
#'
#' @export
dig_artist <- function(id) {
  ids <- check_ids(id, "a")
  out <- fetch_rows(ids, "artists", \(body, id) parse_artist(body))
  if (is.null(out)) invisible(NULL) else out
}

parse_artist <- function(body) {
  body <- list(body)
  tibble::tibble(
    artist_id = int(body, "id"),
    name = chr(body, "name"),
    real_name = chr(body, "realname"),
    profile = chr(body, "profile"),
    data_quality = chr(body, "data_quality"),
    uri = chr(body, "uri"),
    urls = strings(pluck_list(body[[1]], "urls")),
    name_variations = strings(pluck_list(body[[1]], "namevariations")),
    aliases = list(people_tibble(pluck_list(body[[1]], "aliases"))),
    members = list(people_tibble(pluck_list(body[[1]], "members"))),
    groups = list(people_tibble(pluck_list(body[[1]], "groups")))
  )
}

people_tibble <- function(items) {
  items <- as_items(items)
  tibble::tibble(
    artist_id = int(items, "id"),
    name = chr(items, "name"),
    active = lgl(items, "active")
  )
}

#' Get labels
#'
#' Gets record labels and other companies, such as pressing plants and
#' studios, from the 'Discogs' database.
#'
#' Profiles keep the 'Discogs' markup for links. Images are left out,
#' because the people who upload them can hold their own copyright.
#' [dig_label_releases()] lists the releases of a label.
#'
#' @param id One or more label IDs, as numbers or as codes copied from
#'   'Discogs' such as `"l1"` or `"[l1]"`.
#'
#' @return A tibble with one row per label, or `NULL` invisibly if the API
#'   cannot be reached. The columns are `label_id`, `name`, `profile`,
#'   `contact_info`, `parent_label`, `parent_label_id`, `data_quality`,
#'   `uri`, `urls` as a list column of character vectors, and `sublabels`
#'   as a list column of tibbles.
#'
#' @examplesIf interactive()
#' dig_label(1)
#'
#' @export
dig_label <- function(id) {
  ids <- check_ids(id, "l")
  out <- fetch_rows(ids, "labels", \(body, id) parse_label(body))
  if (is.null(out)) invisible(NULL) else out
}

parse_label <- function(body) {
  body <- list(body)
  sublabels <- as_items(pluck_list(body[[1]], "sublabels"))
  tibble::tibble(
    label_id = int(body, "id"),
    name = chr(body, "name"),
    profile = chr(body, "profile"),
    contact_info = chr(body, "contact_info"),
    parent_label = chr(body, "parent_label", "name"),
    parent_label_id = int(body, "parent_label", "id"),
    data_quality = chr(body, "data_quality"),
    uri = chr(body, "uri"),
    urls = strings(pluck_list(body[[1]], "urls")),
    sublabels = list(tibble::tibble(label_id = int(sublabels, "id"), name = chr(sublabels, "name")))
  )
}
