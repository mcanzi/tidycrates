# tidycrates: Tidy Data from the 'Discogs' API

Sends requests to the 'Discogs' application programming interface (API)
<https://www.discogs.com/developers> and returns the results as tidy
tibbles. The 'Discogs' database can be searched, and releases, master
releases, artists and labels can be read from it, along with the
releases of an artist or label and the versions of a master release. The
collection folders, collection and wantlist of a user can be listed,
tallied and plotted, and marketplace statistics, price suggestions and
collection values can be read. Tracklists, credits, formats, identifiers
and companies of releases can be unnested into one row per item.
Requests can be made with a personal access token or without one. They
stay within the rate limit of the API and are retried when the limit is
exceeded. Responses can be cached for the session, and paginated results
can be fetched in full.

## Details

Requests are sent to the 'Discogs' API at <https://api.discogs.com>.
Without a token, 'Discogs' allows 25 requests a minute. With a personal
access token set by
[`dig_auth()`](https://mcanzi.de/tidycrates/reference/dig_auth.md), the
limit is 60 requests a minute, the database can be searched, your own
private collection and wantlist can be read, and price suggestions and
the value of your collection are available. Up to 59 requests with a
token, or 24 without, are sent at once, and later requests wait until
the last 60 seconds have room for them. Requests are retried after HTTP
429 and 503 responses, and a message says how long each wait takes.

When the API cannot be reached, because there is no internet connection,
the server returns an error or the rate limit is still exceeded after
several tries, functions give a message and return `NULL` invisibly.
Errors caused by the request, such as an unknown release, stop with the
message returned by 'Discogs'.

## Options

If the option `tidycrates.cache` is set to `TRUE`, responses from the
database are kept in memory for the session, so repeated requests do not
count towards the rate limit. Caching needs the memoise and cachem
packages and is off by default. Cached responses are kept for 3600
seconds unless `tidycrates.cache_age` gives another number of seconds.
Changing `tidycrates.cache_age` starts a new, empty cache, and
[`dig_cache_clear()`](https://mcanzi.de/tidycrates/reference/dig_cache_clear.md)
empties it. Collections, wantlists and marketplace data are never
cached. The API Terms of Use do not allow showing data that are more
than six hours old, so responses are never kept longer than 21600
seconds.

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

Collections, wantlists, usernames and marketplace data are Restricted
Data: keep them for your own use, see
[`dig_collection()`](https://mcanzi.de/tidycrates/reference/dig_collection.md).
Images are left out, because the people who upload them can hold their
own copyright. Functions for selling, such as listings and orders, are
left out too.

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
