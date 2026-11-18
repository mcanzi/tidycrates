#' @details
#' Requests are sent to the 'Discogs' API at <https://api.discogs.com>.
#' Without a token, 'Discogs' allows 25 requests a minute. With a personal
#' access token set by [dig_auth()], the limit is 60 requests a minute,
#' the database can be searched, your own private collection and wantlist
#' can be read, and price suggestions and the value of your collection are
#' available. Up to 59 requests with a token, or 24 without, are sent at
#' once, and later requests wait until the last 60 seconds have room for
#' them. Requests are retried after HTTP 429 and 503 responses, and a
#' message says how long each wait takes.
#'
#' When the API cannot be reached, because there is no internet connection,
#' the server returns an error or the rate limit is still exceeded after
#' several tries, functions give a message and return `NULL` invisibly.
#' Errors caused by the request, such as an unknown release, stop with the
#' message returned by 'Discogs'.
#'
#' @section Options:
#' If the option `tidycrates.cache` is set to `TRUE`, responses from the
#' database are kept in memory for the session, so repeated requests do not
#' count towards the rate limit. Caching needs the memoise and cachem
#' packages and is off by default. Cached responses are kept for 3600
#' seconds unless `tidycrates.cache_age` gives another number of seconds.
#' Changing `tidycrates.cache_age` starts a new, empty cache, and
#' [dig_cache_clear()] empties it.
#' Collections, wantlists and marketplace data are never cached.
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
#' Collections, wantlists, usernames and marketplace data are Restricted
#' Data: keep them for your own use, see [dig_collection()]. Images are left
#' out, because the people who upload them can hold their own copyright.
#' Functions for selling, such as listings and orders, are left out too.
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
