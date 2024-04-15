################################################################################

# 5. CORINE Land Cover

################################################################################

# 0. PACKAGES ----
library(here)
library(terra)
library(dplyr)

# 1. LOAD CORINE 2018 STATUS LAYER ----

# Add download link
U2018_CLC2018_V2020_20u1 <- ("https://ntnu.box.com/shared/static/iub514rfjnkopg3nu4nc18j4axq5jfon.tif")

# Download the file
download.file(U2018_CLC2018_V2020_20u1, "U2018_CLC2018_V2020_20u1.tif")

# Read in the layer
corine_2018 <- rast(here("data", "U2018_CLC2018_V2020_20u1.tif"))

# 2. CUT AND MASK CORINE LAYER TO NORWAY ----

## 2.1. Download country shapefile ----

norway <- geodata::gadm(country = "NOR", level = 0, 
                        path = tempdir(),
                        version = "latest")
# Check shapefile
plot(norway)

## 2.2. Re-project shapefile to match projection of CORINE layers ----

# Check projections of Norway and CORINE layers
crs(norway, proj = TRUE) #"+proj=longlat +datum=WGS84 +no_defs"
crs(corine_2018, proj = TRUE) #"+proj=laea +lat_0=52 +lon_0=10 +x_0=4321000 +y_0=3210000 +ellps=GRS80 +units=m +no_defs"

# Re-project Norway shapefile to the CORINE layers
norway_corine_projection <- project(norway, crs(corine_2018))

# Check projection
crs(norway_corine_projection, proj = TRUE) #"+proj=laea +lat_0=52 +lon_0=10 +x_0=4321000 +y_0=3210000 +ellps=GRS80 +units=m +no_defs"

## 2.3. Crop and mask CORINE 2018 to Norway ----
norway_corine_2018 <- crop(corine_2018, norway_corine_projection,
                            mask = TRUE)
