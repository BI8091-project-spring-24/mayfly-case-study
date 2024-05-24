################################################################################

# Distance to river

################################################################################

# 0. PACKAGES -----
library(here)
library(terra)
library(sf)

# 1. READ IN DATA ----

## 1.1. Elvenett ----

# Download data from box
#elvenett <- ("https://ntnu.box.com/shared/static/d0o69swa55oij3u0wber0gz59u6z0c82.geojson")
main_rivers <- ("https://ntnu.box.com/shared/static/k8z5amhu343xwdtorbafcm0qcxug4uy3.geojson")
#download.file(elvenett, "Elv_Elvenett.geojson")
download.file(main_rivers, "Elv_Hovedelv.geojson")

# Load river data 
  # Dataset #Elvenett" from NVE, covering all of Norway including Svalbard
  # Format: GeoJSON v1.0, Geographical coordinates WGS84 - lat long, overlapping
#elvenett_sf <- sf::read_sf(here("data","Elv_Elvenett.geojson"))
main_rivers_sf <- sf::read_sf(here("data","Elv_Hovedelv.geojson"))

## 1.2. CORINE -----
corine_2018 <- rast(here("data", "corine_2018_modified_classes.tif"))

# 2. PREPARE FOR ANALYSIS ----

# Change to projected coordinates
#elvenett_sf_P <- sf::st_transform(elvenett_sf, 32633) # UTM zone N33
main_rivers_sf_P <- sf::st_transform(main_rivers_sf, 32633)

# Aggreggate raster layer to 1km x 1km to save computing power
aggregated_corine <- terra::aggregate(corine_2018, fact = 10, fun = max , na.rm = TRUE)

# 3. CALCULATE DISTANCE FROM CENTROIDS TO NEAREST RIVER ----

# Calculate centroids of each CORINE cell
corine_centroids <- as.data.frame(xyFromCell(aggregated_corine, 1:ncell(aggregated_corine)))

# Convert centroids df into spatial object
corine_centroids_sf <- st_as_sf(corine_centroids, coords = c("x", "y"), crs = st_crs(main_rivers_sf_P))

# Find nearest river segment for each centroid
nearest_river_idx <- st_nearest_feature(corine_centroids_sf, main_rivers_sf_P) # do this step first to save memory when calculating distances

# Calculate distance from centroid to nearest river segment
distances <- st_distance(corine_centroids_sf, main_rivers_sf_P[nearest_river_idx, ], by_element = TRUE)

# 4. SAVE CALCULATED DISTANCES AS NEW RASTER LAYER ----

# Create new raster for the distances
distance_raster <- aggregated_corine

# Assign calculated distances to new raster layer
values(distance_raster) <- as.numeric(distances)

# Save the raster 
terra::writeRaster(distance_raster, 
                   here("data", "distance_to_river_raster.tif"))
