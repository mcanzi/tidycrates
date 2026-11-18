# Get labels

Gets record labels and other companies, such as pressing plants and
studios, from the 'Discogs' database.

## Usage

``` r
dig_label(id)
```

## Arguments

- id:

  One or more label IDs, as numbers or as codes copied from 'Discogs'
  such as `"l1"` or `"[l1]"`.

## Value

A tibble with one row per label, or `NULL` invisibly if the API cannot
be reached. The columns are `label_id`, `name`, `profile`,
`contact_info`, `parent_label`, `parent_label_id`, `data_quality`,
`uri`, `urls` as a list column of character vectors, and `sublabels` as
a list column of tibbles.

## Details

Profiles keep the 'Discogs' markup for links. Images are Restricted Data
under the 'Discogs' API Terms of Use and are left out.
[`dig_label_releases()`](https://mcanzi.de/tidycrates/reference/dig_label_releases.md)
lists the releases of a label.

## Examples

``` r
if (FALSE) { # interactive()
dig_label(1)
}
```
