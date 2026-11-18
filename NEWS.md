# tidycrates 0.2.0

* `dig_search()` searches the 'Discogs' database by a query, by filters or
  by both, and returns one row per release, master release, artist or
  label. It needs a token. `dig_tally()` and `dig_plot()` can count the
  results by genre, style, format, label, country, year or decade, and
  `dig_plot()` counts "results" instead of "releases" when they include
  artists or labels.
* `dig_collection()` returns the media and sleeve condition of each copy
  as factors from best to worst, with the same grades as
  `dig_price_suggestions()`. The collection fields are read with one more
  request, and only when a copy has a value in one of them. If that
  request fails, the conditions are `NA` and the collection is kept.
* An HTTP error for one of several IDs now stops with the message from
  'Discogs', without a purrr error about the index around it.
* A response body of `null` gives a row of `NA` instead of returning
  `NULL` without a message.
* `dig_collection_value()` keeps the sign of negative values.
* `dig_collection_folders()` lists the folders of a collection with their
  IDs, which `dig_collection()` takes as `folder`.
* `dig_collection()` returns the folder name of each copy in a `folder`
  column. The folders are read with one more request, which is skipped
  without a token and when the token owner is known to be someone else.
  Then, or if that request fails, the names are `NA` and the collection
  is kept.
* `dig_companies()` unnests the labels and other companies of releases.
* `dig_cache_clear()` empties the cache.
* `dig_collection()`, `dig_wantlist()`, `dig_collection_folders()` and
  `dig_collection_value()` use the owner of the token when no username is
  given.
* Requests are spaced out evenly. Before, the first 25 requests were sent
  at once, so a batch of more than 25 could exceed the rate limit of
  'Discogs'.
* A rate limit that is still exceeded after several tries gives a message
  and returns `NULL`, as when the API cannot be reached.
* `dig_search(all = TRUE)` stops before fetching more than 100 pages.
* `dig_wantlist()` leaves out the notes of the user, as `dig_collection()`
  does.
* Tokens with spaces or line breaks inside, and usernames made only of
  dots, are rejected.
* jsonlite is now imported. It was needed to read every response but was
  only suggested. httr2 1.2.2 and, for plots, ggplot2 3.5.2 are now
  required.
* The made-up data of the tests and README agree with each other.

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
