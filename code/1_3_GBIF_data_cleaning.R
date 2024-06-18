################################################################################

# GBIF Data Cleaning 

################################################################################

# 1. LOAD DATA -----------------------------------------------------------------

## 1.1. Download records from Box ----------------------------------------------

# Add download link ----
mayfly_records <- "https://ntnu.box.com/shared/static/oky8o2cha6nek1jjexum29qqh0fk7asm.rda"

# Download file (NB: requires you to make "data" directory beforehand)
download.file(mayfly_records, here("data", "insectdata.rda"))

## 1.2. Load data --------------------------------------------------------------
load(here("data", "insectdata.rda"))

# 2. CLEAN GBIF RECORDS --------------------------------------------------------

## 2.1. Inspect data -----------------------------------------------------------

# Download world map 
wm <- borders("world", colour = "lightgrey", fill = "lightgrey")

# Plot data to get an overview
records_world <- ggplot() +
  coord_fixed() +
  wm +
  geom_point(data = insectdata,
             aes(x = decimalLongitude, y = decimalLatitude),
             colour = "darkred",
             size = 0.5) +
  theme_classic() + 
  theme(axis.title = element_blank(),
        axis.text = element_blank(),
        axis.ticks = element_blank(),
        axis.line = element_blank())

# Save plot to file
ggsave(here("figures", "insect_records_world_map.png"),
       width=13, height=9)

## 2.2. Remove records with problematic coordinates ----------------------------

# Extract coordinate flags
coord_flags <- clean_coordinates(x = insectdata,
                                      lon = "decimalLongitude", 
                                      lat = "decimalLatitude",
                                      species = "acceptedScientificName",
                                      test = c("centroids", "equal", 
                                               "gbif", "zeros"))

# Get a summary of the detected flags
summary(coord_flags) # only 3 records flagged (centroids)

# Plot flagged records
flagged_records <- ggplot() +
  coord_fixed() +
  geom_point(data = coord_flags,
             aes(x = decimalLongitude, y = decimalLatitude, color = .cen),
             size = 0.5) +
  theme_classic() + 
  theme(axis.title = element_blank(),
        axis.text = element_blank(),
        axis.ticks = element_blank(),
        axis.line = element_blank())

# Save plot to file
ggsave(here("figures", "flagged_insect_records.png"),
       width=13, height=9)

# Exclude flagged records
insectdata_coords <- insectdata[coord_flags$.summary, ]

## 2.3. Remove records with temporal outliers ----------------------------------

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

# 3. IMPROVE DATA QUALITY WITH META-DATA ---------------------------------------

## 3.1. Coordinate precision ---------------------------------------------------

# Boxplot of coordinate precision in insect data
coord_uncertainty_plot <- ggplot(insectdata_no_flags, 
                                 aes(x = coordinateUncertaintyInMeters)) +
  geom_boxplot(bins = 30, na.rm = TRUE) +
  labs(x = "Coordinate Uncertainty (m)", y = "Frequency") +
  theme_minimal() # A few records with relatively high coordinate uncertainty

# Save boxplot to file
ggsave(here("figures", "arenicola_map1.png"),
       width=13, height=9)

# Summary stats on coordinate uncertainty
mean(insectdata_no_flags$coordinateUncertaintyInMeters,
     na.rm = TRUE) #385.518
min(insectdata_no_flags$coordinateUncertaintyInMeters,
    na.rm = TRUE) #0.05
max(insectdata_no_flags$coordinateUncertaintyInMeters,
    na.rm = TRUE) #79110

# Table of frequency of each value of Coordinate Uncertainty
coordinate_uncertainty_df <- table(insectdata_no_flags$coordinateUncertaintyInMeters)
View(coordinate_uncertainty_df)

# Write the table to file
save(coordinate_uncertainty_df,
     file = here::here("data","derived_data","coordinate_uncertainty_df.Rda"))

# Remove records with coordinate uncertainty >1km and records with NA for coordinate uncertainty
insectdata_low_uncertainty <- insectdata_no_flags |>
  filter(coordinateUncertaintyInMeters <= 1000 | 
           is.na(coordinateUncertaintyInMeters))

# Check how many records are left
nrow(insectdata_no_flags) #23547
nrow(insectdata_low_uncertainty)#23487 (removed 60 records - not so bad)

## 3.2. Data sources -----------------------------------------------------------

# Check basis of record in df
table(insectdata_low_uncertainty$basisOfRecord)

# Check individual counts (to remove absences, where individual count = 0)
table(insectdata_low_uncertainty$individualCount)

# Remove records with more than 10 000 individuals counted and with basis of record = material sample
insectdata_cleaned_count <- insectdata_low_uncertainty |>
  filter(individualCount < 10000 | is.na(individualCount)) |>
  filter(basisOfRecord != "MATERIAL SAMPLE")

# Check family
table(insectdata_cleaned_count$family) #Baetidae 23451

# Check taxonRank
table(insectdata_cleaned_count$taxonRank) #Species: 23434, Unranked: 17

# Remove records with taxonomic rank = Unranked
insectdata_cleaned_count <- insectdata_cleaned_count |>
  filter(!taxonRank == "UNRANKED")


## 3.3. Remove problematic datasets --------------------------------------------

# Identify datasets with ddmm to dd.dd conversion error 
out.ddmm <- cd_ddmm(insectdata_cleaned_count, lon = "decimalLongitude", 
                    lat = "decimalLatitude", 
                    ds = "species", diagnostic = T, diff = 1,
                    value = "dataset") # 0 records flagged

#Test for rasterized sampling
par(mfrow = c(2,2), mar = rep(2, 4))
out.round <- cd_round(insectdata_cleaned_count, lon = "decimalLongitude", 
                      lat = "decimalLatitude", 
                      ds = "species",
                      value = "dataset",
                      T1 = 7,
                      graphs = T) #it looks like there is a bit of rasterized sampling so we will need to account for this

# Save cleaned df
cleaned_insectdata <- insectdata_cleaned_count
save(cleaned_insectdata, file = here("data","derived_data","cleaned_insectdata.rda"))

