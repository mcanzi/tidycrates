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

'Discogs' allows 60 requests a minute with a token and 25 without, and
tracks them with a moving average over a 60 second window. The window
resets after 60 seconds without requests. tidycrates sends up to 59
requests with a token, or 24 without, in any 60 seconds, and requests
beyond that wait for room. When a response says that no requests are
left, for example because other applications use the same token, the
next request waits 60 seconds so that the window resets. Requests are
retried after HTTP 429 and 503 responses, and a message says how long
each wait of a second or more takes. The limit only needs checking when
other applications share the same token or IP address.

## Examples

``` r
if (FALSE) { # interactive()
dig_rate_limit()
}
```
