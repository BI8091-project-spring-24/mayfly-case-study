################################################################################

# GBIF Data Cleaning 

################################################################################

# 0. PACKAGES ----
library(here)
library(CoordinateCleaner)
library(terra)
library(sf)
library(dplyr)

# 1.DOWNLOAD RECORDS FROM BOX ----

# Add downaload link ----
mayfly_records <- ("https://ntnu.box.com/shared/static/oky8o2cha6nek1jjexum29qqh0fk7asm.rda")

# Download file
download.file(mayfly_records, here("data", "insectdata.rda"))
