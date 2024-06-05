#############################################

# Create presence/absence file

############################################
source("code/0_setup.R")
# Download NTNU dataset ----

# Searched for the dataset in GBIF, create a download request, date 22.04.024
# GBIF download
datset_key <- "33591b80-0e31-480c-82ce-2f57211b10e6" # select freshwater ecological collection

# create download request
occurrences_NTNU_download <- occ_download(pred("datasetKey", datset_key),
                                          pred("gadm", "NOR"),
                                          pred_gte("year", 1950))
occ_download_wait(occurrences_NTNU_download)

# save as R object
occurrences_NTNU <- occ_download_get("0060598-240506114902167") %>%
  occ_download_import()

# delete zip file?

# Creating presence absence for B rhodani ----

# Keep occurrences with sampling methods: Kick-sampling, surber-sampling.
# These methods are suitable in running waters, and common.
sampling_methods <- c(
  "Rot (1 min)",
  "Surber (stor)",
  "Rot (5 min)",
  "Rot (1 min) x 2",
  "Surber (liten)",
  "Surber dominans verdi",
  "Surber (liten)*5 (Transekt serie)",
  "Rot (2 min)",
  "Rot (1/2 min) x 2",
  "Rot (3 min)",
  "R1",
  "Rot (3 min) x 2",
  "Rot (2 min) x 2",
  "Rot (1/2 min)"
)

sampling_methods <- unique(only_ntnu$samplingProtocol[only_ntnu$samplingProtocol != ""])

occurrences_NTNU <- occurrences_NTNU %>%
  dplyr::filter(samplingProtocol %in% sampling_methods) # reduced number of occurrences from 313119 to 258105, ca 18 % removed

# Sampling event level:
events_NTNU <- occurrences_NTNU %>%
  group_by(eventID) %>%
  dplyr::summarise(
    scientificNames = paste0(unique(scientificName), collapse = ", "),
    decimalLatitude = paste0(unique(decimalLatitude), collapse = ", "),
    decimalLongitude = paste0(unique(decimalLongitude), collapse = ", ")
  )

events_NTNU <- events_NTNU %>%
  mutate(presence = dplyr::if_else(stringr::str_detect(scientificNames, regex("Baetis rhodani")), 1, 0))
# 22444 observations (unique events)

# Save file
events_NTNU$decimalLatitude <- as.numeric(events_NTNU$decimalLatitude)
events_NTNU$decimalLongitude <- as.numeric(events_NTNU$decimalLongitude)
save(events_NTNU,
     file = here::here("data", "derived_data", "presence_absence_dataset.Rda"))
