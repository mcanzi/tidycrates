# Changelog

## tidycrates 0.0.0.9000

- Core request layer with token authentication, a custom user agent,
  throttling to the ‘Discogs’ rate limit, retries after HTTP 429,
  pagination and optional caching.
- [`dig_release()`](https://mcanzi.de/tidycrates/reference/dig_release.md),
  [`dig_master()`](https://mcanzi.de/tidycrates/reference/dig_master.md),
  [`dig_artist()`](https://mcanzi.de/tidycrates/reference/dig_artist.md)
  and
  [`dig_label()`](https://mcanzi.de/tidycrates/reference/dig_label.md)
  read the ‘Discogs’ database. Images and marketplace data are left out.
- [`dig_tracklist()`](https://mcanzi.de/tidycrates/reference/unnest_release.md),
  [`dig_credits()`](https://mcanzi.de/tidycrates/reference/unnest_release.md),
  [`dig_formats()`](https://mcanzi.de/tidycrates/reference/unnest_release.md)
  and
  [`dig_identifiers()`](https://mcanzi.de/tidycrates/reference/unnest_release.md)
  unnest release data into one row per item.
- [`dig_artist_releases()`](https://mcanzi.de/tidycrates/reference/dig_artist_releases.md),
  [`dig_label_releases()`](https://mcanzi.de/tidycrates/reference/dig_label_releases.md)
  and
  [`dig_master_versions()`](https://mcanzi.de/tidycrates/reference/dig_master_versions.md)
  list releases, with all pages on request.
- [`dig_collection()`](https://mcanzi.de/tidycrates/reference/dig_collection.md)
  and
  [`dig_wantlist()`](https://mcanzi.de/tidycrates/reference/dig_wantlist.md)
  list the collection and wantlist of a user. Private ones can be read
  with the token of their owner, and neither is cached.
- [`dig_tally()`](https://mcanzi.de/tidycrates/reference/dig_tally.md)
  counts a collection, a wantlist or the output of the database and list
  functions by genre, style, format, label, artist, role, country, year,
  decade or month added.
  [`dig_plot()`](https://mcanzi.de/tidycrates/reference/dig_plot.md)
  plots the counts with ggplot2 as labelled lollipops, columns or a
  growth line, with titles, subtitles and alt text.
- Cached responses are kept for at most six hours, as the API Terms of
  Use require.
- Plots carry the caption “Data provided by Discogs.”, which the API
  Terms of Use require. The help pages and README explain which fields
  are CC0 and that collections, wantlists and usernames are Restricted
  Data.
- The tests and README examples use made-up data instead of data from
  ‘Discogs’. `data-raw/fixtures.R` creates it.
- IDs can also be given as codes copied from ‘Discogs’, such as
  `"[a514141]"` or `"a514141"`. A code of the wrong type, such as a
  master release code given to
  [`dig_release()`](https://mcanzi.de/tidycrates/reference/dig_release.md),
  gives an error that names the right function.
- Unknown release dates, which ‘Discogs’ gives as `"0"`, are `NA`.
- README and pkgdown site in the glacier theme of mcanzi.de.
