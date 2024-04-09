################################################################################

# Spatial filtering of insect datapoints

################################################################################

# 1. Load river data -----------------------------------------------------------

## Dataset #Elvenett" from NVE, covering all of Norway including Svalbard
# Format: GeoJSON v1.0, Geographical coordinates WGS84 - lat long, overlapping

#elvenett_sf  <- sf::read_sf("https://ntnu.box.com/shared/static/d0o69swa55oij3u0wber0gz59u6z0c82.geojson") # issues, not working

elvenett_sf <- sf::read_sf(here("data","source_data","Elv_Elvenett.geojson"))
# Change to projected coordinates, UTM zone N33
elvenett_sf_P <- sf::st_transform(elvenett_sf, 32633)


# 2. Load cleaned insectdata ---------------------------------------------------

load(file = here::here("data","derived_data","insectdata_low_uncertainty.rda"))


# 3. Create spatial file showing all sampling locations ------------------------

insectdata_locations <- insectdata_low_uncertainty %>%
  dplyr::group_by(locality, decimalLatitude,decimalLongitude) %>%
  dplyr::summarize(
    datasetName = paste0(unique(datasetName), collapse = ", "),
    publisher = paste0(unique(publisher), collapse = ", "),
    datasetID = paste0(unique(datasetID), collapse = ", "),
    datasetKey = paste0(unique(datasetKey), collapse = ", "),
    N_occurrences = length(unique(occurrenceID)),
    N_samplingEvents = length(unique(eventID)),
    locationIDs = paste(unique(locationID), collapse=", "),
    N_taxa = length(unique(scientificName)), # could change to taxonKey?
    Scientific_names = paste(unique(scientificName), collapse = ", "),
    phylums = paste(unique(phylum), collapse = ", "),
    N_methods = length(unique(samplingProtocol)),
    methods = paste0(unique(samplingProtocol), collapse = ", "),
    N_yrs = length(unique(year)),
    years = paste0(unique(year), collapse = ", "),
    first_year = min(year),
    last_year = max(year),
    period_yrs = (last_year - first_year),
    N_months = length(unique(month)),
    months = paste0(unique(month), collapse = ", "),
    field_number = paste0(unique(fieldNumber), collapse = ", "),
    collectionCode = paste0(unique(collectionCode), collapse = ", "),
    associatedReferences = paste0(unique(associatedReferences), collapse = ", ")
  ) 

# Make location data-frame a spatial object 
insectdata_locations_sf <- st_as_sf(insectdata_locations, coords = c("decimalLongitude","decimalLatitude"), crs = 4326, remove = FALSE) # crs identifier for WGS84
# Create a version with projected coordinates
insectdata_locations_sf_P <- sf::st_transform(insectdata_locations_sf, 32633)


# 4. Create 100m buffer for elvenett ----

# OBS! Large files, takes long to run.

# Create 100m buffer for elvenett
elvenett_buf_100m <- sf::st_buffer(elvenett_sf_P,100) 
# Store as a geopackage file for later use
elvenett_buf_100m %>%
  st_write(here::here("data","derived_data","elvenett_buf_100m.gpkg"))


# 5. Filter 100m with elvenett ----

# Join invertebrate datapoints with info from the buffer they overlap with
insectdata_buf100m <-  st_join(insectdata_locations_sf_P,elvenett_buf_100m, join = st_intersects, largest = TRUE) 
# largest = TRUE makes sure no extra rows with NAs are added to the dataframe

# Keep only invertebrate datapoints which lay within the buffer.
insectdata_buf100m  <- insectdata_buf100m[elvenett_buf_100m, , op = st_intersects] 
# filter, get x observations (from x observations)

# Save file
save(insectdata_buf100m, file = here("data", "derived_data","insectdata_buf100m.rda"))


# 6. Create filtered occurrence dataset ----

# Want to keep the occurrence-records corresponding to the selected localities.
# Need to filter the file "insectdata_low_uncertainty.rda"

# Drop geometry
sf::st_drop_geometry(insectdata_buf100m)

# Perform an inner join, keep only occurrence rows with coordinates found in the 
# filtered locality dataset
insectdata_low_uncertainty_100m <- inner_join(insectdata_low_uncertainty,insectdata_buf100m, by = c("decimalLatitude","decimalLongitude"))
  
# Save file
save(insectdata_low_uncertainty_100m, file = here("data", "derived_data","insectdata_low_uncertainty_100m.rda"))

