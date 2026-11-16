# ---- Typical inputs: shape ----
test_that("bart_trip() returns one row with the seven columns in order", {
  skip_if_offline()
  trip <- bart_trip("MLBR")

  expect_equal(nrow(trip), 1)
  expect_named(trip, c("orig", "dest", "depart", "arrive",
                       "minutes", "fare", "transfers"))
})

# ---- Typical inputs: rules every trip follows ----
test_that("trips arrive by arrive_by", {
  skip_if_offline()
  trips <- rbind(bart_trip("MLBR"), bart_trip("DUBL"), bart_trip("RICH"))
  deadline <- lubridate::mdy_hm("11/18/2026 08:45 AM", tz = "America/Los_Angeles")

  expect_true(all(trips$arrive <= deadline))
})

test_that("minutes matches the time between depart and arrive", {
  skip_if_offline()
  trips <- rbind(bart_trip("MLBR"), bart_trip("DUBL"), bart_trip("RICH"))
  elapsed <- as.numeric(difftime(trips$arrive, trips$depart, units = "mins"))

  expect_equal(trips$minutes, elapsed)
})

test_that("fares and trip lengths are positive", {
  skip_if_offline()
  trips <- rbind(bart_trip("MLBR"), bart_trip("DUBL"), bart_trip("RICH"))

  expect_true(all(trips$fare > 0))
  expect_true(all(trips$minutes > 0))
})

# ---- Edge cases ----
test_that("a trip from Millbrae has no transfers", {
  skip_if_offline()
  expect_equal(bart_trip("MLBR")$transfers, 0)
})

test_that("a trip from Dublin/Pleasanton has one transfer", {
  skip_if_offline()
  expect_equal(bart_trip("DUBL")$transfers, 1)
})

# ---- Errors ----
test_that("bart_trip() stops with a clear message when orig isn't a single string", {
  expect_error(bart_trip(c("MLBR", "DUBL")), "single station abbreviation")
})

test_that("a station that doesn't exist gives an error", {
  skip_if_offline()
  expect_error(bart_trip("XXXX"))
})

# ---- Bug: a classmate's report ----
test_that("a trip from Downtown Berkeley to itself is a zero commute", {
  trip <- bart_trip("DBRK")

  expect_false(is.na(trip$depart))
  expect_named(trip, c("orig", "dest", "depart", "arrive",
                       "minutes", "fare", "transfers"))
  expect_equal(trip$minutes, 0)
  expect_equal(trip$fare, 0)
  expect_equal(trip$transfers, 0)
  expect_equal(trip$depart, trip$arrive)
})


