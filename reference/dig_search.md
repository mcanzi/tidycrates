# Search the 'Discogs' database

Searches the releases, master releases, artists and labels in the
'Discogs' database. Search needs a token, see
[`dig_auth()`](https://mcanzi.de/tidycrates/reference/dig_auth.md), but
the token can belong to any user.

## Usage

``` r
dig_search(
  query = NULL,
  type = NULL,
  title = NULL,
  release_title = NULL,
  credit = NULL,
  artist = NULL,
  anv = NULL,
  label = NULL,
  genre = NULL,
  style = NULL,
  country = NULL,
  year = NULL,
  format = NULL,
  catno = NULL,
  barcode = NULL,
  track = NULL,
  sort = c("score", "title", "have", "want", "hot", "date_added", "date_changed", "year"),
  order = c("desc", "asc"),
  all = FALSE,
  page = 1,
  per_page = 50
)
```

## Arguments

- query:

  The search query, or `NULL` to search with filters only.

- type:

  The type of result: `"release"`, `"master"`, `"artist"` or `"label"`,
  or `NULL` for all types.

- title:

  The combined title, as in `"Juniper Static - Lantern Weather"`.

- release_title:

  The title of the release.

- credit:

  A name in the credits.

- artist:

  The name of the artist.

- anv:

  The name the artist is credited as on the release.

- label, genre, style, country, year, format, catno, barcode:

  Values to filter the results by, for example `format = "Vinyl"` or
  `year = 1994`.

- track:

  The title of a track.

- sort:

  The column to sort by: `"score"`, the relevance to the query,
  `"title"`, `"have"`, `"want"`, `"hot"`, `"date_added"`,
  `"date_changed"` or `"year"`.

- order:

  The sort order: `"asc"` or `"desc"`.

- all:

  If `TRUE`, all pages are fetched and `page` and `per_page` are
  ignored.

- page:

  The page to fetch.

- per_page:

  The number of items per page, from 1 to 100.

## Value

A tibble with one row per result, or `NULL` invisibly if the API cannot
be reached. `type` tells releases, master releases, artists and labels
apart, and `id` is the ID of either. `title` combines the artist and the
title, and for artists and labels it is the name. `genres` and `styles`
are list columns. `have` and `want` are the numbers of users with the
item in their collection or wantlist. Columns that do not apply to a
type, such as `catno` for artists, are `NA`.

## Details

Give a search query, one or more filters, or both. Each filter searches
one field, so `artist = "Juniper Static"` finds releases by that artist
but not releases that only mention the name in their title. The IDs in
`id` can be passed to
[`dig_release()`](https://mcanzi.de/tidycrates/reference/dig_release.md),
[`dig_master()`](https://mcanzi.de/tidycrates/reference/dig_master.md),
[`dig_artist()`](https://mcanzi.de/tidycrates/reference/dig_artist.md)
or [`dig_label()`](https://mcanzi.de/tidycrates/reference/dig_label.md),
depending on `type`.

'Discogs' returns up to 100 results per page. With `all = TRUE`, every
page is fetched, which takes one request for each 100 results. A search
with more than 100 pages, or 10,000 results, stops with an error before
the other pages are fetched, so that a broad search does not send
hundreds of requests. Single pages can still be fetched with `page`.

## Examples

``` r
if (FALSE) { # interactive()
dig_search("Lantern Weather", type = "release")
dig_search(artist = "Juniper Static", format = "Vinyl", year = 1994)
}
```
