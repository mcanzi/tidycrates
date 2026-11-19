local_dig_state <- function(token = "", env = parent.frame()) {
  old <- as.list(dig_env)
  rm(list = ls(dig_env), envir = dig_env)
  dig_env$token <- token
  withr::defer(
    {
      rm(list = ls(dig_env), envir = dig_env)
      list2env(old, dig_env)
    },
    envir = env
  )
  withr::local_options(tidycrates.cache = FALSE, .local_envir = env)
  clock <- rlang::env(time = 0, pauses = numeric())
  local_mocked_bindings(
    now = \() clock$time,
    pause = \(seconds) {
      clock$pauses <- c(clock$pauses, seconds)
      clock$time <- clock$time + max(seconds, 0)
    },
    .env = env
  )
  invisible(clock)
}

rate_headers <- function(used, limit) {
  if (is.null(used)) {
    return(list())
  }
  list(
    `X-Discogs-Ratelimit` = limit,
    `X-Discogs-Ratelimit-Used` = used,
    `X-Discogs-Ratelimit-Remaining` = limit - used
  )
}

discogs_response <- function(body, status = 200L, used = NULL, limit = 60L) {
  httr2::response_json(status_code = status, headers = rate_headers(used, limit), body = body)
}

page_response <- function(req, pages = 3L) {
  page <- as.integer(httr2::url_parse(req$url)$query$page)
  discogs_response(list(
    pagination = list(page = page, pages = pages),
    releases = list(list(id = page * 10L), list(id = page * 10L + 1L))
  ))
}

raw_response <- function(name, used = NULL, limit = 60L) {
  path <- test_path("fixtures", paste0(name, ".json"))
  httr2::response(
    status_code = 200L,
    headers = c(list(`Content-Type` = "application/json"), rate_headers(used, limit)),
    body = readBin(path, "raw", file.size(path))
  )
}

discogs_count <- function(times, at) {
  start <- 60 * floor(at / 60)
  sum(times >= start - 60 & times < start) * (1 - (at - start) / 60) + sum(times >= start & times < at)
}

fixture <- function(name) {
  jsonlite::read_json(test_path("fixtures", paste0(name, ".json")))
}

local_fixtures <- function(env = parent.frame()) {
  routes <- c(
    "releases/1001$" = "release-1001",
    "masters/2001$" = "master-2001",
    "artists/3001$" = "artist-3001",
    "labels/4001$" = "label-4001",
    "artists/3001/releases$" = "artist-3001-releases",
    "labels/4001/releases$" = "label-4001-releases",
    "masters/2001/versions$" = "master-2001-versions",
    "users/example/collection/folders/0/releases$" = "collection-example",
    "users/example/collection/fields$" = "collection-fields-example",
    "users/example/wants$" = "wantlist-example",
    "marketplace/stats/1001$" = "price-stats-1001",
    "marketplace/stats/1002$" = "price-stats-1002",
    "marketplace/stats/1003$" = "price-stats-1003",
    "marketplace/price_suggestions/1001$" = "price-suggestions-1001",
    "marketplace/price_suggestions/1002$" = "price-suggestions-1002",
    "users/example/collection/value$" = "collection-value-example",
    "users/example/collection/folders$" = "collection-folders-example",
    "oauth/identity$" = "identity-example",
    "database/search$" = "search-juniper"
  )
  httr2::local_mocked_responses(
    function(req) {
      path <- httr2::url_parse(req$url)$path
      hit <- names(routes)[stringr::str_detect(path, names(routes))]
      if (length(hit) == 0) {
        return(discogs_response(list(message = "Not found."), status = 404L))
      }
      raw_response(routes[[hit[1]]])
    },
    env = env
  )
}
