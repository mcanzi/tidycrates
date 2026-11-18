#' List the collection of a user
#'
#' Lists the releases in the collection of a 'Discogs' user. Anyone can
#' read a public collection. A private collection can only be read with
#' the token of its owner, see [dig_auth()]. Without a username, the
#' collection of the token owner is listed.
#'
#' A release that is in the collection more than once has one row per
#' copy, each with its own `instance_id`. Collections are never cached, so
#' changes show up at once.
#'
#' The media and sleeve conditions come from the collection fields named
#' Media and Sleeve. If any copy has a value in a field, the fields are
#' matched by name with one more request. Other fields, such as Notes, are
#' left out. Without the token of the owner, only public fields can be
#' read, and the conditions are `NA` for fields that are private. If the
#' fields cannot be read, a message says so and the conditions are `NA`.
#'
#' @section Restricted Data:
#' Collections, wantlists, usernames and marketplace data, such as prices
#' and collection values, are Restricted Data under the 'Discogs' API Terms
#' of Use. 'Discogs' grants each user a limited, personal licence to access
#' and use them with their own token. They may not be passed on to anyone
#' else or used for commercial purposes, and their use must respect the
#' privacy of their owners. Keep them, and tallies and plots of them, for
#' your own use, and do not publish them. The Terms of Use also forbid
#' using the API to get around the 'Discogs' marketplace.
#'
#' @inheritParams dig_artist_releases
#' @param username A 'Discogs' username, or `NULL` for the owner of the
#'   token set with [dig_auth()]. Finding the owner takes one request,
#'   once per session.
#' @param folder The ID of a collection folder, see
#'   [dig_collection_folders()]. The default, `0`, holds the whole
#'   collection and is the only folder other users can read.
#' @param sort The column to sort by: `"added"`, `"artist"`, `"title"`,
#'   `"label"`, `"catno"`, `"format"`, `"rating"` or `"year"`.
#'
#' @return A tibble with one row per copy of a release, or `NULL`
#'   invisibly if the API cannot be reached. The columns are `release_id`,
#'   `instance_id`, `folder_id`, `title`, `artist`, `year`, `label`,
#'   `catno`, `format`, `media_condition`, `sleeve_condition`, `genres` and
#'   `styles` as list columns, `master_id`, `rating` and `date_added`.
#'   `rating` is `NA` if the user gave none. The conditions are factors
#'   from best to worst, with the same grades as [dig_price_suggestions()].
#'   The sleeve condition can also be `"Generic"` or `"No Cover"`, and a
#'   condition is `NA` if the user gave none.
#'
#' @examplesIf interactive()
#' collection <- dig_collection("username", all = TRUE)
#' dplyr::count(collection, format, sort = TRUE)
#' dplyr::count(collection, media_condition)
#'
#' @export
dig_collection <- function(username = NULL, folder = 0,
                           sort = c("added", "artist", "title", "label", "catno", "format", "rating", "year"),
                           order = c("asc", "desc"), all = FALSE, page = 1,
                           per_page = 50) {
  if (!rlang::is_scalar_integerish(folder, finite = TRUE) || folder < 0) {
    cli::cli_abort("{.arg folder} must be a whole number from 0.")
  }
  sort <- rlang::arg_match(sort)
  order <- rlang::arg_match(order)
  check_page(page, per_page, all)
  username <- check_username(username)
  if (is.null(username)) {
    return(invisible(NULL))
  }
  items <- dig_get_pages(
    user_path(username, "/collection/folders/", format(folder, scientific = FALSE), "/releases"),
    "releases",
    query = list(sort = sort, sort_order = order),
    all = all, page = page, per_page = per_page, cache = FALSE
  )
  if (is.null(items)) {
    return(invisible(NULL))
  }
  fields <- condition_fields(username, items)
  if (is.null(fields)) {
    return(invisible(NULL))
  }
  basic_tibble(items) |>
    tibble::add_column(
      instance_id = int(items, "instance_id"),
      folder_id = int(items, "folder_id"),
      .after = "release_id"
    ) |>
    tibble::add_column(
      media_condition = grade(field_values(items, fields$media), conditions),
      sleeve_condition = grade(field_values(items, fields$sleeve), c(conditions, "Generic", "No Cover")),
      .after = "format"
    )
}

condition_fields <- function(username, items, call = rlang::caller_env()) {
  noted <- purrr::some(items, \(i) length(as_items(pluck_list(i, "notes"))) > 0)
  if (!noted) {
    return(list(media = integer(), sleeve = integer()))
  }
  body <- tryCatch(
    dig_get(user_path(username, "/collection/fields"), cache = FALSE, call = call),
    tidycrates_http_error = \(e) {
      cli::cli_inform(c("The collection fields could not be read, so the conditions are {.val {NA}}.", i = "{e$message}"))
      list()
    }
  )
  if (is.null(body)) {
    return(NULL)
  }
  fields <- as_items(pluck_list(body, "fields"))
  names <- stringr::str_to_lower(stringr::str_squish(chr(fields, "name")))
  dropdown <- chr(fields, "type") %in% c("dropdown", NA)
  find <- \(name) {
    ids <- int(fields, "id")[dropdown & names %in% c(name, paste(name, "condition"))]
    ids[!is.na(ids)]
  }
  list(media = find("media"), sleeve = find("sleeve"))
}

field_values <- function(items, ids) {
  purrr::map_chr(items, \(i) {
    notes <- as_items(pluck_list(i, "notes"))
    values <- stringr::str_squish(chr(notes, "value"))[int(notes, "field_id") %in% ids]
    values[!is.na(values) & values != ""][1]
  })
}

grade <- function(x, levels) {
  factor(x, levels = c(levels, sort(setdiff(x[!is.na(x)], levels))))
}

#' List the wantlist of a user
#'
#' Lists the releases in the wantlist of a 'Discogs' user. Anyone can read
#' a public wantlist. A private wantlist can only be read with the token of
#' its owner, see [dig_auth()]. Without a username, the wantlist of the
#' token owner is listed. Wantlists are never cached, so changes show up
#' at once.
#'
#' The notes that a user writes for each release are left out, because
#' they can be personal.
#'
#' @inheritSection dig_collection Restricted Data
#' @inheritParams dig_collection
#'
#' @return A tibble with one row per release, or `NULL` invisibly if the
#'   API cannot be reached. The columns are `release_id`, `title`,
#'   `artist`, `year`, `label`, `catno`, `format`, `genres` and `styles` as
#'   list columns, `master_id`, `rating` and `date_added`. `rating` is `NA`
#'   if the user gave none.
#'
#' @examplesIf interactive()
#' dig_wantlist("username", all = TRUE)
#'
#' @export
dig_wantlist <- function(username = NULL,
                         sort = c("added", "artist", "title", "label", "catno", "format", "rating", "year"),
                         order = c("asc", "desc"), all = FALSE, page = 1,
                         per_page = 50) {
  sort <- rlang::arg_match(sort)
  order <- rlang::arg_match(order)
  check_page(page, per_page, all)
  username <- check_username(username)
  if (is.null(username)) {
    return(invisible(NULL))
  }
  items <- dig_get_pages(
    user_path(username, "/wants"), "wants",
    query = list(sort = sort, sort_order = order),
    all = all, page = page, per_page = per_page, cache = FALSE
  )
  if (is.null(items)) {
    return(invisible(NULL))
  }
  basic_tibble(items)
}

#' List the collection folders of a user
#'
#' Lists the folders of a 'Discogs' collection, with the number of
#' releases in each. Folder `0` holds the whole collection and folder `1`
#' holds the releases that are in no other folder. Other users can only
#' see folder `0`, unless the collection is read with the token of its
#' owner, see [dig_auth()]. Folders are never cached.
#'
#' @inheritSection dig_collection Restricted Data
#' @inheritParams dig_collection
#'
#' @return A tibble with one row per folder and the columns `folder_id`,
#'   `name` and `count`, or `NULL` invisibly if the API cannot be reached.
#'   `folder_id` can be passed to [dig_collection()].
#'
#' @examplesIf interactive()
#' dig_collection_folders("username")
#'
#' @export
dig_collection_folders <- function(username = NULL) {
  username <- check_username(username)
  if (is.null(username)) {
    return(invisible(NULL))
  }
  body <- dig_get(user_path(username, "/collection/folders"), cache = FALSE)
  if (is.null(body)) {
    return(invisible(NULL))
  }
  folders <- as_items(pluck_list(body, "folders"))
  tibble::tibble(
    folder_id = int(folders, "id"),
    name = chr(folders, "name"),
    count = int(folders, "count")
  )
}

check_username <- function(x, arg = rlang::caller_arg(x), call = rlang::caller_env()) {
  if (is.null(x)) {
    return(token_username(arg, call))
  }
  if (!rlang::is_string(x) || is.na(x) || !nzchar(stringr::str_trim(x))) {
    cli::cli_abort("{.arg {arg}} must be a single username or `NULL`.", call = call)
  }
  x <- stringr::str_trim(x)
  if (stringr::str_detect(x, "^\\.+$|[[:cntrl:]]")) {
    cli::cli_abort("{.arg {arg}} is not a valid username.", call = call)
  }
  x
}

token_username <- function(arg, call) {
  token <- auth_token(call)
  if (is.null(token)) {
    cli::cli_abort(
      c(
        "{.arg {arg}} is needed when no token is set.",
        i = "Give a username, or set your token with {.fn dig_auth} to use your own."
      ),
      call = call
    )
  }
  key <- rlang::hash(token)
  if (identical(dig_env$identity$key, key)) {
    return(dig_env$identity$username)
  }
  body <- dig_get("oauth/identity", cache = FALSE, call = call)
  if (is.null(body)) {
    return(NULL)
  }
  username <- chr(list(body), "username")
  if (is.na(username)) {
    cli::cli_abort("'Discogs' did not return the username of the token owner.", call = call)
  }
  dig_env$identity <- list(key = key, username = username)
  username
}

user_path <- function(username, ...) {
  paste0("users/", utils::URLencode(username, reserved = TRUE), ...)
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
