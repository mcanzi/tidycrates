base_url <- "https://api.discogs.com"

minute <- 60

request_cap <- function(token = auth_token()) {
  limit <- dig_env[[limit_key(token)]] %||% (if (is.null(token)) 25 else 60)
  limit - 2
}

dig_request <- function(path, query = list(), token = auth_token()) {
  req <- httr2::request(base_url) |>
    httr2::req_url_path_append(path) |>
    httr2::req_url_query(!!!query) |>
    httr2::req_user_agent(user_agent()) |>
    httr2::req_timeout(60) |>
    httr2::req_error(body = error_body)
  if (!is.null(token)) {
    req <- httr2::req_headers_redacted(req, Authorization = paste0("Discogs token=", token))
  }
  req
}

perform <- function(req, token, max_tries = 4) {
  for (attempt in seq_len(max_tries)) {
    wait_for_slot(token)
    before <- request_tally(logged_requests(token), now())
    resp <- tryCatch(httr2::req_perform(req), httr2_http = identity, finally = record_request(token))
    failed <- inherits(resp, "httr2_http")
    sync_tally(if (failed) resp$resp else resp, token, before)
    if (!failed) {
      return(resp)
    }
    status <- httr2::resp_status(resp$resp)
    if (attempt == max_tries || !status %in% c(429, 503)) {
      rlang::cnd_signal(resp)
    }
    seconds <- retry_wait(resp$resp, attempt)
    if (is.null(dig_env$progress) && seconds >= 1) {
      cli::cli_inform("Retrying in {ceiling(seconds)} second{?s} after HTTP {status}.")
    }
    hold(seconds, \(n) paste0("HTTP ", status, ", retry in ", n, "s"))
  }
}

wait_for_slot <- function(token) {
  seconds <- tally_wait(logged_requests(token), now(), request_cap(token))
  if (seconds == 0) {
    return(invisible())
  }
  if (is.null(dig_env$progress) && seconds >= 1) {
    cli::cli_inform("Waiting {ceiling(seconds)} second{?s} for the 'Discogs' rate limit.")
  }
  hold(seconds, \(n) paste0("rate limit wait ", n, "s"))
}

hold <- function(seconds, note) {
  bar <- dig_env$progress
  if (is.null(bar) || seconds <= 0) {
    return(pause(seconds))
  }
  n <- ceiling(seconds)
  steps <- c(seconds - n + 1, rep(1, n - 1))
  for (i in seq_len(n)) {
    left <- sum(steps[i:n])
    show_progress(bar, progress_status(bar, left, if (left >= 1) note(n - i + 1)))
    pause(steps[i])
    bar$waited <- bar$waited + steps[i]
  }
}

start_progress <- function(name, total, envir = parent.frame()) {
  bar <- rlang::env(
    total = total,
    done = 0,
    waited = 0,
    start = now(),
    token = tryCatch(auth_token(), error = \(e) NULL)
  )
  bar$id <- cli::cli_progress_bar(
    name,
    total = total,
    format = "{cli::pb_name}{cli::pb_bar} {cli::pb_current}/{cli::pb_total} | {cli::pb_extra$status}",
    extra = list(status = ""),
    .envir = envir
  )
  bar
}

tick_progress <- function() {
  bar <- dig_env$progress
  bar$done <- bar$done + 1
  show_progress(bar, progress_status(bar))
}

show_progress <- function(bar, status) {
  cli::cli_progress_update(id = bar$id, set = bar$done, extra = list(status = status))
}

progress_status <- function(bar, wait = 0, note = NULL) {
  latency <- if (bar$done > 0) max(0, now() - bar$start - bar$waited) / bar$done else 0
  at <- now() + wait
  seconds <- wait + predict_finish(logged_requests(bar$token), at, request_cap(bar$token), bar$total - bar$done, latency)
  paste(c(paste0("ETA: ", format_seconds(seconds)), note), collapse = ", ")
}

predict_finish <- function(times, at, cap, n, latency) {
  if (n <= 0) {
    return(0)
  }
  counts <- minute_counts(times, at)
  start <- counts$start
  previous <- counts$previous
  current <- counts$current
  ready <- at
  repeat {
    before <- seq(current, length.out = max(0, cap + 1 - current))
    gate <- if (previous > 0) start + minute * pmax(0, 1 - (cap - before) / previous) else rep(start, length(before))
    gate <- pmax(gate, ready)
    k <- seq_along(gate)
    sends <- k * latency + cummax(gate - k * latency)
    sends <- sends[sends < start + minute]
    if (length(sends) >= n) {
      return(sends[n] + latency - at)
    }
    n <- n - length(sends)
    if (length(sends) > 0) {
      ready <- sends[length(sends)] + latency
    }
    previous <- current + length(sends)
    current <- 0
    start <- start + minute
  }
}

format_seconds <- function(seconds) {
  seconds <- ceiling(seconds)
  if (seconds < minute) {
    return(paste0(seconds, "s"))
  }
  hours <- seconds %/% 3600
  mins <- seconds %% 3600 %/% minute
  secs <- seconds %% minute
  if (hours > 0) paste0(hours, "h ", mins, "m") else paste0(mins, "m ", secs, "s")
}

minute_counts <- function(times, at) {
  start <- minute * floor(at / minute)
  list(
    start = start,
    previous = sum(times >= start - minute & times < start),
    current = sum(times >= start & times <= at)
  )
}

request_tally <- function(times, at) {
  counts <- minute_counts(times, at)
  counts$previous * (1 - (at - counts$start) / minute) + counts$current
}

tally_wait <- function(times, at, cap) {
  if (request_tally(times, at) <= cap) {
    return(0)
  }
  counts <- minute_counts(times, at)
  next_minute <- counts$start + minute
  if (counts$current >= cap) {
    return(next_minute - at + tally_wait(times, next_minute, cap))
  }
  next_minute - minute * (cap - counts$current) / counts$previous - at
}

record_request <- function(token, n = 1) {
  dig_env[[log_key(token)]] <- c(logged_requests(token), rep(now(), n))
}

logged_requests <- function(token) {
  times <- dig_env[[log_key(token)]]
  times[times >= minute * floor(now() / minute) - minute]
}

sync_tally <- function(resp, token, before) {
  limit <- as_int(httr2::resp_header(resp, "x-discogs-ratelimit"))
  if (!is.na(limit) && limit > 2) {
    dig_env[[limit_key(token)]] <- limit
  }
  used <- as_int(httr2::resp_header(resp, "x-discogs-ratelimit-used"))
  missing <- if (is.na(used)) 0 else used - ceiling(before)
  if (missing > 0) {
    record_request(token, missing)
  }
}

log_key <- function(token) {
  if (is.null(token)) "requests" else "requests_token"
}

limit_key <- function(token) {
  paste0(log_key(token), "_limit")
}

now <- function() {
  as.numeric(Sys.time())
}

pause <- function(seconds) {
  if (seconds > 0) Sys.sleep(seconds)
}

retry_wait <- function(resp, attempt) {
  after <- httr2::resp_retry_after(resp)
  if (is.na(after)) retry_backoff(attempt) else after
}

retry_backoff <- function(attempt) {
  min(60, 5 * 2^attempt)
}

error_body <- function(resp) {
  message <- tryCatch(as_chr(read_json(resp)[["message"]]), error = \(e) NA_character_)
  if (is.na(message)) NULL else message
}

read_json <- function(resp) {
  httr2::resp_check_content_type(resp, "application/json", "+json")
  jsonlite::fromJSON(httr2::resp_body_string(resp), simplifyVector = FALSE)
}

fetch <- function(path, query = list(), token = auth_token()) {
  resp <- dig_request(path, query, token) |>
    perform(token) |>
    tryCatch(
      httr2_failure = \(e) unavailable("Could not reach the Discogs API. Check your internet connection.", e),
      httr2_http = \(e) {
        status <- httr2::resp_status(e$resp)
        if (status == 429) {
          unavailable("The Discogs API rate limit was still exceeded after several tries. Try again in a minute.", e)
        }
        if (status < 500) rlang::cnd_signal(e)
        unavailable("The Discogs API is not available at the moment (HTTP {status}).", e)
      }
    )
  store_rate_limit(resp, token)
  tryCatch(
    read_json(resp) %||% list(),
    error = \(e) unavailable("The Discogs API returned a response that could not be read.", e)
  )
}

unavailable <- function(message, parent) {
  cli::cli_abort(message, class = "tidycrates_unavailable", parent = parent, .envir = parent.frame())
}

dig_get <- function(path, query = list(), cache = TRUE, call = rlang::caller_env()) {
  fetcher <- if (cache && isTRUE(getOption("tidycrates.cache", FALSE))) cached_fetch(call) else fetch
  tryCatch(
    fetcher(path, query, auth_token(call)),
    tidycrates_unavailable = \(e) {
      message <- e$message
      cli::cli_inform("{message}")
      NULL
    },
    httr2_http = \(e) {
      status <- httr2::resp_status(e$resp)
      reason <- httr2::resp_status_desc(e$resp)
      body <- error_body(e$resp)
      request <- paste0("/", path)
      cli::cli_abort(
        c(
          "HTTP {status} {reason}.",
          i = if (!is.null(body)) "{body}",
          i = "Request: {.path {request}}."
        ),
        class = "tidycrates_http_error",
        status = status,
        call = call
      )
    }
  )
}

cached_fetch <- function(call = rlang::caller_env()) {
  age <- cache_age(call)
  if (is.null(dig_env$cached_fetch) || !identical(dig_env$cache_age, age)) {
    rlang::check_installed(c("memoise", "cachem"), reason = "to cache responses.", call = call)
    dig_env$cached_fetch <- memoise::memoise(fetch, cache = cachem::cache_mem(max_age = age))
    dig_env$cache_age <- age
  }
  dig_env$cached_fetch
}

cache_age <- function(call = rlang::caller_env()) {
  age <- getOption("tidycrates.cache_age", 3600)
  if (!rlang::is_scalar_double(age) && !rlang::is_scalar_integer(age) || is.na(age) || age <= 0) {
    cli::cli_abort("The option {.code tidycrates.cache_age} must be a positive number of seconds.", call = call)
  }
  min(as.numeric(age), 21600)
}

#' Clear the cache
#'
#' Removes the responses that were cached because the option
#' `tidycrates.cache` is `TRUE`, and the username found for the token by
#' functions such as [dig_collection()]. The next requests are sent to
#' 'Discogs' again.
#'
#' @return `NULL`, invisibly.
#'
#' @examples
#' dig_cache_clear()
#'
#' @export
dig_cache_clear <- function() {
  dig_env$cached_fetch <- NULL
  dig_env$cache_age <- NULL
  dig_env$identity <- NULL
  invisible(NULL)
}

dig_get_pages <- function(path, field, query = list(), all = FALSE, page = 1,
                          per_page = 50, cache = TRUE, max_pages = Inf, call = rlang::caller_env()) {
  if (all) {
    page <- 1L
    per_page <- 100L
  }
  page <- as.integer(page)
  get_page <- \(p) dig_get(path, c(query, page = p, per_page = as.integer(per_page)), cache, call)
  first <- get_page(page)
  if (is.null(first)) {
    return(NULL)
  }
  pages <- dplyr::coalesce(int(list(first), "pagination", "pages"), 1L)
  if (!all || pages <= page) {
    return(as_items(pluck_list(first, field)))
  }
  if (pages > max_pages) {
    cli::cli_abort(
      c(
        "There are {pages} pages of results, more than the {max_pages} that {.code all = TRUE} fetches.",
        i = "Narrow the search with filters, or fetch single pages with {.arg page}."
      ),
      call = call
    )
  }
  minutes <- (pages - page) %/% (request_cap() + 1)
  if (minutes >= 1) {
    cli::cli_inform("Fetching {pages} pages takes at least {minutes} minute{?s}.")
  }
  rest <- map_requests(seq(page + 1L, pages), get_page, .progress = "Fetching pages")
  if (any(purrr::map_lgl(rest, is.null))) {
    return(NULL)
  }
  c(list(first), rest) |>
    purrr::map(\(p) as_items(pluck_list(p, field))) |>
    purrr::list_flatten()
}
