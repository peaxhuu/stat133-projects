devtools::load_all()
library(dplyr)

stations <- bart_stations()

# DBRK -> DBRK makes BART return HTTP 400 (Part 2's bug), so skip it for now.
# Once you fix bart_trip("DBRK"), you can switch back to stations$abbr.
origins <- setdiff(stations$abbr, "DBRK")

trips <- lapply(origins, bart_trip) |>
  bind_rows()

commutes <- left_join(stations, trips, by = c("abbr" = "orig")) |>
  filter(!is.na(minutes))

usethis::use_data(commutes, overwrite = TRUE)
