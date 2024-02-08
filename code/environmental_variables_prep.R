################################################################################

# Cut environmental variables to Norway

################################################################################

# 0. PACKAGES ----
library(here)
library(terra)

# 1. CUT BIOCLIMATIC VARIABLES TO NORWAY

# Load bioclimatic variables
bioclim1 <- rast(here("data", "wc2.1_10m_bio_1.tif"))

# Download Norway country shapefile
norway <- geodata::gadm(country = "NOR", level = 0, 
                        path = tempdir(),
                        version = "latest")

# Match projection of shapefile and bioclimatic variables
projection <- "+proj=longlat +ellps=WGS84"
norway_reprojected <- project(norway, crs(projection))
bio1_reprojected <- project(bioclim1, crs(projection))

# Check that projections match
crs(norway_reprojected, proj = TRUE)
crs(bio1_reprojected, proj = TRUE)

# Cut and mask bioclimatic variables to Norway
bio1_norway <- crop(bio1_reprojected, norway_reprojected, 
                    mask = TRUE)

# Save the new bioclimatic variables
terra::writeRaster(bio1_norway, 
                   here("data", "bio1_norway"))