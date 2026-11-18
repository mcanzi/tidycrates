#' Get marketplace statistics
#'
#' Gets the lowest price and the number of copies for sale of releases in
#' the 'Discogs' marketplace. A token is not needed.
#'
#' Prices change quickly, so these requests are never cached. Without a
#' token and without `currency`, prices are in US dollars. With a token,
#' they are in the buyer currency of your account.
#'
#' @inheritSection dig_collection Restricted Data
#' @param id One or more release IDs, as numbers or as codes copied from
#'   'Discogs' such as `"r249504"` or `"[r249504]"`.
#' @param currency The currency of the prices, one of `"USD"`, `"GBP"`,
#'   `"EUR"`, `"CAD"`, `"AUD"`, `"JPY"`, `"CHF"`, `"MXN"`, `"BRL"`, `"NZD"`,
#'   `"SEK"` or `"ZAR"`, or `NULL` for the default.
#'
#' @return A tibble with one row per release, or `NULL` invisibly if the API
#'   cannot be reached. The columns are `release_id`, `lowest_price`,
#'   `currency`, `for_sale`, the number of copies for sale, and `blocked`,
#'   which is `TRUE` if the release may not be sold. `lowest_price` and
#'   `currency` are `NA` if no copy is for sale, and `for_sale` is `NA` if
#'   the release is blocked.
#'
#' @examplesIf interactive()
#' dig_price_stats(249504, currency = "EUR")
#'
#' @export
dig_price_stats <- function(id, currency = NULL) {
  ids <- check_ids(id, "r")
  currency <- check_currency(currency)
  out <- fetch_rows(
    ids, "marketplace/stats", parse_price_stats,
    query = purrr::compact(list(curr_abbr = currency)), cache = FALSE
  )
  if (is.null(out)) invisible(NULL) else out
}

#' Get price suggestions
#'
#' Gets the prices 'Discogs' suggests for releases in each condition, from
#' Mint to Poor. Price suggestions need a token, see [dig_auth()], and the
#' seller settings of the account must be filled in on 'Discogs'.
#'
#' The prices are in the selling currency of your account. They are never
#' cached, because they change quickly.
#'
#' @inheritSection dig_collection Restricted Data
#' @inheritParams dig_price_stats
#'
#' @return A tibble with one row per release and condition, or `NULL`
#'   invisibly if the API cannot be reached. The columns are `release_id`,
#'   `condition`, a factor from best to worst, `price` and `currency`. A
#'   release without suggestions has no rows.
#'
#' @examplesIf interactive()
#' dig_price_suggestions(249504)
#'
#' @export
dig_price_suggestions <- function(id) {
  ids <- check_ids(id, "r")
  check_token()
  out <- fetch_rows(ids, "marketplace/price_suggestions", parse_price_suggestions, cache = FALSE)
  if (is.null(out)) invisible(NULL) else out
}

#' Get the value of a collection
#'
#' Gets the minimum, median and maximum value of a collection, as
#' 'Discogs' estimates it from marketplace sales. Only the owner of a
#' collection can get its value, so this needs the owner's token, see
#' [dig_auth()]. Without a username, the value of the token owner's
#' collection is read.
#'
#' 'Discogs' returns the values as formatted text, such as `"$1,250.00"`.
#' They are turned into numbers, and the currency symbol is kept in
#' `currency`. The value is never cached.
#'
#' @inheritSection dig_collection Restricted Data
#' @inheritParams dig_collection
#'
#' @return A tibble with one row and the columns `username`, `minimum`,
#'   `median`, `maximum` and `currency`, or `NULL` invisibly if the API
#'   cannot be reached. A value that cannot be read is `NA`.
#'
#' @examplesIf interactive()
#' dig_collection_value()
#'
#' @export
dig_collection_value <- function(username = NULL) {
  check_token()
  name <- check_username(username)
  if (is.null(name)) {
    return(invisible(NULL))
  }
  body <- dig_get(user_path(name, "/collection/value"), cache = FALSE)
  if (is.null(body)) {
    return(invisible(NULL))
  }
  body <- list(if (is.list(body)) body else list())
  money <- parse_money(c(chr(body, "minimum"), chr(body, "median"), chr(body, "maximum")))
  tibble::tibble(
    username = name,
    minimum = money$value[1],
    median = money$value[2],
    maximum = money$value[3],
    currency = paste_unique(money$currency)
  )
}

currencies <- c("USD", "GBP", "EUR", "CAD", "AUD", "JPY", "CHF", "MXN", "BRL", "NZD", "SEK", "ZAR")

conditions <- c(
  "Mint (M)", "Near Mint (NM or M-)", "Very Good Plus (VG+)", "Very Good (VG)",
  "Good Plus (G+)", "Good (G)", "Fair (F)", "Poor (P)"
)

check_currency <- function(x, arg = rlang::caller_arg(x), call = rlang::caller_env()) {
  if (is.null(x)) {
    return(NULL)
  }
  code <- if (rlang::is_string(x) && !is.na(x)) stringr::str_to_upper(stringr::str_trim(x)) else NA_character_
  if (!code %in% currencies) {
    cli::cli_abort("{.arg {arg}} must be one of {.or {.val {currencies}}}, or `NULL`.", call = call)
  }
  code
}

check_token <- function(call = rlang::caller_env()) {
  if (is.null(auth_token())) {
    cli::cli_abort(
      c("This needs a personal access token.", i = "Set one with {.fn dig_auth}."),
      call = call
    )
  }
  invisible()
}

parse_price_stats <- function(body, id) {
  body <- list(if (is.list(body)) body else list())
  blocked <- lgl(body, "blocked_from_sale")
  for_sale <- int(body, "num_for_sale")
  tibble::tibble(
    release_id = id,
    lowest_price = num(body, "lowest_price", "value"),
    currency = chr(body, "lowest_price", "currency"),
    for_sale = dplyr::if_else(is.na(for_sale) & blocked %in% FALSE, 0L, for_sale),
    blocked = blocked
  )
}

parse_price_suggestions <- function(body, id) {
  items <- if (is.list(body) && !is.null(names(body))) body else list()
  items <- items[nzchar(names(items)) & purrr::map_lgl(items, is.list)]
  grades <- names(items) %||% character()
  out <- tibble::tibble(
    release_id = rep(id, length(items)),
    condition = factor(grades, levels = c(conditions, sort(setdiff(grades, conditions)))),
    price = unname(num(items, "value")),
    currency = unname(chr(items, "currency"))
  )
  dplyr::arrange(out, .data$condition)
}

parse_money <- function(x) {
  negative <- stringr::str_detect(x, "^\\s*[-\u2212]|[-\u2212]\\s*[0-9]") %in% TRUE
  x <- dplyr::if_else(negative, stringr::str_remove(x, "[-\u2212]"), x)
  number <- stringr::str_extract(x, "[0-9](?:[0-9.,'\\u2019\\s\u00a0]*[0-9])?")
  currency <- dplyr::if_else(
    is.na(number), NA_character_,
    stringr::str_squish(stringr::str_replace(x, stringr::fixed(dplyr::coalesce(number, "\u0001")), " "))
  )
  digits <- stringr::str_remove_all(number, "['\\u2019\\s\u00a0]")
  tail <- stringr::str_extract(digits, "(?<=[.,])[0-9]+$")
  both <- stringr::str_detect(digits, "\\.") & stringr::str_detect(digits, ",")
  decimal <- !is.na(tail) & (nchar(tail) <= 2 | both)
  whole <- dplyr::if_else(decimal, stringr::str_remove(digits, "[.,][0-9]+$"), digits)
  value <- paste0(stringr::str_remove_all(whole, "[.,]"), dplyr::if_else(decimal, paste0(".", tail), ""))
  list(
    value = suppressWarnings(as.numeric(dplyr::if_else(is.na(number), NA_character_, value))) *
      dplyr::if_else(negative, -1, 1),
    currency = dplyr::if_else(currency %in% "", NA_character_, currency)
  )
}
