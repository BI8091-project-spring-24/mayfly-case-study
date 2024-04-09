################################################################################

# Create raster layer

################################################################################

# Preparations -----------------------------------------------------------------

# Load packages
library(stars)

# Load buffer vector for elvenett
elvenett_buf_100m <- st_read(here::here("data","derived_data","elvenett_buf_100m.gpkg"))


# Creating raster --------------------------------------------------------------

raster_elvenett_buf_100m <- stars::st_rasterize(elvenett_buf_100m)