################################################################################

# Cut environmental variables to Norway

################################################################################

# 0. PACKAGES ----
library(here)
library(terra)

# 1. CUT BIOCLIMATIC VARIABLES TO NORWAY

# Load bioclimatic variables
bioclim10 <- rast(here("data", "wc2.1_30s_bio_10.tif"))
bioclim11 <- rast(here("data", "wc2.1_30s_bio_11.tif"))

# Download Norway country shapefile
norway <- geodata::gadm(country = "NOR", level = 0, 
                        path = tempdir(),
                        version = "latest")

# Match projection of shapefile and bioclimatic variables
projection <- "+proj=longlat +ellps=WGS84"
norway_reprojected <- project(norway, crs(projection))
bio10_reprojected <- project(bioclim10, crs(projection))
bio11_reprojected <- project(bioclim11, crs(projection))

# Check that projections match
crs(norway_reprojected, proj = TRUE)
crs(bio10_reprojected, proj = TRUE)

# Cut and mask bioclimatic variables to Norway
bio10_norway <- crop(bio10_reprojected, norway_reprojected, 
                    mask = TRUE)
bio11_norway <- crop(bio11_reprojected, norway_reprojected, 
                     mask = TRUE)

# Save the new bioclimatic variables
terra::writeRaster(bio10_norway, 
                   here("data", "bio10_norway.tif"))
terra::writeRaster(bio11_norway, 
                   here("data", "bio11_norway.tif"))