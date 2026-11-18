#' Set the 'Discogs' token
#'
#' Sets the personal access token used for requests in this session. With a
#' token, 'Discogs' allows 60 requests a minute instead of 25, and
#' [dig_collection()] and [dig_wantlist()] can read your own collection and
#' wantlist when they are private. A token can be generated at
#' <https://www.discogs.com/settings/developers>.
#'
#' If `dig_auth()` is never called, the `DISCOGS_TOKEN` environment
#' variable is used. Storing the token in `.Renviron` keeps it out of your
#' scripts.
#'
#' @param token A personal access token. By default the value of the
#'   `DISCOGS_TOKEN` environment variable. An empty string removes the
#'   token, so requests are made without one.
#'
#' @return `TRUE` if a token is set and `FALSE` otherwise, invisibly.
#'
#' @examplesIf interactive()
#' dig_auth()
#'
#' @export
dig_auth <- function(token = Sys.getenv("DISCOGS_TOKEN")) {
  check_string(token)
  token <- stringr::str_trim(token)
  dig_env$token <- token
  if (nzchar(token)) {
    cli::cli_inform("Requests will be made with a token.")
  } else {
    cli::cli_inform("Requests will be made without a token.")
  }
  invisible(nzchar(token))
}

auth_token <- function() {
  token <- stringr::str_trim(dig_env$token %||% Sys.getenv("DISCOGS_TOKEN"))
  if (nzchar(token)) token else NULL
}

#' Set the user agent
#'
#' 'Discogs' asks every application to identify itself with a user agent.
#' Requests are sent as `tidycrates/<version>
#' (+https://github.com/mcanzi/tidycrates)` by default. A name set here is
#' placed in front, so requests from your script or application can be told
#' apart.
#'
#' @param agent The name and version of your application, for example
#'   `"MyCollectionStats/1.0"`. `NULL` returns the current user agent
#'   without changing it, and an empty string restores the default.
#'
#' @return The user agent, invisibly if `agent` is given.
#'
#' @examples
#' dig_user_agent()
#'
#' @export
dig_user_agent <- function(agent = NULL) {
  if (is.null(agent)) {
    return(user_agent())
  }
  check_string(agent)
  dig_env$agent <- stringr::str_squish(agent)
  invisible(user_agent())
}

user_agent <- function() {
  base <- paste0(
    "tidycrates/", utils::packageVersion("tidycrates"),
    " (+https://github.com/mcanzi/tidycrates)"
  )
  agent <- dig_env$agent %||% ""
  if (nzchar(agent)) paste(agent, base) else base
}
