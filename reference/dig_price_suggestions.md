# Get price suggestions

Gets the prices 'Discogs' suggests for releases in each condition, from
Mint to Poor. Price suggestions need a token, see
[`dig_auth()`](https://mcanzi.de/tidycrates/reference/dig_auth.md), and
the seller settings of the account must be filled in on 'Discogs'.

## Usage

``` r
dig_price_suggestions(id)
```

## Arguments

- id:

  One or more release IDs, as numbers or as codes copied from 'Discogs'
  such as `"r249504"` or `"[r249504]"`.

## Value

A tibble with one row per release and condition, or `NULL` invisibly if
the API cannot be reached. The columns are `release_id`, `condition`, a
factor from best to worst, `price` and `currency`. A release without
suggestions has no rows.

## Details

The prices are in the selling currency of your account. They are never
cached, because they change quickly.

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
dig_price_suggestions(249504)
}
```
