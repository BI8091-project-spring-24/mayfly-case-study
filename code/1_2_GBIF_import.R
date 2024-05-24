################################################################################

# 1.2 Import GBIF download

################################################################################

# Import GBIF download and save ------------------------------------------------

# Download key: "0058633-231120084113126"

# Import
insectdata <- occ_download_get("0058633-231120084113126") %>%
  occ_download_import()

# Save file
save(insectdata, file = here::here("data","source_data","insectdata.rda"))