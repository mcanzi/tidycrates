# Set the user agent

'Discogs' asks every application to identify itself with a user agent.
Requests are sent as
`tidycrates/<version> (+https://github.com/mcanzi/tidycrates)` by
default. A name set here is placed in front, so requests from your
script or application can be told apart.

## Usage

``` r
dig_user_agent(agent = NULL)
```

## Arguments

- agent:

  The name and version of your application, for example
  `"MyCollectionStats/1.0"`. `NULL` returns the current user agent
  without changing it, and an empty string restores the default.

## Value

The user agent, invisibly if `agent` is given.

## Examples

``` r
dig_user_agent()
#> [1] "tidycrates/0.0.0.9000 (+https://github.com/mcanzi/tidycrates)"
```
