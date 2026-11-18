# tidycrates: Tidy Data from the 'Discogs' API

Sends requests to the 'Discogs' API <https://www.discogs.com/developers>
and returns the results as tidy tibbles. Releases, master releases,
artists and labels can be read from the 'Discogs' database, along with
the releases of an artist or label and the versions of a master release.
The collection and wantlist of a user can be listed, tallied and
plotted. Tracklists, credits, formats and identifiers of releases can be
unnested into one row per item. Requests can be made with a personal
access token or without one. They are spaced out to stay within the rate
limit of the API and retried when the limit is exceeded. Responses can
be cached for the session, and paginated results can be fetched in full.

## Details

Requests are sent to the 'Discogs' API at <https://api.discogs.com>.
Without a token, 'Discogs' allows 25 requests a minute. With a personal
access token set by
[`dig_auth()`](https://mcanzi.de/tidycrates/reference/dig_auth.md), the
limit is 60 requests a minute and your own private collection and
wantlist can be read. Requests are spaced out to stay within the limit
and retried after HTTP 429 responses.

When the API cannot be reached, because there is no internet connection
or the server returns an error, functions give a message and return
`NULL` invisibly. Errors caused by the request, such as an unknown
release, stop with the message returned by 'Discogs'.

## Options

If the option `tidycrates.cache` is set to `TRUE`, responses from the
database are kept in memory for the session, so repeated requests do not
count towards the rate limit. Caching needs the memoise and cachem
packages and is off by default. Cached responses are kept for 3600
seconds unless `tidycrates.cache_age` gives another number of seconds.
Changing `tidycrates.cache_age` starts a new, empty cache. Collections
and wantlists are never cached. The API Terms of Use do not allow
showing data that are more than six hours old, so responses are never
kept longer than 21600 seconds.

## Terms of use

The 'Discogs' API Terms of Use apply to all data returned by the
package, and using the package means accepting them. In the United
States, they require you to be at least 18 years old.

The Terms of Use list the fields that are available under the CC0
licence: titles, notes, dates, formats, tracklists, identifiers,
credits, versions and links of releases, and the names, notes and
releases of artists and labels. Other fields, such as genres, styles,
community counts and ratings, are not listed as CC0, so they can only be
used under the Terms of Use.

Collections, wantlists and usernames are Restricted Data, see
[`dig_collection()`](https://mcanzi.de/tidycrates/reference/dig_collection.md).
Images and marketplace data, such as prices, are Restricted Data too and
are left out.

Data from 'Discogs' may not be shown if they are more than six hours
older than the 'Discogs' website, or stored longer than needed.
Applications that show data from 'Discogs' have to display "Data
provided by Discogs." next to the data, with a link to the page on
'Discogs'. The `uri` column gives that link, and
[`dig_plot()`](https://mcanzi.de/tidycrates/reference/dig_plot.md) adds
the text as a caption.

This application uses Discogs' API but is not affiliated with, sponsored
or endorsed by Discogs. 'Discogs' is a trademark of Zink Media, LLC.

## See also

Useful links:

- <https://github.com/mcanzi/tidycrates>

- <https://mcanzi.de/tidycrates/>

- Report bugs at <https://github.com/mcanzi/tidycrates/issues>

## Author

**Maintainer**: Massimiliano Canzi <massimiliano.canzi@uni-konstanz.de>
([ORCID](https://orcid.org/0000-0001-6124-0321)) \[copyright holder\]

Authors:

- Massimiliano Canzi <massimiliano.canzi@uni-konstanz.de>
  ([ORCID](https://orcid.org/0000-0001-6124-0321)) \[copyright holder\]
