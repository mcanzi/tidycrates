# List the wantlist of a user

Lists the releases in the wantlist of a 'Discogs' user. Anyone can read
a public wantlist. A private wantlist can only be read with the token of
its owner, see
[`dig_auth()`](https://mcanzi.de/tidycrates/reference/dig_auth.md).
Wantlists are never cached, so changes show up at once.

## Usage

``` r
dig_wantlist(
  username,
  sort = c("added", "artist", "title", "label", "catno", "format", "rating", "year"),
  order = c("asc", "desc"),
  all = FALSE,
  page = 1,
  per_page = 50
)
```

## Arguments

- username:

  A 'Discogs' username.

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
`master_id`, `rating`, `date_added` and `notes`. `rating` is `NA` if the
user gave none.

## Restricted Data

Collections, wantlists and usernames are Restricted Data under the
'Discogs' API Terms of Use. 'Discogs' grants a limited, personal licence
to use them. They may not be passed on to anyone else or used for
commercial purposes, and their use must respect the privacy of their
owners. Only publish a collection or wantlist, or tallies and plots of
it, if it is your own or its owner has agreed, and never for commercial
purposes.

## Examples

``` r
if (FALSE) { # interactive()
dig_wantlist("username", all = TRUE)
}
```
