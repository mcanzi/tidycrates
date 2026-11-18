# Set the 'Discogs' token

Sets the personal access token used for requests in this session. With a
token, 'Discogs' allows 60 requests a minute instead of 25,
[`dig_collection()`](https://mcanzi.de/tidycrates/reference/dig_collection.md)
and
[`dig_wantlist()`](https://mcanzi.de/tidycrates/reference/dig_wantlist.md)
can read your own collection and wantlist when they are private, and
[`dig_search()`](https://mcanzi.de/tidycrates/reference/dig_search.md),
[`dig_price_suggestions()`](https://mcanzi.de/tidycrates/reference/dig_price_suggestions.md)
and
[`dig_collection_value()`](https://mcanzi.de/tidycrates/reference/dig_collection_value.md)
work. A token can be generated at
<https://www.discogs.com/settings/developers>.

## Usage

``` r
dig_auth(token = Sys.getenv("DISCOGS_TOKEN"))
```

## Arguments

- token:

  A personal access token. By default the value of the `DISCOGS_TOKEN`
  environment variable. An empty string removes the token, so requests
  are made without one. Spaces at either end are removed, and a token
  with spaces or line breaks inside is rejected.

## Value

`TRUE` if a token is set and `FALSE` otherwise, invisibly.

## Details

If `dig_auth()` is never called, the `DISCOGS_TOKEN` environment
variable is used. Storing the token in `.Renviron` keeps it out of your
scripts.

## Examples

``` r
if (FALSE) { # interactive()
dig_auth()
}
```
