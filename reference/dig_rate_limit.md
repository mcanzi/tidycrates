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
counted over a moving window of 60 seconds. tidycrates sends up to 59
requests with a token, or 24 without, in any 60 seconds, and requests
beyond that wait for room in the window. Requests are retried after HTTP
429 and 503 responses, and a message says how long each wait of a second
or more takes. The limit only needs checking when other applications
share the same token or IP address.

## Examples

``` r
if (FALSE) { # interactive()
dig_rate_limit()
}
```
