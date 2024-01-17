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

## 2.2. Remove records with problematic coordinates ----

# Extract coordinate flags
coord_flags <- clean_coordinates(x = insectdata,
                                      lon = "decimalLongitude", 
                                      lat = "decimalLatitude",
                                      species = "acceptedScientificName",
                                      test = c("centroids", "equal", "gbif", "zeros"))

# Get a summary of the detected flags
summary(coord_flags) # only 3 records flagged (centroids)

# Plot flagged records
plot(coord_flags, lon = "decimalLongitude", lat = "decimalLatitude")

# Exclude flagged records
insectdata_coords <- insectdata[coord_flags$.summary, ]

## 2.3. Remove records with temporal outliers ----

# Test for temporal outliers on taxon level
time_flags <- cf_age(x = insectdata_coords,
                  lon = "decimalLongitude",
                  lat = "decimalLatitude",
                  taxon = "species", 
                  min_age = "year", 
                  max_age = "year", 
                  value = "flagged") # Flagged 8 records

# Exclude records flagged for temporal outliers
insectdata_no_flags <- insectdata_coords[time_flags, ]  

# 3. IMPROVE DATA QUALITY WITH META-DATA ----

## 3.1. Coordinate precision ----

# Boxplot of coordinate precision in insect data
ggplot(insectdata_no_flags, aes(x = coordinateUncertaintyInMeters)) +
  geom_boxplot(bins = 30, na.rm = TRUE) +
  labs(x = "Coordinate Uncertainty (m)", y = "Frequency") +
  theme_minimal() # A few records with relatively high coordinate uncertainty

# Summary stats on coordinate uncertainty
mean(insectdata_no_flags$coordinateUncertaintyInMeters,
     na.rm = TRUE) #385.518
min(insectdata_no_flags$coordinateUncertaintyInMeters,
    na.rm = TRUE) #0.05
max(insectdata_no_flags$coordinateUncertaintyInMeters,
    na.rm = TRUE) #79110

# Table of frequency of each value of Coordinate Uncertainty
value_counts <- table(insectdata_no_flags$coordinateUncertaintyInMeters)
View(value_counts)

# Which Coordinate uncertainty value is most common?
sorted_value_counts <- sort(value_counts, decreasing = TRUE)
most_frequent_value <- names(sorted_value_counts)[1]
most_frequent_value #1m coordinate uncertainty most frequent

# Remove records with coordinate uncertainty >3km and records with NA for coordinate uncertainty
insectdata_low_uncertainty <- insectdata_no_flags |>
  filter(coordinateUncertaintyInMeters <= 3000 | 
           is.na(coordinateUncertaintyInMeters))

# Check how many records are left
nrow(insectdata_no_flags) #23547
nrow(insectdata_low_uncertainty)#23516 (removed 31 records - not so bad)

## 3.2. Data sources ----

# Check basis of record in df
table(insectdata_low_uncertainty$basisOfRecord)

# Check individual counts (to remove absences, where individual count = 0)
table(insectdata_low_uncertainty$individualCount)

# Remove records with more than 10 000 individuals counted
insectdata_cleaned_count <- insectdata_low_uncertainty |>
  filter(individualCount < 10000 | is.na(individualCount))

# Check family
table(insectdata_cleaned_count$family) #Baetidae 23480

# Check taxonRank
table(insectdata_cleaned_count$taxonRank) #Species: 23463, Unranked: 17
