##############################
### 03. vms subset for SoCal ###
##############################

# Created by Brian Free and modified by Eliza Carter. Script used to select VMS points within the SoCal polygon.
# Date created: November 2024

# Clear environment
rm(list = ls())

# Calculate start time of code (determine how long it takes to complete all code)
start <- Sys.time()

#####################################
#####################################

# Load packages
if (!require("pacman")) install.packages("pacman")
pacman::p_load(dplyr,
               lubridate,
               plyr,
               purrr,
               reshape2,
               stringr,
               tidyr)

#####################################
#####################################

# parameters
year <- 2023
month <- "08"
data_name <- "VMS"

## fields
# DOC# for month 1
# DOC.for month 10

#####################################
#####################################

# set directories
## download directory
a_data_dir <- "data/a_raw_data"
b_data_dir <- "data/b_intermediate_data"

## SoCal Polygon
socal_poly_path <- file.path(a_data_dir, stringr::str_glue("VMS_area_for_analysis.gdb"))

## year directory
yr_dir <- file.path(b_data_dir, year)
# yr_dir
# list.files(yr_dir)

## RDS files directory
rds_dir <- "data/b_intermediate_data"

## create directory for .RDS files
dest_path <- file.path(rds_dir, paste0(data_name, year))

### Check if the directory exists, if not, create it
if (!dir.exists(dest_path)) {
  dir.create(dest_path, recursive = TRUE)
}

### set directory for vms .RDS files
vms_rds_dir <- file.path(rds_dir, paste0(data_name, year))

#####################################
#####################################

# file
vms_file <- file.path(yr_dir, pattern = str_glue("{data_name}_{year}_{month}.csv"))


# load US SoCal polygon
## use geopackage when running locally
socal_poly <- sf::st_read(socal_poly_path, layer = "VMS_Polygon")


## parameters
### boundaries of the US west coast EEZ
xmin <- sf::st_bbox(obj = socal_poly)[1] # west
ymin <- sf::st_bbox(obj = socal_poly)[2] # south
xmax <- sf::st_bbox(obj = socal_poly)[3] # east
ymax <- sf::st_bbox(obj = socal_poly)[4] # north

vms_name <- tools::file_path_sans_ext(vms_file)
  
## read the CSV file
csv <- readr::read_csv(file = file.path(vms_file))

# create a vector of field names for the VMS data
point_fields <- names(csv)[2:13]
  
#####################################
  
## generate template name for southern california
area_name <- "SoCal"
  
## limit points to SoCal
vms <- csv %>%
    # subset points to ones within the longitude and latitude of SoCal polygon
    dplyr::filter(LONGITUDE >= xmin & LONGITUDE <= xmax,
                  LATITUDE <= ymax & LATITUDE >= ymin) %>%
    # select all the fields that are relevant for the vms transects
    dplyr::select(all_of(point_fields))

  
## export data as .RDS file
readr::write_rds(x = vms, file = file.path(vms_rds_dir, paste0(area_name, month, ".rds")))
  
#####################################


# calculate end time and print time difference
print(Sys.time() - start) # print how long it takes to calculate



####################################################### loop
years <- 2021:2023
months <- sprintf("%02d", 1:12)
data_name <- "VMS"

for (year in years) {
  for (month in months) {
    # set directories
    ## download directory
    a_data_dir <- "data/a_raw_data"
    b_data_dir <- "data/b_intermediate_data"
    
    ## SoCal Polygon
    socal_poly_path <- file.path(a_data_dir, stringr::str_glue("VMS_area_for_analysis.gdb"))
    
    ## year directory
    yr_dir <- file.path(b_data_dir, year)
    # yr_dir
    # list.files(yr_dir)
    
    ## RDS files directory
    rds_dir <- "data/b_intermediate_data"
    
    ## create directory for .RDS files
    dest_path <- file.path(rds_dir, paste0(data_name, year))
    
    ### Check if the directory exists, if not, create it
    if (!dir.exists(dest_path)) {
      dir.create(dest_path, recursive = TRUE)
    }
    
    ### set directory for vms .RDS files
    vms_rds_dir <- file.path(rds_dir, paste0(data_name, year))
    
    #####################################
    #####################################
    
    # file
    vms_file <- file.path(yr_dir, pattern = str_glue("{data_name}_{year}_{month}.csv"))
    
    
    # load US SoCal polygon
    ## use geopackage when running locally
    socal_poly <- sf::st_read(socal_poly_path, layer = "VMS_Polygon")
    
    
    ## parameters
    ### boundaries of the US west coast EEZ
    xmin <- sf::st_bbox(obj = socal_poly)[1] # west
    ymin <- sf::st_bbox(obj = socal_poly)[2] # south
    xmax <- sf::st_bbox(obj = socal_poly)[3] # east
    ymax <- sf::st_bbox(obj = socal_poly)[4] # north
    
    vms_name <- tools::file_path_sans_ext(vms_file)
    
    ## read the CSV file
    csv <- readr::read_csv(file = file.path(vms_file))
    
    # create a vector of field names for the VMS data
    point_fields <- names(csv)[2:13]
    
    #####################################
    
    ## generate template name for southern california
    area_name <- "SoCal"
    
    ## limit points to SoCal
    vms <- csv %>%
      # subset points to ones within the longitude and latitude of SoCal polygon
      dplyr::filter(LONGITUDE >= xmin & LONGITUDE <= xmax,
                    LATITUDE <= ymax & LATITUDE >= ymin) %>%
      # select all the fields that are relevant for the vms transects
      dplyr::select(all_of(point_fields))
    
    
    ## export data as .RDS file
    readr::write_rds(x = vms, file = file.path(vms_rds_dir, paste0(area_name, month, ".rds")))
    
    #####################################
    
    
    # calculate end time and print time difference
    print(Sys.time() - start) # print how long it takes to calculate
    
  }
}


