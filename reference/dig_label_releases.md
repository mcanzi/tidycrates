# List the releases of a label

Lists the releases of a label or other company.

## Usage

``` r
dig_label_releases(id, all = FALSE, page = 1, per_page = 50)
```

## Arguments

- id:

  A label ID, as a number or as a code copied from 'Discogs' such as
  `"l1"` or `"[l1]"`.

- all:

  If `TRUE`, all pages are fetched and `page` and `per_page` are
  ignored.

- page:

  The page to fetch.

- per_page:

  The number of items per page, from 1 to 100.

## Value

A tibble with one row per release, or `NULL` invisibly if the API cannot
be reached.

## Examples

``` r
if (FALSE) { # interactive()
dig_label_releases(1)
}
```
