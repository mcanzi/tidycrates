test_that("dig_auth sets and removes the token", {
  local_dig_state()
  expect_message(set <- dig_auth("abc"), "with a token")
  expect_true(set)
  expect_equal(auth_token(), "abc")
  expect_message(set <- dig_auth(""), "without a token")
  expect_false(set)
  expect_null(auth_token())
})

test_that("the environment variable is used until dig_auth is called", {
  local_dig_state()
  rm("token", envir = dig_env)
  withr::local_envvar(DISCOGS_TOKEN = "from-env")
  expect_equal(auth_token(), "from-env")
  suppressMessages(dig_auth(""))
  expect_null(auth_token())
})

test_that("dig_auth rejects anything but a single string", {
  local_dig_state()
  expect_error(dig_auth(1), "single string")
  expect_error(dig_auth(c("a", "b")), "single string")
  expect_error(dig_auth(NA_character_), "single string")
})

test_that("dig_user_agent puts the application in front of the default", {
  local_dig_state()
  default <- dig_user_agent()
  expect_match(default, "^tidycrates/[0-9.]+ \\(\\+https://github.com/mcanzi/tidycrates\\)$")
  expect_invisible(dig_user_agent("MyApp/1.0"))
  expect_equal(dig_user_agent(), paste("MyApp/1.0", default))
  dig_user_agent("")
  expect_equal(dig_user_agent(), default)
})

test_that("tokens are trimmed", {
  local_dig_state()
  suppressMessages(dig_auth("  abc\n"))
  expect_equal(auth_token(), "abc")
  suppressMessages(dig_auth(" "))
  expect_null(auth_token())
})

test_that("the user agent is squished", {
  local_dig_state()
  dig_user_agent(" My App/1.0\n")
  expect_match(dig_user_agent(), "^My App/1.0 tidycrates/")
})

test_that("tokens with spaces or line breaks inside are rejected", {
  local_dig_state()
  expect_error(dig_auth("abc def"), "spaces or line breaks")
  expect_error(dig_auth("abc\r\nX-Other: 1"), "spaces or line breaks")
  rm("token", envir = dig_env)
  withr::local_envvar(DISCOGS_TOKEN = "abc\ndef")
  expect_error(dig_release(1), "DISCOGS_TOKEN")
})
