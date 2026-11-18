# Get marketplace statistics

Gets the lowest price and the number of copies for sale of releases in
the 'Discogs' marketplace. A token is not needed.

## Usage

``` r
dig_price_stats(id, currency = NULL)
```

## Arguments

- id:

  One or more release IDs, as numbers or as codes copied from 'Discogs'
  such as `"r249504"` or `"[r249504]"`.

- currency:

  The currency of the prices, one of `"USD"`, `"GBP"`, `"EUR"`, `"CAD"`,
  `"AUD"`, `"JPY"`, `"CHF"`, `"MXN"`, `"BRL"`, `"NZD"`, `"SEK"` or
  `"ZAR"`, or `NULL` for the default.

## Value

A tibble with one row per release, or `NULL` invisibly if the API cannot
be reached. The columns are `release_id`, `lowest_price`, `currency`,
`for_sale`, the number of copies for sale, and `blocked`, which is
`TRUE` if the release may not be sold. `lowest_price` and `currency` are
`NA` if no copy is for sale, and `for_sale` is `NA` if the release is
blocked.

## Details

Prices change quickly, so these requests are never cached. Without a
token and without `currency`, prices are in US dollars. With a token,
they are in the buyer currency of your account.

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
dig_price_stats(249504, currency = "EUR")
}
```
