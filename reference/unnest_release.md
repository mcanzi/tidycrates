# Unnest release data

Turns the list columns of
[`dig_release()`](https://mcanzi.de/tidycrates/reference/dig_release.md)
into tibbles with one row per track, credit, format, identifier or
company. Each row keeps the ID of its release.

## Usage

``` r
dig_tracklist(x)

dig_credits(x)

dig_formats(x)

dig_identifiers(x)

dig_companies(x)
```

## Arguments

- x:

  A tibble returned by
  [`dig_release()`](https://mcanzi.de/tidycrates/reference/dig_release.md)
  or, for `dig_tracklist()`,
  [`dig_master()`](https://mcanzi.de/tidycrates/reference/dig_master.md).
  Release IDs or codes such as `"[r249504]"` are also accepted and
  fetched first.

## Value

A tibble, or `NULL` invisibly if the API cannot be reached.

## Details

`dig_tracklist()` also accepts the output of
[`dig_master()`](https://mcanzi.de/tidycrates/reference/dig_master.md).
Headings and index tracks are kept with their `type`, and the tracks of
an index follow it. `seconds` is the duration converted to seconds.

`dig_credits()` combines the credits of the whole release with those of
single tracks. `credited_as` is the name printed on the release, if it
differs from the artist name, and `tracks` gives the positions a credit
applies to.

`dig_companies()` lists the labels of the release followed by the other
companies, such as pressing plants and studios. `role` says what each
company did, and `label_id` can be passed to
[`dig_label()`](https://mcanzi.de/tidycrates/reference/dig_label.md).

## Examples

``` r
if (FALSE) { # interactive()
release <- dig_release(249504)
dig_tracklist(release)
dig_credits(release)
dig_formats(release)
dig_identifiers(release)
dig_companies(release)
}
```
