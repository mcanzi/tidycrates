# List the collection folders of a user

Lists the folders of a 'Discogs' collection, with the number of releases
in each. Folder `0` holds the whole collection and folder `1` holds the
releases that are in no other folder. Other users can only see folder
`0`, unless the collection is read with the token of its owner, see
[`dig_auth()`](https://mcanzi.de/tidycrates/reference/dig_auth.md).
Folders are never cached.

## Usage

``` r
dig_collection_folders(username = NULL)
```

## Arguments

- username:

  A 'Discogs' username, or `NULL` for the owner of the token set with
  [`dig_auth()`](https://mcanzi.de/tidycrates/reference/dig_auth.md).
  Finding the owner takes one request, once per session.

## Value

A tibble with one row per folder and the columns `folder_id`, `name` and
`count`, or `NULL` invisibly if the API cannot be reached. `folder_id`
can be passed to
[`dig_collection()`](https://mcanzi.de/tidycrates/reference/dig_collection.md).

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
dig_collection_folders("username")
}
```
