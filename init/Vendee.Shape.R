library(sf)
library(rgdal)

france <- readOGR("shapefile/communes-20200101.shp")
france.sf = st_as_sf(france)
vendee.sf <- france.sf[startsWith(france.sf$insee, "85"),]
id <- vendee.sf$insee