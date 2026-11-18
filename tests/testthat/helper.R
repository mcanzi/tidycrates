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
}

discogs_response <- function(body, status = 200L, used = 1L, limit = 25L) {
  httr2::response_json(
    status_code = status,
    headers = list(
      `X-Discogs-Ratelimit` = limit,
      `X-Discogs-Ratelimit-Used` = used,
      `X-Discogs-Ratelimit-Remaining` = limit - used
    ),
    body = body
  )
}

page_response <- function(req, pages = 3L) {
  page <- as.integer(httr2::url_parse(req$url)$query$page)
  discogs_response(list(
    pagination = list(page = page, pages = pages),
    releases = list(list(id = page * 10L), list(id = page * 10L + 1L))
  ))
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
    "users/example/wants$" = "wantlist-example"
  )
  httr2::local_mocked_responses(
    function(req) {
      path <- httr2::url_parse(req$url)$path
      hit <- names(routes)[stringr::str_detect(path, names(routes))]
      if (length(hit) == 0) {
        return(discogs_response(list(message = "Not found."), status = 404L))
      }
      discogs_response(fixture(routes[[hit[1]]]))
    },
    env = env
  )
}
