# Tally releases

Counts the rows of a tibble returned by tidycrates, such as the copies
in a collection or the releases of a label, by genre, style, format,
label, artist, role, country, year, decade or month added. Only the
columns of `x` are used, so no requests are sent.

## Usage

``` r
dig_tally(
  x,
  by = c("genre", "style", "format", "label", "artist", "role", "country", "decade",
    "year", "added"),
  n = 10,
  unique = FALSE
)
```

## Arguments

- x:

  A tibble returned by one of the functions listed in Details.

- by:

  What to count by: `"genre"`, `"style"`, `"format"`, `"label"`,
  `"artist"`, `"role"`, `"country"`, `"decade"`, `"year"` or `"added"`,
  the month a copy was added.

- n:

  The number of values to keep for all but years, decades and months.
  The rest are counted together as `"Other"`. `Inf` keeps all values.

- unique:

  If `TRUE`, each release counts once, however many copies of it there
  are.

## Value

A tibble with a column named after `by`, `n`, the number of rows, and
`share`, the share of all rows. For `by = "added"`, `total` gives the
running number of rows at the end of each month, such as the size of a
collection. Years, decades and months are in order, and other values are
sorted from most to least common. `"Other"` counts the rows with at
least one value outside the top `n`. It is called `"All other"` if one
of the values is `"Other"`. `NULL` is returned invisibly if `x` is
`NULL`.

## Details

Which values of `by` work depends on where `x` comes from:

|  |  |
|----|----|
| `x` from | `by` |
| [`dig_collection()`](https://mcanzi.de/tidycrates/reference/dig_collection.md), [`dig_wantlist()`](https://mcanzi.de/tidycrates/reference/dig_wantlist.md) | genre, style, format, label, artist, decade, year, added |
| [`dig_release()`](https://mcanzi.de/tidycrates/reference/dig_release.md) | genre, style, format, label, artist, country, decade, year, added |
| [`dig_master()`](https://mcanzi.de/tidycrates/reference/dig_master.md) | genre, style, artist, decade, year |
| [`dig_artist_releases()`](https://mcanzi.de/tidycrates/reference/dig_artist_releases.md) | format, label, artist, role, decade, year |
| [`dig_label_releases()`](https://mcanzi.de/tidycrates/reference/dig_label_releases.md) | format, artist, decade, year |
| [`dig_master_versions()`](https://mcanzi.de/tidycrates/reference/dig_master_versions.md) | format, label, country, decade, year |
| [`dig_search()`](https://mcanzi.de/tidycrates/reference/dig_search.md) | genre, style, format, label, country, decade, year |

A row with several genres, styles, formats or labels counts once for
each of them, so the shares can add up to more than 1. Rows without a
value, such as releases with an unknown year, are left out.

The lists of
[`dig_artist_releases()`](https://mcanzi.de/tidycrates/reference/dig_artist_releases.md)
and
[`dig_label_releases()`](https://mcanzi.de/tidycrates/reference/dig_label_releases.md)
give formats as descriptions such as `2x12", Comp`. Only the first part
is counted, without the number of items, so vinyl is counted by size,
for example `12"`.
[`dig_search()`](https://mcanzi.de/tidycrates/reference/dig_search.md)
gives the format of a release followed by its descriptions, and only the
format is counted. Master releases in
[`dig_artist_releases()`](https://mcanzi.de/tidycrates/reference/dig_artist_releases.md)
stand for all their versions and have no format or label. For
[`dig_release()`](https://mcanzi.de/tidycrates/reference/dig_release.md),
`added` is the month the release was added to 'Discogs'.

Collections and wantlists have no country, because 'Discogs' does not
return it for them. To tally a collection by country, get its releases
first with `dig_release(collection$release_id)`. This sends one request
for each release.

Tallies of a collection or wantlist are still Restricted Data, see
[`dig_collection()`](https://mcanzi.de/tidycrates/reference/dig_collection.md).

## Examples

``` r
shelf <- tibble::tibble(
  release_id = c(1, 1, 2, 3),
  year = c(1994, 1994, 1998, NA),
  genres = list(c("Electronic", "Pop"), c("Electronic", "Pop"), "Electronic", "Jazz")
)
dig_tally(shelf, "genre")
#> # A tibble: 3 × 3
#>   genre          n share
#>   <chr>      <int> <dbl>
#> 1 Electronic     3  0.75
#> 2 Pop            2  0.5 
#> 3 Jazz           1  0.25
dig_tally(shelf, "decade")
#> # A tibble: 1 × 3
#>   decade     n share
#>    <dbl> <int> <dbl>
#> 1   1990     3  0.75
dig_tally(shelf, "genre", unique = TRUE)
#> # A tibble: 3 × 3
#>   genre          n share
#>   <chr>      <int> <dbl>
#> 1 Electronic     2 0.667
#> 2 Jazz           1 0.333
#> 3 Pop            1 0.333

if (FALSE) { # interactive()
collection <- dig_collection("username", all = TRUE)
dig_tally(collection, "genre")
dig_tally(collection, "added")
dig_tally(dig_label_releases(1, all = TRUE), "decade")
}
```
