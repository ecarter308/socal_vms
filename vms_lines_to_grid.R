####

# VMS Lines to Grid

# This script was run after creating lines from points in ArcPro using Reconstruct Tracks. We used a distance of 4 international nautical miles and 90 minutes to split lines. All track years were merged into a single file.

# Script to count the number of fishing vessel transits per BOEM aliquot grid cell. This script was created by Isaac Keohane and modified by Eliza Carter to count the number of AIS transects per grid cell for Southern California for all years. The script separates the transects counts by vessel type, which is determined in the "vms_processing_functions" script. Vessel codes can be found here: https://www.fisheries.noaa.gov/s3/2023-12/VMS-Declaration-Report-Worksheet-exp-12-18-2026-December2023Update.pdf


# Date created: December 2024 

####

library(sf)
library(stringr)
library(matrixStats)
library(dplyr)
library(units)
library(lubridate)
library(terra)
library(tidyterra)
source("C:/Users/Eliza.Carter/Documents/Projects/California/ori_vms/code/vms_processing_functions.R") # make sure path is correct
fname <- basename(rstudioapi::getSourceEditorContext()$path) #get the name of the current file
start0 <- Sys.time()

###########
# years to loop through
year = "all"

###########


###
# output directory
out_dir = "C:/Users/Eliza.Carter/Documents/Projects/California/ori_vms/data/c_transect_data"

###########

# dsn of merged lines for the relevant year
dsn_lines = file.path(stringr::str_glue("C:/Users/Eliza.Carter/Documents/Projects/California/ori_vms/data/b_intermediate_data/VMS_lines_{year}.shp"))  # make sure this is right


########
# pull the relevant lines datasets
lines_month = sf::st_read(dsn_lines, quiet = T) 
# %>%
#   mutate(START_DATE = parse_date_time(START_DATE, "%y-%m-%d %H:%M:%S")) %>%
#   filter(START_DATE < parse_date_time("02-01-2015", "%m-%d-%y"))

lines_month = st_transform(lines_month, "EPSG:32611")

lines_month = st_make_valid(lines_month)

lines_month = lines_month[st_geometry_type(lines_month)=="LINESTRING",]

lines_month$ShipTypeCat <- categorize_ship_types(lines_month$declaratio) # from ais_processing_functions.R
########


#######

# read in the hex grid
fishnet_polygon <- st_read("C:/Users/Eliza.Carter/Documents/Projects/California/ori_vms/data/b_intermediate_data/vms_grid.shp")


fishnet_polygon <- st_zm(fishnet_polygon, drop = T, what = "ZM") #drop Z and M fields

fishnet_polygon = st_transform(fishnet_polygon, "EPSG:32611")

fishnet_polygon  = st_make_valid(fishnet_polygon)

fishnet_polygon$fn_id = seq(nrow(fishnet_polygon)) # add an id field
# create a version of the fishnet that is a line for each grid instead of polygons
fishnet_boundary_lines = st_cast(fishnet_polygon, "MULTILINESTRING")

#######

# Extract the intersecting points between the lines and each grid cell in the fishnet 
# Do this separately for each ship type
ship_types = c("210", "211", "233","234", "235", "240", "241", "242","243","260","261","263","264","265","266","267","268","Exempt", "Other", "262", "236")


print(paste("start loop"))

#fishnet_polygon$n_unique_total = 0

for(j in seq(length(ship_types))){
  # get just the lines for this ship (vessel) type
  vessel_lines <- lines_month %>%
    filter(ShipTypeCat == ship_types[j])
  
  if (nrow(vessel_lines) > 0) {
    ###
    # generate points for all of the intersections between ais lines and the grid cell boundaries
    line_intersect_points = st_intersection(fishnet_boundary_lines, vessel_lines) %>%
      st_cast(., "MULTIPOINT") %>%
      st_cast(., "POINT")
    
    # generate endpoint intersections
    line_end_pts <- st_coordinates(st_cast(vessel_lines, "MULTILINESTRING")) %>% # get coordinates of line vertices
      as.data.frame(.) %>% # convert from matrix to data frame
      group_by(c(L2)) %>%  # group by the origninal line it came from
      slice(c(1,n())) %>%  # get the first and last point of the linestring
      st_as_sf(., coords=c("X", "Y"), crs=st_crs(vessel_lines))
    
    end_pt_intscts = st_join(fishnet_polygon, line_end_pts, join=st_contains, left=FALSE)
    
    # combine end point intersections and wall intersections
    intsct_data = rbind(st_drop_geometry(line_intersect_points) %>% select(fn_id), 
                        st_drop_geometry(end_pt_intscts) %>% select(fn_id))
    
    # count unique IDs per grid cell
    unique_counts = st_drop_geometry(line_intersect_points) %>% select(fn_id, doc)
    
    new_colname=paste0("doc_", ship_types[j])
    
    unique_counts = unique_counts %>%
      group_by(fn_id) %>%
      summarise(!!new_colname := n_distinct(doc))
    
    fishnet_polygon = fishnet_polygon %>% left_join(unique_counts, by="fn_id")
    
    # count the number of point intersections for each fishnet grid (using the fishnet id)
    intsct_data = intsct_data %>%
      group_by(fn_id) %>%
      summarise(!!ship_types[j] := n()) # set column name to ship type
    
    # join the counts for this ship type back to the fishnet polygon
    fishnet_polygon = fishnet_polygon %>%
      left_join(intsct_data, by=c("fn_id"))
  } else {
    fishnet_polygon = fishnet_polygon %>% mutate(!!ship_types[j] := 0)
  }
  
print(paste(j, Sys.time()))
}
######

# replace NA with 0, divide by 2 for transect, and then by 9 
fishnet_polygon = fishnet_polygon %>%
  mutate(across(all_of(ship_types), 
                       ~ as.numeric(ifelse(is.na(.x), 0, .x/2)) )) %>%
  mutate(across(all_of(ship_types), ~ . / 9))

#write fishnet_polygon table to shapefile
#st_write(st_as_sf(terra::vect(fishnet_polygon)), "C:/Users/Eliza.Carter/Documents/Projects/California/ori_vms/data/c_transect_data/VMS_transects.gpkg", layer = stringr::str_glue("vms_grid_{year}"), delete_layer = TRUE)

st_write(fishnet_polygon, stringr::str_glue("C:/Users/Eliza.Carter/Documents/Projects/California/ori_vms/data/c_transect_data/VMS_transects_{year}_2.shp"), delete = T, overwrite = T)



#############

end <- Sys.time()
print(end - start) # print runtime for this iteration


print("full loop ended")
print(Sys.time() - start0)


#################
# read shapefile and write it again to fix column names

shp <- st_read("C:/Users/Eliza.Carter/Documents/Projects/California/ori_vms/data/c_transect_data/VMS_transects_all_2.shp")


st_write(shp, "C:/Users/Eliza.Carter/Documents/Projects/California/ori_vms/data/c_transect_data/VMS_transects_all_2_final.shp")

