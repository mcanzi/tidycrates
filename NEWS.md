# tidycrates (development version)

* `dig_search()` searches the 'Discogs' database by a query, by filters or
  by both, and returns one row per release, master release, artist or
  label. It needs a token. `dig_tally()` and `dig_plot()` can count the
  results by genre, style, format, label, country, year or decade.
* An HTTP error for one of several IDs now stops with the message from
  'Discogs', without a purrr error about the index around it.
* A response body of `null` gives a row of `NA` instead of returning
  `NULL` without a message.
* `dig_collection_value()` keeps the sign of negative values.

# tidycrates 0.1.0

First release.

* Core request layer with token authentication, a custom user agent,
  throttling to the 'Discogs' rate limit, retries after HTTP 429,
  pagination and optional caching.
* `dig_release()`, `dig_master()`, `dig_artist()` and `dig_label()` read
  the 'Discogs' database. Images and prices are left out.
* `dig_tracklist()`, `dig_credits()`, `dig_formats()` and
  `dig_identifiers()` unnest release data into one row per item.
* `dig_artist_releases()`, `dig_label_releases()` and
  `dig_master_versions()` list releases, with all pages on request.
* `dig_collection()` and `dig_wantlist()` list the collection and wantlist
  of a user. Private ones can be read with the token of their owner, and
  neither is cached.
* `dig_price_stats()`, `dig_price_suggestions()` and
  `dig_collection_value()` read marketplace data. They are never cached,
  and the last two need a token.
* `dig_tally()` counts a collection, a wantlist or the output of the
  database and list functions by genre, style, format, label, artist,
  role, country, year, decade or month added. `dig_plot()` plots the
  counts with ggplot2 as labelled lollipops, columns or a growth line,
  with titles, subtitles and alt text.
* Cached responses are kept for at most six hours, as the API Terms of
  Use require.
* Plots carry the caption "Data provided by Discogs.", which the API
  Terms of Use require. The help pages and README explain which fields are
  CC0 and that collections, wantlists, usernames and marketplace data are
  Restricted Data.
* The tests and README examples use made-up data instead of data from
  'Discogs'. `data-raw/fixtures.R` creates it.
* IDs can also be given as codes copied from 'Discogs', such as
  `"[a514141]"` or `"a514141"`. A code of the wrong type, such as a
  master release code given to `dig_release()`, gives an error that names
  the right function.
* Unknown release dates, which 'Discogs' gives as `"0"`, are `NA`.
* README and pkgdown site in the glacier theme of mcanzi.de.
