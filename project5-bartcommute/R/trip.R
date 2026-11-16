#' Plan a BART trip that arrives by a given time
#'
#' Asks BART's trip planner for the last trip from `orig` that reaches
#' `dest` by `arrive_by` on `date`, and returns its times, fare and
#' number of transfers.
#'
#' @param orig Abbreviation of the station the trip starts at, such as
#'   `"MLBR"`. Must be a single string.
#' @param dest Abbreviation of the station the trip ends at. Defaults to
#'   Downtown Berkeley, `"DBRK"`.
#' @param arrive_by The latest arrival time, as BART writes it, such as
#'   `"8:45am"`.
#' @param date The date of the trip, as `"mm/dd/yyyy"`.
#' @param key A BART API key. Defaults to BART's public key.
#'
#' @returns A data frame with one row and columns `orig` and `dest`
#'   (station abbreviations), `depart` and `arrive` (date-times in Pacific
#'   time), `minutes` (trip length), `fare` (adult Clipper fare, in dollars)
#'   and `transfers` (number of train changes).
#'
#' @examplesIf interactive()
#' bart_trip("MLBR")
#' bart_trip("DUBL", arrive_by = "10:00am")
#'
#' @export
bart_trip <- function(orig, dest = "DBRK", arrive_by = "8:45am",
                      date = "11/18/2026", key = "MW9S-E7SL-26DU-VV8V") {
  # Check the input before spending a request on it (Part 2's error test)
  if (!is.character(orig) || length(orig) != 1) {
    stop("`orig` must be a single station abbreviation, like \"MLBR\".",
         call. = FALSE)
  }

  # A trip from a station to itself: BART refuses it (HTTP 400), but living
  # at the destination is a real answer, so return a zero commute.
  if (orig == dest) {
    at <- lubridate::mdy_hm(paste(date, arrive_by), tz = "America/Los_Angeles")
    return(tibble::tibble(
      orig = orig, dest = dest, depart = at, arrive = at,
      minutes = 0, fare = 0, transfers = 0L
    ))
  }

  # The Part 1 URL, with the arguments filled in.
  # If BART answers 400, req_perform() stops with that error for us.
  resp <- httr2::request("https://api.bart.gov/api/sched.aspx") |>
    httr2::req_url_query(
      cmd = "arrive", orig = orig, dest = dest,
      date = date, time = arrive_by,
      b = 0, a = 0, key = key, json = "y"
    ) |>
    httr2::req_perform() |>
    httr2::resp_body_json()

  trip <- resp$root$schedule$request$trip
  trip <- one_item(trip)

  # Each train you ride is one leg. BART's JSON is converted from XML, so a
  # single leg arrives as an object instead of an array of one; as_items()
  # makes both cases a list of legs.
  legs <- as_items(trip$leg)

  # Times come in two pieces: "11/18/2026 " and "07:31 AM"
  depart <- lubridate::mdy_hm(
    paste(trimws(trip$`@origTimeDate`), trip$`@origTimeMin`),
    tz = "America/Los_Angeles"
  )
  arrive <- lubridate::mdy_hm(
    paste(trimws(trip$`@destTimeDate`), trip$`@destTimeMin`),
    tz = "America/Los_Angeles"
  )

  tibble::tibble(
    orig      = trip$`@origin`,
    dest      = trip$`@destination`,
    depart    = depart,
    arrive    = arrive,
    minutes   = as.numeric(trip$`@tripTime`),
    fare      = clipper_fare(trip),
    transfers = length(legs) - 1L
  )
}

# Helpers (not exported, so no @export) -----------------------------------

# A named list is one JSON object; an unnamed list is an array of objects.
as_items <- function(x) {
  if (!is.null(names(x))) list(x) else x
}

# The trip itself may also come as an array of one
one_item <- function(x) {
  as_items(x)[[1]]
}

# CHECK THIS against bart.gov's trip planner (Part 1 asks you to work out
# which field is the adult Clipper fare). If @fare or @clipper turns out
# to be the right one, replace the body with as.numeric(trip$`@fare`).
clipper_fare <- function(trip) {
  fares   <- as_items(trip$fares$fare)
  classes <- vapply(fares, function(f) f$`@class`, character(1))
  amounts <- vapply(fares, function(f) f$`@amount`, character(1))
  as.numeric(amounts[classes == "clipper"][1])
}
