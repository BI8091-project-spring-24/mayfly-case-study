################################################################################

# Cut environmental variables to Norway

################################################################################

# 0. PACKAGES ----
library(here)
library(terra)

# 1. CUT BIOCLIMATIC VARIABLES TO NORWAY

# Download bioclimatic variables
bioclim <- worldclim_country(var='bio', res=0.5, path=here("data", "source_data"),
                            country="Norway")

# Load bioclimatic variables
bioclim10 <- bioclim$wc2.1_30s_bio_10 # what is this??
bioclim11 <- bioclim$wc2.1_30s_bio_11 # what is this??

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
                   here("data", "derived_data", "bio10_norway.tif"))
terra::writeRaster(bio11_norway, 
                   here("data", "derived_data", "bio11_norway.tif"))

