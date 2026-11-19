# List the releases of an artist

Lists the releases and master releases an artist appears on, with the
role of the artist on each.

## Usage

``` r
dig_artist_releases(
  id,
  sort = c("year", "title", "format"),
  order = c("asc", "desc"),
  all = FALSE,
  page = 1,
  per_page = 50
)
```

## Arguments

- id:

  An artist ID, as a number or as a code copied from 'Discogs' such as
  `"a1"` or `"[a1]"`.

- sort:

  The column to sort by: `"year"`, `"title"` or `"format"`.

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

A tibble with one row per release or master release, or `NULL` invisibly
if the API cannot be reached. `type` tells releases and master releases
apart, and `id` is the ID of either. `have` and `want` are the numbers
of users with the item in their collection or wantlist.

## Details

'Discogs' returns up to 100 items per page and sometimes fewer than
`per_page`. With `all = TRUE`, every page is fetched, which takes one
request for each 100 items. If this takes a minute or more, a message
gives the least time it takes.

## Examples

``` r
if (FALSE) { # interactive()
dig_artist_releases(1, all = TRUE)
}
```
