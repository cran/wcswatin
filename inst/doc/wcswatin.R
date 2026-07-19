## ----setup, include = FALSE---------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>",
  message = FALSE,
  warning = FALSE
)

## ----packages-----------------------------------------------------------------
library(wcswatin)

## ----example-data-------------------------------------------------------------
daily_nc <- system.file(
  "extdata/nc_data/daily_2m_temperature_daily_maximum_2025.nc",
  package = "wcswatin"
)

hourly_nc <- system.file(
  "extdata/nc_data/hourly_2m_temperature_2days_2025.nc",
  package = "wcswatin"
)

multi_nc <- system.file(
  "extdata/nc_data/hourly_multi_2days_2025.nc",
  package = "wcswatin"
)

stations_file <- system.file(
  "extdata/pcp_stations/pcp.txt",
  package = "wcswatin"
)

basin_file <- system.file(
  "extdata/sl_bassin/sl_bassin_limit.shp",
  package = "wcswatin"
)

basename(c(daily_nc, hourly_nc, multi_nc, stations_file, basin_file))

## ----raster-info--------------------------------------------------------------
raster_info(c(daily_nc, hourly_nc, multi_nc))
var_names(multi_nc)

## ----load-inputs--------------------------------------------------------------
daily_cube <- input_raster(daily_nc)
stations <- input_table(stations_file)
basin <- input_vector(basin_file)

daily_cube
head(stations)
basin

## ----extract-values-----------------------------------------------------------
station_values <- tbl_from_references(
  raster_file = daily_cube,
  ref_points = stations_file,
  prefix_colname = "t2m"
)

dim(station_values)
station_values[, 1:4]

## ----daily-aggregation--------------------------------------------------------
hourly_folder <- file.path(tempdir(), "wcswatin_hourly")
daily_folder <- file.path(tempdir(), "wcswatin_daily")
dir.create(hourly_folder, showWarnings = FALSE)

hourly_values <- data.frame(t2m = seq(280, 303, length.out = 48))
utils::write.table(
  hourly_values,
  file.path(hourly_folder, "t2m_20251001.txt"),
  row.names = FALSE,
  sep = ","
)

daily_aggregation(
  folder_in = hourly_folder,
  folder_out = daily_folder,
  from = "2025-10-01 00",
  to = "2025-10-02 23",
  drop_first_record = FALSE,
  aggregation_function = mean
)

input_table(file.path(daily_folder, "t2m_20251001.txt"))

## ----value-at-hour------------------------------------------------------------
accumulated_folder <- file.path(tempdir(), "wcswatin_accumulated")
dir.create(accumulated_folder, showWarnings = FALSE)

accumulated_values <- data.frame(tp = seq_len(24))
utils::write.table(
  accumulated_values,
  file.path(accumulated_folder, "tp_20251001.txt"),
  row.names = FALSE,
  sep = ","
)

value_hour_folder <- file.path(tempdir(), "wcswatin_value_hour")

daily_aggregation(
  folder_in = accumulated_folder,
  folder_out = value_hour_folder,
  from = "2025-10-01 01",
  to = "2025-10-02 00",
  drop_first_record = FALSE,
  mode = "value_at_hour",
  value_hour = 0
)

input_table(file.path(value_hour_folder, "tp_20251001.txt"))

## ----station-table------------------------------------------------------------
station_folder <- system.file("extdata/pcp_stations", package = "wcswatin")

pcp_table <- files_to_table(
  files_path = station_folder,
  files_pattern = "^p-",
  start_date = "2002-01-01",
  end_date = "2002-01-31",
  na_value = -99,
  neg_to_zero = TRUE
)

pcp_table[1:5, 1:5]
count_na(pcp_table, percent = TRUE)[1:5, ]

## ----table-to-files-----------------------------------------------------------
station_out <- file.path(tempdir(), "wcswatin_station_files")

table_to_files(
  table = pcp_table[, -1],
  folder_path = station_out,
  first_date = "20020101",
  file_extension = "txt"
)

head(list.files(station_out))

## ----daily-station-format, eval = FALSE---------------------------------------
# daily_tables <- point_to_daily(
#   my_folder = station_folder,
#   start_date = "20020101",
#   end_date = "20020131"
# )
# 
# save_daily_tbl(
#   tbl_list = daily_tables,
#   path = file.path(tempdir(), "wcswatin_daily_station_tables")
# )

## ----unit-converter-----------------------------------------------------------
celsius_folder <- file.path(tempdir(), "wcswatin_celsius")

unit_converter(
  folder_in = daily_folder,
  folder_out = celsius_folder,
  FUN = function(x) x - 273.15
)

input_table(file.path(celsius_folder, "t2m_20251001.txt"))

