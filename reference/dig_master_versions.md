# List the versions of a master release

Lists the releases that belong to a master release, such as reissues and
editions in other countries. The versions can be filtered by format,
label, year and country.

## Usage

``` r
dig_master_versions(
  id,
  format = NULL,
  label = NULL,
  released = NULL,
  country = NULL,
  sort = c("released", "title", "format", "label", "catno", "country"),
  order = c("asc", "desc"),
  all = FALSE,
  page = 1,
  per_page = 50
)
```

## Arguments

- id:

  A master release ID, as a number or as a code copied from 'Discogs'
  such as `"m96559"` or `"[m96559]"`.

- format, label, released, country:

  Values to filter the versions by, for example `format = "Vinyl"` or
  `released = 1997`.

- sort:

  The column to sort by: `"released"`, `"title"`, `"format"`, `"label"`,
  `"catno"` or `"country"`.

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

A tibble with one row per version, or `NULL` invisibly if the API cannot
be reached. `have` and `want` are the numbers of users with the version
in their collection or wantlist.

## Examples

``` r
if (FALSE) { # interactive()
dig_master_versions(1000, format = "CD")
}
```
