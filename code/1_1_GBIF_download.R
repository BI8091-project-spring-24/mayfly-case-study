################################################################################

# 1.1 Download file

################################################################################

# Connect to GBIF --------------------------------------------------------------

# Need a GBIF account
# Setting username, password and email in my .Renviron. 
usethis::edit_r_environ()
# GBIF_USER="my username"
# GBIF_PWD="my password"
# GBIF_EMAIL="my email"

# Create download request ------------------------------------------------------

# Find taxonkey - get list of gbif keys to filter download
species_names <- c("Baetis rhodani (Pictet, 1843)")

gbif_taxon_keys <- species_names %>%
  rgbif::name_backbone_checklist() %>%
  filter(!matchType == "NONE") %>%
  pull(usageKey)

# Send download request
download_key <- occ_download(
  pred_in("taxonKey", gbif_taxon_keys),
  pred("gadm", "NOR"), # Norway
  pred_gte("year", 1950), # Greater than or equal to year 1950
  pred("hasCoordinate", TRUE), 
  format = "DWCA") # Download as a Darwin Core Archive file

# Check progress
occ_download_wait(download_key)
#  Download key: 0058633-231120084113126
# Download link: https://api.gbif.org/v1/occurrence/download/request/0058633-231120084113126.zip

# Import GBIF download and save ------------------------------------------------

# Import
insectdata <- occ_download_get(download_key) %>%
  occ_download_import()

# Save file
dir.create("data/source_data2", showWarnings = FALSE)
save(insectdata, file = here::here("data","source_data","insectdata.rda"))
