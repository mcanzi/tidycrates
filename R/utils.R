#' @importFrom rlang %||% .data
NULL

check_string <- function(x, arg = rlang::caller_arg(x), call = rlang::caller_env()) {
  if (!rlang::is_string(x) || is.na(x)) {
    cli::cli_abort("{.arg {arg}} must be a single string.", call = call)
  }
  invisible(x)
}

check_ids <- function(x, prefix, arg = rlang::caller_arg(x), call = rlang::caller_env()) {
  code <- stringr::regex(paste0("^\\s*(\\[", prefix, "[0-9]+\\]|", prefix, "?[0-9]+)\\s*$"), ignore_case = TRUE)
  typed <- is.numeric(x) || (is.character(x) && all(stringr::str_detect(x, code), na.rm = TRUE))
  if (!typed && is.character(x)) {
    check_code_type(x, prefix, arg, call)
  }
  if (typed && is.character(x)) {
    x <- stringr::str_remove_all(x, "[^0-9]")
  }
  ids <- if (typed) suppressWarnings(as.numeric(x)) else NA_real_
  valid <- typed && length(x) > 0 && !anyNA(ids) &&
    all(ids >= 1 & ids <= .Machine$integer.max & ids == trunc(ids))
  if (!valid) {
    cli::cli_abort(
      "{.arg {arg}} must contain positive whole numbers or codes such as {.code [{prefix}1]}.",
      call = call
    )
  }
  format(ids, scientific = FALSE, trim = TRUE)
}

check_code_type <- function(x, prefix, arg, call) {
  types <- c(r = "release", m = "master release", a = "artist", l = "label")
  articles <- c(r = "a", m = "a", a = "an", l = "a")
  fns <- c(r = "dig_release", m = "dig_master", a = "dig_artist", l = "dig_label")
  found <- x |>
    stringr::str_match(stringr::regex("^\\s*(\\[([rmal])[0-9]+\\]|([rmal])[0-9]+)\\s*$", ignore_case = TRUE))
  kinds <- stringr::str_to_lower(dplyr::coalesce(found[, 3], found[, 4]))
  wrong <- which(!is.na(kinds) & kinds != prefix)[1]
  if (is.na(wrong)) {
    return(invisible())
  }
  code <- stringr::str_trim(x[[wrong]])
  given <- types[[kinds[[wrong]]]]
  article <- articles[[kinds[[wrong]]]]
  fn <- fns[[kinds[[wrong]]]]
  cli::cli_abort(
    c(
      "{.arg {arg}} must contain {types[[prefix]]} IDs, but {.val {code}} is {article} {given} code.",
      i = "Use {.fn {fn}} for {given}s."
    ),
    call = call
  )
}

check_id <- function(x, prefix, arg = rlang::caller_arg(x), call = rlang::caller_env()) {
  if (length(x) != 1) {
    cli::cli_abort("{.arg {arg}} must be a single ID.", call = call)
  }
  check_ids(x, prefix, arg, call)
}

check_flag <- function(x, arg = rlang::caller_arg(x), call = rlang::caller_env()) {
  if (!rlang::is_bool(x)) {
    cli::cli_abort("{.arg {arg}} must be `TRUE` or `FALSE`.", call = call)
  }
  invisible(x)
}

check_page <- function(page, per_page, all, call = rlang::caller_env()) {
  check_flag(all, call = call)
  whole <- \(x) rlang::is_scalar_integerish(x, finite = TRUE) && x >= 1
  if (!whole(page)) {
    cli::cli_abort("{.arg page} must be a positive whole number.", call = call)
  }
  if (!whole(per_page) || per_page > 100) {
    cli::cli_abort("{.arg per_page} must be a whole number from 1 to 100.", call = call)
  }
  invisible()
}

check_filter <- function(x, arg = rlang::caller_arg(x), call = rlang::caller_env()) {
  valid <- is.null(x) || (is.character(x) && length(x) == 1 && !is.na(x) && nzchar(stringr::str_trim(x))) ||
    (is.numeric(x) && length(x) == 1 && is.finite(x))
  if (!valid) {
    cli::cli_abort("{.arg {arg}} must be a single value or `NULL`.", call = call)
  }
  invisible(x)
}

fetch_each <- function(ids, path, parse, call = rlang::caller_env()) {
  unique_ids <- unique(ids)
  bodies <- map_requests(
    unique_ids,
    \(id) dig_get(paste0(path, "/", id), call = call),
    .progress = if (length(unique_ids) > 1) "Fetching" else FALSE
  )
  if (any(purrr::map_lgl(bodies, is.null))) {
    return(NULL)
  }
  rows <- bodies |>
    purrr::map(parse) |>
    dplyr::bind_rows()
  rows[match(ids, unique_ids), ]
}

map_requests <- function(.x, .f, .progress = FALSE) {
  tryCatch(
    purrr::map(.x, .f, .progress = .progress),
    purrr_error_indexed = \(e) rlang::cnd_signal(e$parent)
  )
}

as_items <- function(x) {
  if (!is.list(x)) {
    return(list())
  }
  if (any(nzchar(names(x) %||% ""))) {
    x <- list(x)
  }
  unname(purrr::keep(x, is.list))
}

clean <- function(x) {
  if (is.list(x)) {
    x <- unlist(x, use.names = FALSE)
  }
  if (!is.atomic(x)) {
    return(NULL)
  }
  x <- x[!is.na(x) & x != ""]
  if (length(x) == 0) NULL else x
}

as_chr <- function(x) {
  x <- clean(x)
  if (is.null(x)) NA_character_ else paste(x, collapse = ", ")
}

as_int <- function(x) {
  x <- clean(x)
  if (is.null(x)) NA_integer_ else suppressWarnings(as.integer(x[[1]]))
}

as_num <- function(x) {
  x <- clean(x)
  if (is.null(x)) NA_real_ else suppressWarnings(as.numeric(x[[1]]))
}

as_lgl <- function(x) {
  x <- clean(x)
  if (is.null(x)) NA else as.logical(x[[1]])
}

pluck_list <- function(x, ...) {
  if (is.list(x)) purrr::pluck(x, ...) else NULL
}

chr <- function(items, ...) {
  purrr::map_chr(items, \(i) as_chr(pluck_list(i, ...)))
}

int <- function(items, ...) {
  purrr::map_int(items, \(i) as_int(pluck_list(i, ...)))
}

num <- function(items, ...) {
  purrr::map_dbl(items, \(i) as_num(pluck_list(i, ...)))
}

lgl <- function(items, ...) {
  purrr::map_lgl(items, \(i) as_lgl(pluck_list(i, ...)))
}

strings <- function(x) {
  list(as.character(clean(x) %||% character()))
}

paste_unique <- function(x, sep = "; ") {
  x <- unique(x[!is.na(x) & x != ""])
  if (length(x) == 0) NA_character_ else paste(x, collapse = sep)
}

as_year <- function(x) {
  x <- as.integer(x)
  dplyr::if_else(x == 0L, NA_integer_, x)
}

as_released <- function(x) {
  dplyr::if_else(x %in% c("0", "0000", "0000-00-00"), NA_character_, x)
}

as_datetime <- function(x) {
  x |>
    stringr::str_replace("\\.[0-9]+", "") |>
    stringr::str_replace("Z$", "+0000") |>
    stringr::str_replace("([+-][0-9]{2}):([0-9]{2})$", "\\1\\2") |>
    as.POSIXct(format = "%Y-%m-%dT%H:%M:%S%z", tz = "UTC")
}

as_seconds <- function(x) {
  purrr::map_int(x, \(d) {
    d <- stringr::str_trim(d)
    if (is.na(d) || !stringr::str_detect(d, "^[0-9]{1,4}(:[0-5]?[0-9]){1,2}$")) {
      return(NA_integer_)
    }
    parts <- as.numeric(stringr::str_split_1(d, ":"))
    as.integer(sum(parts * 60^rev(seq_along(parts) - 1)))
  })
}

artist_names <- function(artists) {
  artists <- as_items(artists)
  names <- dplyr::coalesce(chr(artists, "anv"), chr(artists, "name"))
  joins <- stringr::str_trim(dplyr::coalesce(chr(artists, "join"), ""))[!is.na(names)]
  names <- names[!is.na(names)]
  if (length(names) == 0) {
    return(NA_character_)
  }
  joins <- dplyr::case_when(
    joins == "" ~ " ",
    joins == "," ~ ", ",
    .default = paste0(" ", joins, " ")
  )
  joins[length(joins)] <- ""
  paste0(names, joins, collapse = "") |> stringr::str_squish()
}
