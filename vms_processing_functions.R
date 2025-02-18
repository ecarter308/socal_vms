
categorize_ship_types <- function(type_names){
  
  type_names <- as.numeric(type_names)
  
  group_tags <- list(
    "210" = 210,
    "211" = 211,
    "233" = 233,
    "234" = 234,
    "235" = 235,
    "240" = 240,
    "241" = 241,
    "242" = 242,
    "243" = 243,
    "260" = 260,
    "261" = 261,
    "263" = 263,
    "264" = 264,
    "265" = 265,
    "266" = 266,
    "267" = 267,
    "268" = 268,
    "262" = 262,
    "236" = 236,
    "Exempt" = c(310, 320, 330, 340)
# 230 does not intersect the grid
  )
  
  out_categories <- rep("Other", length(type_names)) # 269 is "Other"
  
  for(n in seq(length(group_tags))){
    
    out_categories[type_names %in% group_tags[[n]]] <- names(group_tags)[n]
    
  }
  
  return(out_categories)
}



