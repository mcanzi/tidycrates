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
`media_condition`, `sleeve_condition`, `genres` and `styles` as list
columns, `master_id`, `rating` and `date_added`. `rating` is `NA` if the
user gave none. The conditions are factors from best to worst, with the
same grades as
[`dig_price_suggestions()`](https://mcanzi.de/tidycrates/reference/dig_price_suggestions.md).
The sleeve condition can also be `"Generic"` or `"No Cover"`, and a
condition is `NA` if the user gave none.

## Details

A release that is in the collection more than once has one row per copy,
each with its own `instance_id`. Collections are never cached, so
changes show up at once.

The media and sleeve conditions come from the collection fields named
Media and Sleeve. If any copy has a value in a field, the fields are
matched by name with one more request. Other fields, such as Notes, are
left out. Without the token of the owner, only public fields can be
read, and the conditions are `NA` for fields that are private. If the
fields cannot be read, a message says so and the conditions are `NA`.

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
collection <- dig_collection("username", all = TRUE)
dplyr::count(collection, format, sort = TRUE)
dplyr::count(collection, media_condition)
}
```
