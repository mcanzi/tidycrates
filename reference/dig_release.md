# Get releases

Gets releases from the 'Discogs' database. A release is one particular
edition of a recording, such as the 1987 UK 7" single of a song.

## Usage

``` r
dig_release(id)
```

## Arguments

- id:

  One or more release IDs, as numbers or as codes copied from 'Discogs'
  such as `"r249504"` or `"[r249504]"`.

## Value

A tibble with one row per release, or `NULL` invisibly if the API cannot
be reached. Several labels, catalogue numbers or formats are separated
by semicolons in `label`, `catno` and `format`. `genres` and `styles`
are list columns of character vectors. `have` and `want` give the number
of users with the release in their collection or wantlist. The
tracklist, credits, formats, identifiers and companies are list columns
of tibbles.

## Details

The tracklist, credits, formats, identifiers and companies are kept as
list columns of tibbles.
[`dig_tracklist()`](https://mcanzi.de/tidycrates/reference/unnest_release.md),
[`dig_credits()`](https://mcanzi.de/tidycrates/reference/unnest_release.md),
[`dig_formats()`](https://mcanzi.de/tidycrates/reference/unnest_release.md)
and
[`dig_identifiers()`](https://mcanzi.de/tidycrates/reference/unnest_release.md)
turn them into one row per item.

Images, prices and the number of copies for sale are Restricted Data
under the 'Discogs' API Terms of Use and are left out. The `uri` column
links to the release on the 'Discogs' website.

## See also

[`dig_master()`](https://mcanzi.de/tidycrates/reference/dig_master.md)
and
[`dig_master_versions()`](https://mcanzi.de/tidycrates/reference/dig_master_versions.md)
for other versions of a release.

## Examples

``` r
if (FALSE) { # interactive()
dig_release(249504)
}
```
