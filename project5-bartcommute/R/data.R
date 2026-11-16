#' Commutes from BART stations to Downtown Berkeley
#'
#' The last BART trip from each station that reaches Downtown Berkeley by
#' 8:45 am on Wednesday, November 18, 2026, joined to the station's location.
#'
#' @format A data frame with one row per station (Downtown Berkeley itself
#'   excluded) and 12 columns:
#' \describe{
#'   \item{abbr}{Station abbreviation}
#'   \item{name}{Station name}
#'   \item{city}{City the station is in}
#'   \item{county}{County the station is in, as BART writes it}
#'   \item{lat, lon}{Station latitude and longitude, in degrees}
#'   \item{dest}{Destination station abbreviation (DBRK)}
#'   \item{depart}{When the trip leaves the station, Pacific time}
#'   \item{arrive}{When the trip reaches Downtown Berkeley, Pacific time}
#'   \item{minutes}{Length of the trip, in minutes}
#'   \item{fare}{One-way adult Clipper fare, in US dollars}
#'   \item{transfers}{Number of times you change trains}
#' }
#' @source BART API trip planner
#'   (\url{https://api.bart.gov/docs/sched/arrive.aspx}) and station list
#'   (\url{https://api.bart.gov/docs/stn/stns.aspx}), requested
#'   November 13, 2026.
"commutes"
