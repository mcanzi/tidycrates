# Get artists

Gets artists from the 'Discogs' database. Names that several artists
share are told apart by a number in brackets, for example
`"Persuader (2)"`.

## Usage

``` r
dig_artist(id)
```

## Arguments

- id:

  One or more artist IDs, as numbers or as codes copied from 'Discogs'
  such as `"a1"` or `"[a1]"`.

## Value

A tibble with one row per artist, or `NULL` invisibly if the API cannot
be reached. The columns are `artist_id`, `name`, `real_name`, `profile`,
`data_quality`, `uri`, `urls` and `name_variations` as list columns of
character vectors, and `aliases`, `members` and `groups` as list columns
of tibbles.

## Details

Profiles keep the 'Discogs' markup for links, such as `[a=Carl Craig]`.
Images are left out, because the people who upload them can hold their
own copyright.
[`dig_artist_releases()`](https://mcanzi.de/tidycrates/reference/dig_artist_releases.md)
lists the releases of an artist.

## Examples

``` r
if (FALSE) { # interactive()
dig_artist(1)
}
```
