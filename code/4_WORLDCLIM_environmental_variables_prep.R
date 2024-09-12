################################################################################

# Cut environmental variables to Norway

################################################################################

# 1. CUT BIOCLIMATIC VARIABLES TO NORWAY ---------------------------------------

# Download bioclimatic variables
bioclim <- worldclim_global(var='bio', res=0.5, path=here("data", "source_data"))

# Load bioclimatic variables
bioclim10 <- bioclim$wc2.1_30s_bio_10 # mean temp warmest quarter
bioclim11 <- bioclim$wc2.1_30s_bio_11 # mean temp coldest quarter

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

# 2. CHECK CORRELATION ---------------------------------------------------------

# Convert rasters to dfs
bio10_norway <- as.data.frame(bio10_norway, xy = TRUE)
bio11_norway <- as.data.frame(bio11_norway, xy = TRUE)

# Run correlation test
cor.test(bio10_norway_df$wc2.1_30s_bio_10, bio11_norway_df$wc2.1_30s_bio_11)
# r = 0.5586072, p-value < 2.2e-16, t = 631.