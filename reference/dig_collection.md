# List the collection of a user

Lists the releases in the collection of a 'Discogs' user. Anyone can
read a public collection. A private collection can only be read with the
token of its owner, see
[`dig_auth()`](https://mcanzi.de/tidycrates/reference/dig_auth.md).

## Usage

``` r
dig_collection(
  username,
  folder = 0,
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

- folder:

  The ID of a collection folder. The default, `0`, holds the whole
  collection and is the only folder other users can read.

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

A tibble with one row per copy of a release, or `NULL` invisibly if the
API cannot be reached. The columns are `release_id`, `instance_id`,
`folder_id`, `title`, `artist`, `year`, `label`, `catno`, `format`,
`genres` and `styles` as list columns, `master_id`, `rating` and
`date_added`. `rating` is `NA` if the user gave none.

## Details

A release that is in the collection more than once has one row per copy,
each with its own `instance_id`. Custom fields, such as the media
condition, are left out. Collections are never cached, so changes show
up at once.

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
collection <- dig_collection("username", all = TRUE)
dplyr::count(collection, format, sort = TRUE)
}
```
