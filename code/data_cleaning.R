################################################################################

# GBIF Data Cleaning 

################################################################################

# 0. PACKAGES ----
library(here)
library(ggplot2)
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

# 2. CLEAN GBIF RECORDS ----

## 2.1. Inspect data ----

# Download world map 
wm <- borders("world", colour = "gray50", fill = "gray50")

# Plot data to get an overview
ggplot() +
  coord_fixed() +
  wm +
  geom_point(data = insectdata,
             aes(x = decimalLongitude, y = decimalLatitude),
             colour = "darkred",
             size = 0.5) +
  theme_classic()

## 2.2. Remove records with erronous coorindates ----

# Extract coordinate flags
coordinate_flags <- clean_coordinates(x = insectdata,
                                      lon = "decimalLongitude", 
                                      lat = "decimalLatitude",
                                      species = "acceptedScientificName",
                                      test = c("centroids", "equal", "gbif", "zeros"))

# Get a summary of the detected flags
summary(coordinate_flags) # only 3 records flagged (centroids)

# Plot flagged records
plot(coordinate_flags, lon = "decimalLongitude", lat = "decimalLatitude")

# Exclude flagged records
insectdata_no_flags <- insectdata[coordinate_flags$.summary, ]
