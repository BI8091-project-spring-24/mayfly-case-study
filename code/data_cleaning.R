################################################################################

# GBIF Data Cleaning 

################################################################################

# 0. PACKAGES ----
library(here)
library(CoordinateCleaner)
library(dplyr)
library(terra)
library(sf)

# 1. LOAD DATA ----

## 1.1. Download records from Box ----

# Add downaload link ----
mayfly_records <- ("https://ntnu.box.com/shared/static/oky8o2cha6nek1jjexum29qqh0fk7asm.rda")

# Download file
download.file(mayfly_records, here("data", "insectdata.rda"))

## 1.2. Load data ----
load(here("data", "insectdata.rda"))

