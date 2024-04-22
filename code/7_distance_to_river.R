################################################################################

# Distance to river

################################################################################

# Load river data ----

## Dataset #Elvenett" from NVE, covering all of Norway including Svalbard
# Format: GeoJSON v1.0, Geographical coordinates WGS84 - lat long, overlapping
#elvenett_sf  <- sf::read_sf("https://ntnu.box.com/shared/static/d0o69swa55oij3u0wber0gz59u6z0c82.geojson") # issues, not working
elvenett_sf <- sf::read_sf(here("data","source_data","Elv_Elvenett.geojson"))
# Change to projected coordinates
elvenett_sf_P <- sf::st_transform(elvenett_sf, 32633) # UTM zone N33

