#########################################################

# Download ---------------------------------------------

#########################################################

# Connect to GBIF --------------------------------------

# Need a GBIF account
# Setting username, password and email in my .Renviron. 
usethis::edit_r_environ()
# GBIF_USER="my username"
# GBIF_PWD="my password"
# GBIF_EMAIL="my email"

# Create download request -----------------------------------------

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

# Check the progress, get string for checking status
download_key

# Import and save dataset ------------------------------------------

res_meta <- occ_download_wait(download_key, status_ping = 5, curlopts = list(), quiet = FALSE)
## 2. Download the data as .zip (can specify a path)
res_get <- occ_download_get(res)
## 3. Load the data into R
res_data <- occ_download_import(res_get)
