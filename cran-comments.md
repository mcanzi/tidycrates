## Submission

This is a new submission.

## R CMD check results

0 errors | 0 warnings | 1 note

* This is a new submission.

## Internet access

The package reads the 'Discogs' API. Examples that need the internet run
only in interactive sessions, and the tests use recorded, made-up
responses, so checks send no requests. When the API cannot be reached,
functions give a message and return `NULL`.

## URLs

The links to www.discogs.com and support.discogs.com may return HTTP 403
to automated checks, because the site blocks requests that do not come
from a browser. The links work in a browser.
