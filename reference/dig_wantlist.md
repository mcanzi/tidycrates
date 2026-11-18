# List the wantlist of a user

Lists the releases in the wantlist of a 'Discogs' user. Anyone can read
a public wantlist. A private wantlist can only be read with the token of
its owner, see
[`dig_auth()`](https://mcanzi.de/tidycrates/reference/dig_auth.md).
Without a username, the wantlist of the token owner is listed. Wantlists
are never cached, so changes show up at once.

## Usage

``` r
dig_wantlist(
  username = NULL,
  sort = c("added", "artist", "title", "label", "catno", "format", "rating", "year"),
  order = c("asc", "desc"),
  all = FALSE,
  page = 1,
  per_page = 50
)
```

## Arguments

- username:

  A 'Discogs' username, or `NULL` for the owner of the token set with
  [`dig_auth()`](https://mcanzi.de/tidycrates/reference/dig_auth.md).
  Finding the owner takes one request, once per session.

- sort:

  The column to sort by: `"added"`, `"artist"`, `"title"`, `"label"`,
  `"catno"`, `"format"`, `"rating"` or `"year"`.

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

A tibble with one row per release, or `NULL` invisibly if the API cannot
be reached. The columns are `release_id`, `title`, `artist`, `year`,
`label`, `catno`, `format`, `genres` and `styles` as list columns,
`master_id`, `rating` and `date_added`. `rating` is `NA` if the user
gave none.

## Details

The notes that a user writes for each release are left out, because they
can be personal.

## Restricted Data

Collections, wantlists, usernames and marketplace data, such as prices
and collection values, are Restricted Data under the 'Discogs' API Terms
of Use. 'Discogs' grants each user a limited, personal licence to access
and use them with their own token. They may not be passed on to anyone
else or used for commercial purposes, and their use must respect the
privacy of their owners. Keep them, and tallies and plots of them, for
your own use, and do not publish them. The Terms of Use also forbid
using the API to get around the 'Discogs' marketplace.

## Examples

``` r
if (FALSE) { # interactive()
dig_wantlist("username", all = TRUE)
}
```
