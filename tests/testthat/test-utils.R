test_that("durations that are not clock times give NA", {
  expect_equal(
    as_seconds(c("3:32", " 3:32 ", "1:02:03", "0:05", "3.32", "3'32", "3:32.5", "12", "3:75", "", NA)),
    c(212L, 212L, 3723L, 5L, NA, NA, NA, NA, NA, NA, NA)
  )
  expect_silent(as_seconds("99999999:00:00"))
})

test_that("dates with offsets, Z or fractions are read", {
  out <- as_datetime(c(
    "2004-04-30T08:10:05-07:00", "2004-04-30T15:10:05Z",
    "2004-04-30T08:10:05.123-07:00", "2004-04-30", NA
  ))
  expect_equal(format(out[1:3], "%Y-%m-%d %H:%M:%S"), rep("2004-04-30 15:10:05", 3))
  expect_true(all(is.na(out[4:5])))
})

test_that("joins with spaces are trimmed", {
  artists <- list(list(name = "A", join = ", "), list(name = "B", join = " & "), list(name = "C"))
  expect_equal(artist_names(artists), "A, B & C")
})

test_that("a single record is treated as a list of one", {
  expect_equal(as_items(list(name = "A")), list(list(name = "A")))
  expect_equal(as_items(list(list(name = "A"), "x")), list(list(name = "A")))
  expect_equal(as_items("x"), list())
})

test_that("fields are matched exactly", {
  body <- list(artists_sort = "Wrong", tracklist = list(list(title = "T", artists_x = "Wrong")))
  out <- parse_release(body)
  expect_true(is.na(out$artist))
  expect_true(is.na(out$tracklist[[1]]$artist))
})

test_that("unknown release dates give NA", {
  expect_equal(as_released(c("1997", "1987-07-00", "0", "0000-00-00", NA)), c("1997", "1987-07-00", NA, NA, NA))
})
