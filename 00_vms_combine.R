##############################
### 00. Combine VMS Files ###
##############################

# VMS data was cleaned prior to combining. Three files for each month were combined for all years. This script was created by Eliza Carter. 
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

## use fileEncoding = "UTF-8" for 2021, 03

# read in csvs

year <- '2023'
month <- '08'

data_dir <- 'data/a_raw_data'
output_dir<- 'data/b_intermediate_data'

vms_1 <- read.csv(file.path(data_dir, stringr::str_glue("NOAA24-2019to2023"), stringr::str_glue("NOAAA24-006-{year}_{month}.csv")))

vms_2 <- read.csv(file.path(data_dir, stringr::str_glue("NOAA24-2019to2023"), stringr::str_glue("NOAAA24-006-{year}_{month}b_clean.csv")))

vms_3 <- read.csv(file.path(data_dir, stringr::str_glue("NOAA24-2019to2023"), stringr::str_glue("NOAAA24-006-{year}_{month}c.csv")))

vms_file <- rbind(vms_1, vms_2, vms_3) 

write.csv(vms_file, file.path(output_dir, year, stringr::str_glue("VMS_{year}_{month}.csv")))



