invisible(Sys.setlocale("LC_CTYPE", "en_US.UTF-8"))

dir <- file.path("tests", "testthat", "fixtures")

write_fixture <- function(x, name) {
  jsonlite::write_json(x, file.path(dir, paste0(name, ".json")), auto_unbox = TRUE, pretty = TRUE, null = "null")
}

pages <- function(per_page, pages, items) {
  list(page = 1, pages = pages, per_page = per_page, items = items, urls = setNames(list(), character()))
}

juniper <- list(name = "Juniper Static", anv = "", join = "", role = "", tracks = "", id = 3001)

fernhollow <- list(name = "Fernhollow Records", catno = "FHR 007", entity_type = "1", entity_type_name = "Label", id = 4001)

credit <- function(name, anv, role, id) {
  list(name = name, anv = anv, join = "", role = role, tracks = "", id = id)
}

company <- function(name, role, id) {
  list(name = name, catno = "", entity_type = "13", entity_type_name = role, id = id)
}

write_fixture(
  list(
    id = 1001,
    status = "Accepted",
    year = 1994,
    uri = "https://example.com/release/1001",
    artists = list(juniper),
    artists_sort = "Juniper Static",
    labels = list(fernhollow),
    series = list(),
    companies = list(
      company("Fernhollow Records Ltd.", "Phonographic Copyright (p)", 4002),
      company("Fernhollow Records Ltd.", "Copyright (c)", 4002),
      company("Lantern Songs", "Published By", 4003),
      company("Mossbank Studio", "Recorded At", 4004),
      company("Mossbank Studio", "Lacquer Cut At", 4004),
      company("Tidewater Pressing", "Pressed By", 4005)
    ),
    formats = list(list(name = "Vinyl", qty = "1", descriptions = list("7\"", "45 RPM", "Single", "Stereo"))),
    data_quality = "Correct",
    community = list(have = 120, want = 45, rating = list(count = 12, average = 4.25), data_quality = "Correct", status = "Accepted"),
    format_quantity = 1,
    date_added = "2004-04-30T08:10:05-07:00",
    date_changed = "2021-06-02T03:15:44-07:00",
    title = "Lantern Weather",
    country = "UK",
    released = "1994-07-00",
    notes = "Made-up release for testing. It does not exist.",
    released_formatted = "Jul 1994",
    identifiers = list(
      list(type = "Barcode", value = "5000000000017"),
      list(type = "Label Code", value = "LC 00007"),
      list(type = "Price Code", value = "B", description = "D:")
    ),
    genres = list("Electronic", "Pop"),
    styles = list("Downtempo"),
    master_id = 2001,
    tracklist = list(
      list(position = "A", type_ = "track", title = "Lantern Weather", duration = "3:32"),
      list(position = "B", type_ = "track", title = "Lantern Weather (Dub)", duration = "3:30")
    ),
    extraartists = list(
      credit("Paperweight Design", "Paperweight", "Design", 3101),
      credit("Ida Marsh", "", "Engineer", 3102),
      credit("Tomas Reed", "", "Engineer", 3103),
      credit("Noor Halden", "NH", "Lacquer Cut By", 3104),
      credit("Felix Arno", "Felix A.", "Mixed By", 3105),
      credit("Malin \u00d6degaard", "M. \u00d6degaard", "Producer, Written-By", 3106)
    )
  ),
  "release-1001"
)

atlas <- c(
  "Small Hours", "Quiet Engine", "Tin Roof Choir", "Harbour Lights", "Moth Radio", "Glasshouse",
  "Northbound Static", "Paper Moon Signal", "Low Tide Waltz", "Ember Lane", "Atlas (Reprise)"
)

write_fixture(
  list(
    id = 2001,
    main_release = 1001,
    most_recent_release = 1006,
    genres = list("Electronic", "Pop"),
    styles = list("Downtempo"),
    year = 1994,
    tracklist = purrr::map(seq_along(atlas), \(i) list(position = as.character(i), type_ = "track", title = atlas[[i]], duration = paste0(3 + i %% 4, ":", sprintf("%02d", (i * 7) %% 60)))),
    artists = list(juniper),
    title = "Small Hours Atlas",
    data_quality = "Correct",
    uri = "https://example.com/master/2001"
  ),
  "master-2001"
)

alias <- function(name, id) {
  list(id = id, name = name)
}

write_fixture(
  list(
    name = "Juniper Static",
    id = 3001,
    uri = "https://example.com/artist/3001",
    profile = "Made-up artist for testing, sometimes working with [a=Felix Arno].",
    urls = list("https://example.com/juniper-static"),
    namevariations = list("Juniper Static.", "J. Static"),
    aliases = list(
      alias("Malin \u00d6degaard", 3106),
      alias("Moth Radio", 3201),
      alias("Low Tide", 3202),
      alias("Ember Lane", 3203),
      alias("Quiet Engine", 3204),
      alias("Harbour Lights", 3205),
      alias("Tin Roof", 3206)
    ),
    realname = "Malin \u00d6degaard",
    data_quality = "Needs Vote"
  ),
  "artist-3001"
)

write_fixture(
  list(
    id = 4001,
    name = "Fernhollow Records",
    uri = "https://example.com/label/4001",
    profile = "Made-up label for testing.",
    contact_info = "Fernhollow Records\n1 Example Street\nNowhere",
    urls = list("https://example.com/fernhollow"),
    sublabels = purrr::map(1:8, \(i) list(id = 4100 + i, name = paste("Fernhollow Sublabel", i))),
    data_quality = "Needs Vote"
  ),
  "label-4001"
)

write_fixture(
  list(
    pagination = pages(3, 44, 132),
    releases = list(
      list(id = 1004, status = "Accepted", type = "release", format = "10\"", label = "Fernhollow Records", title = "Moth Radio", role = "Main", artist = "Juniper Static & Felix Arno", year = 1997, stats = list(community = list(in_wantlist = 160, in_collection = 43))),
      list(id = 2001, type = "master", main_release = 1001, title = "Small Hours Atlas", role = "Main", artist = "Juniper Static", year = 1997, stats = list(community = list(in_wantlist = 90, in_collection = 70))),
      list(id = 2002, type = "master", main_release = 1007, title = "Paper Moon Signal", role = "Main", artist = "Juniper Static", year = 1997, stats = list(community = list(in_wantlist = 30, in_collection = 25)))
    )
  ),
  "artist-3001-releases"
)

write_fixture(
  list(
    pagination = pages(3, 199, 597),
    releases = list(
      list(status = "Accepted", format = "CD, Comp, Mixed", catno = "FHR 010", title = "Fernhollow Nights", id = 1001, year = 1998, artist = "Felix Arno"),
      list(status = "Accepted", format = "2x12\", Comp", catno = "FHR 011", title = "Tidewater Sessions", id = 1002, year = 1998, artist = "Various"),
      list(status = "Accepted", format = "CD, Mixed, RP", catno = "FHR 012", title = "Low Tide Mix", id = 1003, year = 0, artist = "Ida Marsh")
    )
  ),
  "label-4001-releases"
)

version <- function(id, country, format, catno) {
  list(
    id = id, label = "Fernhollow Records", country = country, title = "Small Hours Atlas",
    major_formats = list(format), format = "Album", catno = catno, released = "1997", status = "Accepted",
    stats = list(community = list(in_wantlist = 10, in_collection = 5))
  )
}

write_fixture(
  list(
    pagination = pages(3, 3, 8),
    versions = list(
      version(1001, "Bulgaria", "Cassette", "FHR 001 MC"),
      version(1005, "UK & France", "CD", "FHR 001 CD"),
      version(1006, "Poland", "Cassette", "FHR 001 PL")
    )
  ),
  "master-2001-versions"
)

basic <- function(id, master_id, title, year, format, descriptions, labels, artist, genres, styles) {
  list(
    id = id, master_id = master_id, title = title, year = year,
    formats = list(list(name = format, qty = "1", descriptions = as.list(descriptions))),
    labels = purrr::map(labels, \(l) list(name = l, catno = "FHR 007", entity_type = "1", id = 4001)),
    artists = list(list(name = artist, anv = "", join = "", role = "", tracks = "", id = 3001)),
    genres = as.list(genres),
    styles = as.list(styles)
  )
}

lantern <- basic(1001, 2001, "Lantern Weather", 1994, "Vinyl", c("7\"", "Single", "45 RPM"), "Fernhollow Records", "Juniper Static", c("Electronic", "Pop"), "Downtempo")

write_fixture(
  list(
    pagination = pages(3, 2, 5),
    releases = list(
      list(id = 1001, instance_id = 101, folder_id = 1, rating = 4, date_added = "2024-03-02T10:15:30-08:00", basic_information = lantern, notes = list(list(field_id = 1, value = "Near Mint (NM or M-)"))),
      list(id = 1001, instance_id = 102, folder_id = 1, rating = 0, date_added = "2024-05-20T08:00:00-07:00", basic_information = lantern),
      list(
        id = 1002, instance_id = 103, folder_id = 2, rating = 5, date_added = "2025-01-11T19:45:00-08:00",
        basic_information = basic(1002, 0, "Tidewater Sessions", 0, "CD", c("Compilation", "Mixed"), c("Fernhollow Records", "Fernhollow Records"), "Felix Arno", "Electronic", character())
      )
    )
  ),
  "collection-example"
)

write_fixture(
  list(
    pagination = pages(50, 1, 2),
    wants = list(
      list(
        id = 1003, rating = 0, notes = "Only the first pressing.", date_added = "2023-11-05T12:00:00-08:00",
        basic_information = basic(1003, 0, "Low Tide Mix", 1998, "CD", "Mixed", "Fernhollow Records", "Ida Marsh", "Electronic", c("Downtempo", "Electro"))
      ),
      list(
        id = 1002, rating = 3, notes = "", date_added = "2024-02-14T09:30:00-08:00",
        basic_information = basic(1002, 2002, "Tidewater Sessions", 1998, "Vinyl", c("12\"", "Compilation"), "Fernhollow Records", "Various", "Electronic", "Techno")
      )
    )
  ),
  "wantlist-example"
)

write_fixture(
  list(lowest_price = list(currency = "EUR", value = 4.5), num_for_sale = 12, blocked_from_sale = FALSE),
  "price-stats-1001"
)

write_fixture(
  list(lowest_price = NULL, num_for_sale = NULL, blocked_from_sale = FALSE),
  "price-stats-1002"
)

write_fixture(
  list(lowest_price = NULL, num_for_sale = NULL, blocked_from_sale = TRUE),
  "price-stats-1003"
)

suggestion <- function(value) {
  list(currency = "EUR", value = value)
}

write_fixture(
  list(
    `Very Good (VG)` = suggestion(6.78),
    `Good Plus (G+)` = suggestion(3.77),
    `Near Mint (NM or M-)` = suggestion(12.81),
    `Good (G)` = suggestion(2.26),
    `Very Good Plus (VG+)` = suggestion(9.8),
    `Mint (M)` = suggestion(14.32),
    `Fair (F)` = suggestion(1.51),
    `Poor (P)` = suggestion(0.75)
  ),
  "price-suggestions-1001"
)

write_fixture(setNames(list(), character()), "price-suggestions-1002")

write_fixture(
  list(maximum = "€1.250,00", median = "€480,25", minimum = "€75,50"),
  "collection-value-example"
)
