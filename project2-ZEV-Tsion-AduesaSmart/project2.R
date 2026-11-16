library(readxl)
zev <- read_excel("data/New_ZEV_Sales_Last_updated_07-17-2026_ada.xlsx",
  sheet = "County")

library(readxl)
library(dplyr)
library(tidyr)

zev <- read_excel("data/New_ZEV_Sales_Last_updated_07-17-2026_ada.xlsx",
                  sheet = "County") |>
  rename(year = `Data Year`, quarter = Quarter, county = COUNTY,
         fuel = FUEL_TYPE, make = MAKE, model = MODEL,
         n = `Number of Vehicles`) |>
  mutate(fuel = factor(fuel,
                       levels = c("Electric", "PHEV", "Hydrogen"),
                       labels = c("BEV", "PHEV", "FCEV")))

zev |> summarise(total = sum(n))
zev |> filter(county != "Out Of State") |> summarise(total = sum(n))

zev |> filter(year == 2026) |> summarise(total = sum(n))

zev |> filter(year == 2026, county == "Alameda") |> summarise(total = sum(n))

zev |>
  filter(year == 2026) |>
  count(fuel, wt = n) |>
  mutate(prop = n / sum(n))

zev |>
  filter(year == 2026, make == "Tesla") |>
  count(model, wt = n, sort = TRUE)

zev |>
  filter(year == 2026) |>
  count(make, model, wt = n) |>
  arrange(make, desc(n))

zev |>
  filter(year %in% 2024:2025, fuel != "FCEV") |>
  group_by(year, quarter, fuel) |>
  summarise(n = sum(n), .groups = "drop") |>
  pivot_wider(names_from = year, values_from = n, names_prefix = "y") |>
  mutate(yoy_change = y2025 / y2024 - 1)

zev |>
  filter(year %in% 2022:2025, fuel != "FCEV", quarter %in% 3:4) |>
  group_by(year, fuel, quarter) |>
  summarise(n = sum(n), .groups = "drop") |>
  pivot_wider(names_from = quarter, values_from = n, names_prefix = "Q") |>
  mutate(q4_over_q3 = Q4 / Q3)

hhi <- function(d) {
  d |>
    group_by(year, make) |>
    summarise(n = sum(n), .groups = "drop") |>
    group_by(year) |>
    mutate(share = 100 * n / sum(n)) |>
    summarise(hhi = sum(share^2),
              n_makes = n(),
              tesla_share = sum(share[make == "Tesla"]))
}

hhi(zev) |> filter(year >= 2018)
hhi(filter(zev, make != "Tesla")) |> filter(year >= 2018) |> select(year, hhi_ex_tesla = hhi)

dem_counties <- c("Alameda", "San Francisco", "Santa Clara", "Marin",
                  "San Mateo", "Los Angeles", "Santa Cruz", "Humboldt")
rep_counties <- c("Kern", "Shasta", "Modoc", "Lassen", "Tehama", "Kings",
                  "Placer", "El Dorado")

tesla_lean <- zev |>
  filter(county %in% c(dem_counties, rep_counties), year >= 2021) |>
  mutate(lean = if_else(county %in% dem_counties, "Dem", "Rep"))

# Annual share
tesla_lean |>
  group_by(lean, year) |>
  summarise(share = sum(n[make == "Tesla"]) / sum(n), .groups = "drop") |>
  pivot_wider(names_from = lean, values_from = share) |>
  mutate(gap = Dem - Rep)

# H1 only, so 2026 is comparable
tesla_lean |>
  filter(year >= 2023, quarter <= 2) |>
  group_by(lean, year) |>
  summarise(share = sum(n[make == "Tesla"]) / sum(n), .groups = "drop") |>
  pivot_wider(names_from = lean, values_from = share) |>
  mutate(gap = Dem - Rep)

# County-level change in Tesla share, 2024 to 2025
tesla_lean |>
  filter(year %in% 2024:2025) |>
  group_by(lean, county, year) |>
  summarise(share = sum(n[make == "Tesla"]) / sum(n), total = sum(n),
            .groups = "drop") |>
  pivot_wider(names_from = year, values_from = c(share, total)) |>
  mutate(change = share_2025 - share_2024) |>
  arrange(lean, change)