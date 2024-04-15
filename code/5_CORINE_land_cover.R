################################################################################

# 5. CORINE Land Cover

################################################################################

# 0. PACKAGES ----
library(terra)
library(dplyr)

# 1. LOAD CORINE 2018 STATUS LAYER ----

# Add download link
U2018_CLC2018_V2020_20u1 <- ("https://ntnu.box.com/shared/static/iub514rfjnkopg3nu4nc18j4axq5jfon.tif")

# Download the file
download.file(U2018_CLC2018_V2020_20u1, "U2018_CLC2018_V2020_20u1.tif")

# Read in the layer
corine_2018 <- rast(here("data", "U2018_CLC2018_V2020_20u1.tif"))