#' Check the rate limit
#'
#' Asks 'Discogs' how many requests are left in the current window. The
#' check is a request itself and counts towards the limit.
#'
#' 'Discogs' allows 60 requests a minute with a token and 25 without. Its
#' documentation describes a moving average over a 60 second window. In
#' tests made for tidycrates, the count followed clock minutes and was
#'
#' ```
#' current + previous * (1 - seconds / 60)
#' ```
#'
#' where `current` is the number of requests so far in this clock minute,
#' `previous` the number in the minute before, and `seconds` the time since
#' this minute began. Requests of one minute therefore fade out over the
#' next, and a burst counts for up to two minutes. Refused requests were
#' counted too.
#'
#' tidycrates keeps the same count of its own requests. A request is sent
#' at once while the count is 58 or less with a token, or 23 or less
#' without, so up to 59 or 24 requests go out in a minute. Later requests
#' wait until the count has room again, and no longer. If the response
#' headers give another limit, the count may reach two below it. If
#' 'Discogs' reports a higher count, for example because other
#' applications use the same token, the difference is added. Requests are
#' retried after HTTP 429 and 503 responses. A message says how long each
#' wait of a second or more takes; when several items are fetched, the
#' progress bar counts the wait down instead and its ETA includes the
#' waits still to come. The limit only needs checking when
#' other applications share the same token or IP address.
#'
#' The count uses the clock of your computer. A clock that is off by a
#' second changes it by about one request, which the margin of two covers.
#' A larger error can lead to refused requests until the count reported by
#' 'Discogs' corrects it.
#'
#' @section Why tidycrates throttles requests itself:
#' httr2 has a throttle of its own, [httr2::req_throttle()], but it cannot
#' follow the count of 'Discogs'. Its bucket allows a burst and then
#' refills at a steady rate, and it does not know that a burst counts for
#' up to two minutes. A bucket that allows a full minute of requests at
#' once sends more requests than 'Discogs' allows. They are refused, still
#' counted, and retried after waits of 10 seconds or more, so long batches
#' slow down and can fail. A bucket small enough to stay within the limit
#' either spaces all requests evenly, so every small batch waits about a
#' second for each request, or refills more slowly, so long batches take
#' up to twice as long.
#'
#' Keeping the same count as 'Discogs' avoids both problems. Requests go
#' out at once whenever 'Discogs' has room, wait only as long as needed
#' when it has none, and are not refused. In a simulation with 0.4 seconds
#' for each request, 46 requests took about 18 seconds this way and about
#' 46 seconds with even spacing, and 300 requests took about as long with
#' both.
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
