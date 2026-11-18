# Check the rate limit

Asks 'Discogs' how many requests are left in the current window. The
check is a request itself and counts towards the limit.

## Usage

``` r
dig_rate_limit()
```

## Value

A tibble with one row and the columns `limit`, `used`, `remaining` and
`authenticated`, or `NULL` invisibly if the API cannot be reached.

## Details

'Discogs' allows 60 requests a minute with a token and 25 without,
counted over a moving window of 60 seconds. Requests made by tidycrates
are spaced out to stay within the limit and retried after HTTP 429
responses, so the limit only needs checking when other applications
share the same token or IP address.

## Examples

``` r
if (FALSE) { # interactive()
dig_rate_limit()
}
```
