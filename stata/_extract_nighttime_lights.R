library(terra)
library(readr)
library(dplyr)
library(haven)

root <- "G:/My Drive/socio bosque"
ntl_dir <- file.path(root, "processed_data", "nighttime lights")
points_csv <- file.path(ntl_dir, "nighttime_lights_unique_points.csv")
out_csv <- file.path(ntl_dir, "nighttime_lights_long.csv")
out_dta <- file.path(ntl_dir, "nighttime_lights_long.dta")

points <- read_csv(points_csv, show_col_types = FALSE) |>
  transmute(
    pointid = as.integer(pointid),
    x = as.numeric(x),
    y = as.numeric(y)
  ) |>
  distinct(pointid, x, y)

tifs <- list.files(
  ntl_dir,
  pattern = "^Harmonized_DN_NTL_[0-9]{4}_(calDMSP|simVIIRS)\\.tif$",
  full.names = TRUE
)

years <- as.integer(sub(".*_([0-9]{4})_.*", "\\1", basename(tifs)))
keep <- years >= 1996 & years <= 2020
tifs <- tifs[keep]
years <- years[keep]
ord <- order(years)
tifs <- tifs[ord]
years <- years[ord]

if (length(tifs) == 0) {
  stop("No nighttime lights TIFFs found for 1996-2020.")
}

xy <- as.matrix(points[, c("x", "y")])

extract_one <- function(path, year) {
  message("Extracting nighttime lights for ", year, ": ", basename(path))
  r <- rast(path)
  extracted <- terra::extract(r, xy)
  vals <- if (is.data.frame(extracted)) {
    extracted[[ncol(extracted)]]
  } else {
    extracted[, ncol(extracted)]
  }
  tibble(
    pointid = points$pointid,
    year = as.integer(year),
    nighttime_lights = as.numeric(vals)
  )
}

ntl_long <- bind_rows(Map(extract_one, tifs, years)) |>
  arrange(pointid, year)

attr(ntl_long$pointid, "label") <- "Point ID"
attr(ntl_long$year, "label") <- "Year"
attr(ntl_long$nighttime_lights, "label") <- "Nighttime lights (harmonized DN)"

write_csv(ntl_long, out_csv, na = "")
write_dta(ntl_long, out_dta, version = 14)

message("Saved: ", out_csv)
message("Saved: ", out_dta)
message("Rows: ", nrow(ntl_long), "; points: ", n_distinct(ntl_long$pointid), "; years: ", n_distinct(ntl_long$year))
