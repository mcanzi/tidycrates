# Get the value of a collection

Gets the minimum, median and maximum value of a collection, as 'Discogs'
estimates it from marketplace sales. Only the owner of a collection can
get its value, so this needs the owner's token, see
[`dig_auth()`](https://mcanzi.de/tidycrates/reference/dig_auth.md).

## Usage

``` r
dig_collection_value(username)
```

## Arguments

- username:

  A 'Discogs' username.

## Value

A tibble with one row and the columns `username`, `minimum`, `median`,
`maximum` and `currency`, or `NULL` invisibly if the API cannot be
reached. A value that cannot be read is `NA`.

## Details

'Discogs' returns the values as formatted text, such as `"$1,250.00"`.
They are turned into numbers, and the currency symbol is kept in
`currency`. The value is never cached.

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
dig_collection_value("your-username")
}
```
