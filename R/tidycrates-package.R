#' @details
#' Requests are sent to the 'Discogs' API at <https://api.discogs.com>.
#' Without a token, 'Discogs' allows 25 requests a minute. With a personal
#' access token set by [dig_auth()], the limit is 60 requests a minute and
#' your own private collection and wantlist can be read. Requests are
#' spaced out to stay within the limit and retried after HTTP 429
#' responses.
#'
#' When the API cannot be reached, because there is no internet connection
#' or the server returns an error, functions give a message and return
#' `NULL` invisibly. Errors caused by the request, such as an unknown
#' release, stop with the message returned by 'Discogs'.
#'
#' @section Options:
#' If the option `tidycrates.cache` is set to `TRUE`, responses from the
#' database are kept in memory for the session, so repeated requests do not
#' count towards the rate limit. Caching needs the memoise and cachem
#' packages and is off by default. Cached responses are kept for 3600
#' seconds unless `tidycrates.cache_age` gives another number of seconds.
#' Changing `tidycrates.cache_age` starts a new, empty cache.
#' Collections and wantlists are never cached.
#' The API Terms of Use do not allow showing data that are more than six
#' hours old, so responses are never kept longer than 21600 seconds.
#'
#' @section Terms of use:
#' The 'Discogs' API Terms of Use apply to all data returned by the
#' package, and using the package means accepting them. In the United
#' States, they require you to be at least 18 years old.
#'
#' The Terms of Use list the fields that are available under the CC0
#' licence: titles, notes, dates, formats, tracklists, identifiers,
#' credits, versions and links of releases, and the names, notes and
#' releases of artists and labels. Other fields, such as genres, styles,
#' community counts and ratings, are not listed as CC0, so they can only
#' be used under the Terms of Use.
#'
#' Collections, wantlists and usernames are Restricted Data, see
#' [dig_collection()]. Images and marketplace data, such as prices, are
#' Restricted Data too and are left out.
#'
#' Data from 'Discogs' may not be shown if they are more than six hours
#' older than the 'Discogs' website, or stored longer than needed.
#' Applications that show data from 'Discogs' have to display "Data
#' provided by Discogs." next to the data, with a link to the page on
#' 'Discogs'. The `uri` column gives that link, and [dig_plot()] adds the
#' text as a caption.
#'
#' This application uses Discogs' API but is not affiliated with, sponsored
#' or endorsed by Discogs. 'Discogs' is a trademark of Zink Media, LLC.
#'
#' @keywords internal
"_PACKAGE"

dig_env <- new.env(parent = emptyenv())
