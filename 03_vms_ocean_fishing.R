###########################################
### 03. Calculate VMS time and distance ###
###########################################

# Created by Brian Free and modified by Eliza Carter. VMS points are clipped to areas on the ocean, not on land. Points where the average speed is <= 4 are considered fishing and were not removed. 

# After this script, all points were merged into a single year using ArcTools. Lines were created in ArcPro using Reconstruct Tracks for each year. We used a distance of 4 international nautical miles and 90 minutes to split lines. All track years were merged into a single file.

# Date created: November 2024


# Clear environment
rm(list = ls())

# Calculate start time of code (determine how long it takes to complete all code)
start <- Sys.time()

#####################################
#####################################

# Load packages
if (!require("pacman")) install.packages("pacman")
pacman::p_load(DescTools,
               dplyr,
               lubridate,
               plyr,
               purrr,
               reshape2,
               stringr,
               tidyr,
               janitor,
               terra,
               sf)

#####################################
#####################################

## year directory
year <- "2023"
month <- "12"
data_name <- "VMS"
area_name <- "SoCal"
crs <- "EPSG:4326"

#####################################
#####################################
# set directories
## vms and land data directory
data_dir <- "data/b_intermediate_data"

# RDS files
rds_dir <- file.path(data_dir, stringr::str_glue("{data_name}{year}")) 

## land directory
land_gpkg <- file.path(data_dir, stringr::str_glue("land.gpkg"))

## export geopackage
fishing_gdb <- file.path(data_dir, stringr::str_glue("{data_name}_fishing_{year}.gdb"))

#####################################
#####################################
# vector of files
rds_files <- list.files(rds_dir, recursive = T, pattern = stringr::str_glue("{area_name}{month}"))

## Load data
month_point <- terra::readRDS(file = file.path(rds_dir, rds_files))

## clean month-point data for distinct points in real longitudes and latitudes
month_point_clean <- month_point %>%
  clean_names() %>%
  rename_with(~ "doc", .cols = any_of(c("doc", "doc_number")))  %>%
  mutate(local_date = mdy_hm(local_date))%>%
  # remove duplicates 
  distinct(doc, local_date, .keep_all = T) %>%
  dplyr::group_by(doc, local_date) %>%
  # sort by time stamp within vessels
  arrange(doc, local_date) %>%
  # ungroup to add in the information back to the vessel and date-time for later calculations
  dplyr::ungroup()

# determine the unique dates
unique_dates <- month_point_clean %>%
  mutate(date_only = as.Date(local_date)) %>% 
  distinct(date_only) %>%                    
  arrange(date_only) 

print(nrow(unique_dates))

## remove the month-point data
rm(month_point)

month_point_clean <- month_point_clean %>%
  sf::st_as_sf(coords = c("longitude", "latitude"),
               # set the coordinate reference system to WGS84
               crs = crs, # EPSG 4326 (https://epsg.io/4326)
               # keep longitude and latitude fields
               remove = FALSE)

#####################################
VMS_time <- Sys.time()

## Load continental land data
continents <- sf::st_read(dsn = land_gpkg, layer = "continents")
continents_time <- Sys.time()

## Load big island land data
big_islands <- sf::st_read(dsn = land_gpkg, layer = "big_islands")
big_islands_time <- Sys.time()

## Load small island land data
small_islands <- sf::st_read(dsn = land_gpkg, layer = "small_islands")
small_islands_time <- Sys.time()

## Load very small island land data
very_small_islands <- sf::st_read(dsn = land_gpkg, layer = "very_small_islands")
very_small_islands_time <- Sys.time()

## Load ports data
ports <- sf::st_read(dsn = land_gpkg, layer = "ports")
ports_time <- Sys.time()

## Load harbor data
harbors <- sf::st_read(dsn = land_gpkg, layer = "harbors")
harbors_time <- Sys.time()

load_end <- Sys.time()


#####################################
#####################################

# only ocean based VMS points
ocean_time <- Sys.time()

month_point_ocean <- month_point_clean %>%
  # check validity or fix any invalid geometry
  sf::st_make_valid() %>%
  
  # Remove continental land
  sf::st_difference(continents) %>%
  # Remove big island land
  sf::st_difference(big_islands) %>%
  # Remove small island land
  sf::st_difference(small_islands) %>%
  # Remove very small island land
  sf::st_difference(very_small_islands) %>%
  # Remove ports
  sf::st_difference(ports) %>%
  # Remove harbors
  sf::st_difference(harbors)

# calculate time to create annual shrimp fishing data in only ocean areas
print(Sys.time() - ocean_time)

#####################################

# remove land data and month point data with time and distance
rm(continents)
rm(big_islands)
rm(small_islands)
rm(very_small_islands)
rm(month_point_clean)


#####################################

# filter for only fishing vessels -- where average speed <= 4 knots

month_point_fishing <- month_point_ocean %>%
  # filter for fishing speeds
  filter(avg_speed <= 4) %>%
  # remove unnecessary columns
  dplyr::select(-land, -land.1, -land.2, -land.3, -land.4, -land.5) %>%
  # reproject the coordinate reference system
  sf::st_transform(crs)


#####################################

# export data
sf::st_write(obj = month_point_fishing, dsn = fishing_gdb, layer = stringr::str_glue("{data_name}_{year}_{month}"), append = F)

#sf::st_write(month_point_fishing, "data/b_intermediate_data/test_10.shp", overwrite = T)

#####################################
#####################################

# calculate end time and print time difference
print(Sys.time() - start) # print how long it takes to calculate

