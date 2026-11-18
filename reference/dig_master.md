# Get master releases

Gets master releases from the 'Discogs' database. A master release
groups all versions of a release, such as the original pressing, later
reissues and editions in other countries.

## Usage

``` r
dig_master(id)
```

## Arguments

- id:

  One or more master release IDs, as numbers or as codes copied from
  'Discogs' such as `"m96559"` or `"[m96559]"`.

## Value

A tibble with one row per master release, or `NULL` invisibly if the API
cannot be reached. The columns are `master_id`, `title`, `artist`,
`year`, `genres`, `styles`, `main_release`, `most_recent_release`,
`data_quality`, `uri` and `tracklist`, a list column of tibbles that
[`dig_tracklist()`](https://mcanzi.de/tidycrates/reference/unnest_release.md)
unnests.

## Details

Images are left out, because the people who upload them can hold their
own copyright.
[`dig_master_versions()`](https://mcanzi.de/tidycrates/reference/dig_master_versions.md)
lists the versions.

## Examples

``` r
if (FALSE) { # interactive()
dig_master(96559)
}
```
