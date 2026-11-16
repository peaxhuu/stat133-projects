#' Get BART stations
#'
#' Requests the list of BART stations from the BART API and returns one row
#' per station with its location.
#'
#' @param key A BART API key. Defaults to BART's public key.
#'
#' @returns A data frame with one row per station and columns `abbr`
#'   (station abbreviation), `name`, `city`, `county`, `lat` and `lon`
#'   (latitude and longitude, as numbers).
#'
#' @examplesIf interactive()
#' stations <- bart_stations()
#' head(stations)
#'
#' @export
bart_stations <- function(key = "MW9S-E7SL-26DU-VV8V") {
  # Same request as PS 6, but req_url_query() builds the ?a=b&c=d part for us
  resp <- httr2::request("https://api.bart.gov/api/stn.aspx") |>
    httr2::req_url_query(cmd = "stns", key = key, json = "y") |>
    httr2::req_perform() |>
    httr2::resp_body_json(simplifyVector = TRUE)

  # With simplifyVector = TRUE, the list of stations becomes a data frame
  st <- resp$root$stations$station

  # Pick columns in the order Part 1 asks for. Every value BART sends is a
  # string, so the coordinates need as.numeric().
  tibble::tibble(
    abbr   = st$abbr,
    name   = st$name,
    city   = st$city,
    county = st$county,
    lat    = as.numeric(st$gtfs_latitude),
    lon    = as.numeric(st$gtfs_longitude)
  )
}
