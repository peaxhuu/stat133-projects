test_that("bart_stations() returns the six columns in order, with numeric coordinates", {
  skip_if_offline()
  stations <- bart_stations()

  expect_named(stations, c("abbr", "name", "city", "county", "lat", "lon"))
  expect_type(stations$lat, "double")
  expect_type(stations$lon, "double")
})
