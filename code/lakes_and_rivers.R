# Lake and river data

## Dataset "Elvenett, hovedelv" from NVE
hovedelv_sf  <- sf::read_sf("https://ntnu.box.com/shared/static/09y8k4t2svbkpimm5fhebe0u4nf5od9e.geojson")

# Change to projected coordinates
hovedelv_sf_P <- sf::st_transform(hovedelv_sf, 32633) # N33


## Dataset Norwegian lakes
innsjo_sf  <- sf::read_sf("https://ntnu.box.com/shared/static/dvv6w3bu1o3gdgga0ucl45ry5sofrv8g.geojson")

# Change to projected coordinates
innsjo_sf_P <- sf::st_transform(innsjo_sf, 32633) # N33