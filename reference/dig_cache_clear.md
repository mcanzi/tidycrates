# Clear the cache

Removes the responses that were cached because the option
`tidycrates.cache` is `TRUE`, and the username found for the token by
functions such as
[`dig_collection()`](https://mcanzi.de/tidycrates/reference/dig_collection.md).
The next requests are sent to 'Discogs' again.

## Usage

``` r
dig_cache_clear()
```

## Value

`NULL`, invisibly.

## Examples

``` r
dig_cache_clear()
```
