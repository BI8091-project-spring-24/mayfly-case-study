################################################################################

# Data mapping

################################################################################

# Mapping datapints against lakes and rivers 

# 1. Load lake and river data --------------------------------------------------

## Dataset "Elvenett, hovedelv" from NVE, covering all of Norway including Svalbard
# Format: GeoJSON v1.0, Geographical coordinates WGS84 - lat long, overlapping
hovedelv_sf  <- sf::read_sf("https://ntnu.box.com/shared/static/k8z5amhu343xwdtorbafcm0qcxug4uy3.geojson")
# Change to projected coordinates
hovedelv_sf_P <- sf::st_transform(hovedelv_sf, 32633) # UTM zone N33

## Dataset #Elvenett" from NVE, covering all of Norway including Svalbard
# Format: GeoJSON v1.0, Geographical coordinates WGS84 - lat long, overlapping
#elvenett_sf  <- sf::read_sf("https://ntnu.box.com/shared/static/d0o69swa55oij3u0wber0gz59u6z0c82.geojson") # issues, not working
elvenett_sf <- sf::read_sf(here("data","source_data","Elv_Elvenett.geojson"))
# Change to projected coordinates
elvenett_sf_P <- sf::st_transform(elvenett_sf, 32633) # UTM zone N33

## Dataset Norwegian lakes
#innsjo_sf  <- sf::read_sf("https://ntnu.box.com/shared/static/dvv6w3bu1o3gdgga0ucl45ry5sofrv8g.geojson")
# Change to projected coordinates
#innsjo_sf_P <- sf::st_transform(innsjo_sf, 32633) # N33

# 2. Load cleaned insectdata ---------------------------------------------------

load(file = here::here("data","derived_data","insectdata_low_uncertainty.rda"))

# 3. Create spatial file showing all sampling locations ------------------------

## 3.1 All data ----
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

## 3.2 Only data with known aquatic sampling ----

# What sampling methods do we have?
unique(insectdata_low_uncertainty$samplingProtocol)

# Filter out all with unknown or unwanted sampling methods
insectdata_water <- insectdata_low_uncertainty %>%
  filter(samplingProtocol %in% c("Rot (1 min)","Rot (5 min)","Surber (stor)","Surber (liten)"))
  # This leave us with 12944 observations we can use to estimate the typical uncertainty in water sampling locations. (Distance to river from sampling location)

insectdata_locations_water <- insectdata_water %>%
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
insectdata_locations_water_sf <- st_as_sf(insectdata_locations_water, coords = c("decimalLongitude","decimalLatitude"), crs = 4326, remove = FALSE) # crs identifier for WGS84
# Create a version with projected coordinates
insectdata_locations_water_sf_P <- sf::st_transform(insectdata_locations_water_sf, 32633)


# Plot data --------------------------------------------------------------------

mapview(insectdata_locations_sf_P, col.regions = "red") + mapview(hovedelv_sf_P, color = "blue", alpha = 0.6)


# 4. Distance calculations --------------------------------------------------------
# Checking distribution of distances from point (insect datapoint) to line (elvenett)

# Not getting this to make much sense.. hehe
distance_matrix <- sf::st_distance(insectdata_locations_water_sf_P, hovedelv_sf_P)
plot(distance_matrix)



# Spatial filtering 1 ----------------------------------------------------------
# Keep only locations within 3700 meters from rivers, which is the best estimate
# of adult flight distance available.

# Create 3700 m buffer
hovedelv_buf_3700m <- sf::st_buffer(hovedelv_sf_P,3700) 
# Store as a geopackage file for later use (done once)
hovedelv_buf_3700m %>%
  st_write(here::here("data","derived_data","hovedelv_buf_3700m.gpkg"))

hovedelv_buf_3700m <- st_read(here::here("data","derived_data","hovedelv_buf_3700m.gpkg"))

# Filter
# Join invertebrate datapoints with info from the buffer they overlap with
insectdata_buf3700m <-  st_join(insectdata_locations_sf_P,hovedelv_buf_3700m, join = st_intersects, largest = TRUE) 
# largest = TRUE makes sure no extra rows with NAs are added to the dataframe

# Keep only invertebrate datapoints which lay within the buffer. They have the polygon info added
insectdata_buf3700m  <- insectdata_buf3700m[hovedelv_buf_3700m, , op = st_intersects] 
# filter, get 5826 observations (from 5964 observations) so lost 138 observations

# Save as a rda file
save(insectdata_buf3700m, file= here::here("data","derived_data","insectdata_buf3700m.rda"))


# Subset with only datapoints outside the buffer
# Remove based on coordinate column
insectdata_buf3700m_utenfor <- insectdata_locations_sf_P %>%
  filter(!geometry %in% insectdata_buf3700m$geometry) # 138 observations
  
# View the locataions with insectdata outside the buffer
mapview(insectdata_buf3700m_utenfor, col.regions = "red") + mapview(hovedelv_sf_P, color = "blue", alpha = 0.6)
  # Almost all are close to a river, but not one of the large ones from NVE hovedelv. 
  # Could try to use the full river dataset for increased precision



# Spatial filtering 2 ----------------------------------------------------------

# Keep only locations within 50 meters from rivers. Want to see how many % of datapoints 
# which we know should be in water that lie within this distance.

# Create 50 m buffer
hovedelv_buf_50m <- sf::st_buffer(hovedelv_sf_P,50) 
# Store as a geopackage file for later use (done once)
hovedelv_buf_50m %>%
  st_write(here::here("data","derived_data","hovedelv_buf_50m.gpkg"))

hovedelv_buf_50m <- st_read(here::here("data","derived_data","hovedelv_buf_50m.gpkg"))

# Creat 100m buffer
hovedelv_buf_100m <- sf::st_buffer(hovedelv_sf_P,100) 
# Store as a geopackage file for later use (done once)
hovedelv_buf_100m %>%
  st_write(here::here("data","derived_data","hovedelv_buf_100m.gpkg"))

hovedelv_buf_100m <- st_read(here::here("data","derived_data","hovedelv_buf_100m.gpkg"))

# Creat 100m buffer for elvenett
elvenett_buf_100m <- sf::st_buffer(elvenett_sf_P,100) 
# Store as a geopackage file for later use (done once)
elvenett_buf_100m %>%
  st_write(here::here("data","derived_data","elvenett_buf_100m.gpkg"))

# elvenett_buf_100m <- st_read(here::here("data","derived_data","hovedelv_buf_100m.gpkg"))

# Filter 50m
# Join invertebrate datapoints with info from the lake/buffer they overlap with
insectdata_buf50m <-  st_join(insectdata_locations_water_sf_P,hovedelv_buf_50m, join = st_intersects, largest = TRUE) 
# largest = TRUE makes sure no extra rows with NAs are added to the dataframe

# Keep only invertebrate datapoints which lay within the lake/buffer. They have the polygon info added
insectdata_buf50m  <- insectdata_buf50m[hovedelv_buf_50m, , op = st_intersects] 
# filter, get 573 observations (from 1274 observations)

mapview(insectdata_buf50m, col.regions = "red") + mapview(hovedelv_sf_P, color = "blue", alpha = 0.6) + mapview(insectdata_locations_water_sf_P, col.regions = "orange")
  # see that we really should be using the elvenett dataset and increase the buffer to maybe 100 meters?


# Filter 100m with elvenett
# Join invertebrate datapoints with info from the lake/buffer they overlap with
insectdata_buf100m <-  st_join(insectdata_locations_water_sf_P,elvenett_buf_100m, join = st_intersects, largest = TRUE) 
# largest = TRUE makes sure no extra rows with NAs are added to the dataframe

# Keep only invertebrate datapoints which lay within the lake/buffer. They have the polygon info added
insectdata_buf100m  <- insectdata_buf100m[elvenett_buf_100m, , op = st_intersects] 
# filter, get 573 observations (from 1274 observations)

mapview(insectdata_buf100m, col.regions = "red") + mapview(hovedelv_sf_P, color = "blue", alpha = 0.6) + mapview(insectdata_locations_water_sf_P, col.regions = "orange")


# Testing different distances
(573/1274)*100 # 50 meters ish 45 %


# Save as a rda file
save(insectdata_buf50m, file= here::here("data","derived_data","insectdata_buf50m.rda"))


# View the 3000 locataions with insectdata which lie in or within 50 meters from a river.
mapview(insectdata_buf50m) # 3313 points


# Spatial mapping for vannmiljø data -------------------------------------------

# Vannmiljø and NINA vanndata
vannmiljo_vanndata <- insectdata %>%
  dplyr::filter(collectionCode %in% c("NINA Vanndata","vannmiljo"))

vannmiljo_vanndata_locations <- vannmiljo_vanndata %>%
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
vannmiljo_vanndata_locations_sf <- st_as_sf(vannmiljo_vanndata_locations, coords = c("decimalLongitude","decimalLatitude"), crs = 4326, remove = FALSE) # crs identifier for WGS84
# Create a version with projected coordinates
vannmiljo_vanndata_locations_sf_P <- sf::st_transform(vannmiljo_vanndata_locations_sf, 32633)


# Filter
vannmiljo_vanndata_buf50m <-  st_join(vannmiljo_vanndata_locations_sf_P,hovedelv_buf_50m, join = st_intersects, largest = TRUE) 
# largest = TRUE makes sure no extra rows with NAs are added to the dataframe

# Keep only invertebrate datapoints which lay within the lake/buffer. They have the polygon info added
vannmiljo_vanndata_buf50m  <- vannmiljo_vanndata_buf50m[hovedelv_buf_50m, , op = st_intersects] 
# filter, get 10 191 observations (from 288 276 observations)

# Save as a rda file
save(vannmiljo_vanndata_buf50m, file= here::here("data","derived_data","vannmiljo_vanndata_buf50m.rda")) # Ca 2000 locations

# View ----------------
mapview(vannmiljo_vanndata_buf50m) + mapview(hovedelv_sf_P, color = "blue", alpha = 0.6) + mapview(innsjo_sf_P, color = "blue", alpha = 0.7)
