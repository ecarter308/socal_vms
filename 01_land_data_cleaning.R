##############################
### 01. Clean Island Files ###
##############################

# This script was created by Brian Free and modified by Eliza Carter.
# Date created: November 2024

# Clear environment
rm(list = ls())

# Calculate start time of code (determine how long it takes to complete all code)
start <- Sys.time()

#####################################
#####################################

# Load packages
if (!require("pacman")) install.packages("pacman")
pacman::p_load(docxtractr,
               dplyr,
               elsa,
               fasterize,
               fs,
               geosphere,
               ggplot2,
               janitor,
               microbenchmark,
               ncf,
               paletteer,
               pdftools,
               plyr,
               purrr,
               raster,
               RColorBrewer,
               reshape2,
               rgdal,
               rgeoda,
               rgeos,
               rmapshaper,
               rnaturalearth, # use devtools::install_github("ropenscilabs/rnaturalearth") if packages does not install properly
               RSelenium,
               sf,
               shadowr,
               sp,
               stringi,
               stringr,
               terra, # is replacing the raster package
               tidyr,
               tidyverse)

# Resources
## geosphere package Github: https://github.com/rspatial/geosphere
## geosphere reference manual: https://cran.r-project.org/web/packages/geosphere/geosphere.pdf

#####################################
#####################################

# Create directories
# dir.create("data/a_raw_data")

#####################################

# Directories
## shrimp directory
data_dir <- "data/a_raw_data"

## Export directory
land_gpkg <- "data/b_intermediate_data/land.gpkg"
export_dir <- "data/b_intermediate_data"

#####################################


#####################################
#####################################

# Function to create clean land feature data
## The function will take the input (land data) and then return a single feature

land_function <- function(land_data){
  land_layer <- land_data %>%
    # rectify any issues
    sf::st_make_valid() %>%
    # create field called "land"
    dplyr::mutate(land = "land") %>%
    # select the "land" field
    dplyr::select(land) %>%
    # reproject the coordinate reference system
    sf::st_transform("EPSG:4326") %>%
    # group all rows by the different elements with "land" field -- this will create a row for the grouped data
    dplyr::group_by(land) %>%
    # summarise all those grouped elements together -- in effect this will create a single feature
    dplyr::summarise()
  return(land_layer)
}

#####################################
#####################################

load_start <- Sys.time()

### Load continental land data
continents <- sf::st_read(dsn = paste(data_dir, "usgs_mainland.shp", sep = "/")) %>%
  # use the land function to clean the data for later use
  land_function()
continents_time <- Sys.time()

paste("Time to take load continents data:", continents_time - load_start, units(continents_time - load_start))

### Load big island land data
big_islands <- sf::st_read(dsn = paste(data_dir, "usgs_big_islands.shp", sep = "/")) %>%
  # make all features valid as an error may be generated otherwise
  sf::st_make_valid() %>%
  # use the land function to clean the data for later use
  land_function() %>%
  sf::st_make_valid()
big_islands_time <- Sys.time()

paste("Time to take load big islands data:", big_islands_time - continents_time, units(big_islands_time - continents_time))

### Load small island land data
small_islands <- sf::st_read(dsn = paste(data_dir, "usgs_small_islands.shp", sep = "/")) %>%
  # use the land function to clean the data for later use
  land_function()
small_islands_time <- Sys.time()

paste("Time to take load big islands data:", small_islands_time - big_islands_time, units(small_islands_time - big_islands_time))

### Load very small island land data
very_small_islands <- sf::st_read(dsn = paste(data_dir, "usgs_very_small_islands.shp", sep = "/")) %>%
  # use the land function to clean the data for later use
  land_function()
very_small_islands_time <- Sys.time()

paste("Time to take load big islands data:", very_small_islands_time - small_islands_time, units(very_small_islands_time - small_islands_time))


ports <- sf::st_read(dsn = paste(data_dir, "cdfw_ports_buffer.shp", sep = "/")) %>%
  # use the land function to clean the data for later use
  land_function()

harbors <- sf::st_read(dsn = paste(data_dir, "csmw_harbors_buffer.shp", sep = "/")) %>%
  # use the land function to clean the data for later use
  land_function()


load_end <- Sys.time()
paste("Time to take load land data:", load_end - load_start, units(load_end - load_start))

#####################################
#####################################

# Export data
## land data
### ***Warning: when using Microsoft Azure ML, the data will not export correctly to the geopackage;
###             thus, will need to use the .RDS files
sf::st_write(obj = continents, dsn = land_gpkg, layer = "continents", append = F)
sf::st_write(obj = big_islands, dsn = land_gpkg, layer = "big_islands", append = F)
sf::st_write(obj = small_islands, dsn = land_gpkg, layer = "small_islands", append = F)
sf::st_write(obj = very_small_islands, dsn = land_gpkg, layer = "very_small_islands", append = F)
sf::st_write(obj = ports, dsn = land_gpkg, layer = "ports", append = F)
sf::st_write(obj = harbors, dsn = land_gpkg, layer = "harbors", append = F)



#####################################
#####################################

# calculate end time and print time difference
print(Sys.time() - start) # print how long it takes to calculate

