#' Check the rate limit
#'
#' Asks 'Discogs' how many requests are left in the current window. The
#' check is a request itself and counts towards the limit.
#'
#' 'Discogs' allows 60 requests a minute with a token and 25 without,
#' counted over a moving window of 60 seconds. Requests made by
#' tidycrates are spaced out to stay within the limit and retried after
#' HTTP 429 responses, so the limit only needs checking when other
#' applications share the same token or IP address.
#'
#' @return A tibble with one row and the columns `limit`, `used`,
#'   `remaining` and `authenticated`, or `NULL` invisibly if the API cannot
#'   be reached.
#'
#' @examplesIf interactive()
#' dig_rate_limit()
#'
#' @export
dig_rate_limit <- function() {
  dig_env$rate_limit <- NULL
  if (is.null(dig_get("", cache = FALSE))) {
    return(invisible(NULL))
  }
  dig_env$rate_limit
}

store_rate_limit <- function(resp, token) {
  header <- \(name) as_int(httr2::resp_header(resp, paste0("x-discogs-ratelimit", name)))
  if (is.na(header(""))) {
    return(invisible())
  }
  dig_env$rate_limit <- tibble::tibble(
    limit = header(""),
    used = header("-used"),
    remaining = header("-remaining"),
    authenticated = !is.null(token)
  )
  invisible()
}
