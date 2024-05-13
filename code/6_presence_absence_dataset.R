#############################################

# Create presence/absence file 

############################################

# Download NTNU dataset ----

# Searched for the dataset in GBIF, create a download request, date 22.04.024

# GBIF download
download_url <- "https://api.gbif.org/v1/occurrence/download/request/0200986-240321170329656.zip"
tmpfile <- tempfile()
tmpdir <- tempdir()
download.file(download_url,tmpfile)
occurrences_NTNU <- rio::import(unzip(tmpfile,files="occurrence.txt",exdir = tmpdir), encoding = "UTF-8") # on the fly unzip and import to R object 

# Creating presence absence for B rhodani ----

# Keep occurrences with sampling methods: Kick-sampling, surber-sampling.
# These methods are suitable in running waters, and common.

print(unique(occurrences_NTNU$samplingProtocol))

sampling_methods <- c("Rot (1 min)","Surber (stor)","Rot (5 min)",
                      "Rot (1 min) x 2","Surber (liten)",
                      "Surber dominans verdi","Surber (liten)*5 (Transekt serie)",
                      "Rot (2 min)","Rot (1/2 min) x 2",
                      "Rot (3 min)","R1","Rot (3 min) x 2",
                      "Rot (2 min) x 2","Rot (1/2 min)")

occurrences_NTNU <- occurrences_NTNU %>%
  dplyr::filter(samplingProtocol %in% sampling_methods) # reduced number of occurrences from 313119 to 258105, ca 18 % removed

# Sampling event level: 
events_NTNU <- occurrences_NTNU %>%
  group_by(eventID) %>%
  dplyr::summarise(scientificNames = paste0(unique(scientificName), collapse = ", "),
                   decimalLatitude = paste0(unique(decimalLatitude), collapse = ", "),
                   decimalLongitude = paste0(unique(decimalLongitude), collapse = ", ")) 
  
events_NTNU <- events_NTNU %>%
  mutate(presence = dplyr::if_else(stringr::str_detect(scientificNames, regex("Baetis rhodani")),1,0))
# 22444 observations (unique events)

# Save file
save(events_NTNU,file = here::here("data","derived_data","presence_absence_dataset.Rda"))


