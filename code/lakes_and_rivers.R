# Lake and river data

# Lake data
## Data from NVE: innsjødatabase
#innsjo_sf <- geojsonsf::geojson_sf(here::here("data","source_data","NVE_innsjo","NVEData","Innsjo_Innsjo.geojson"))

# Change to projected coordinates
#innsjo_sf_P <- sf::st_transform(innsjo_sf, 32633)


## Dataset "Elvenett, hovedelv" from NVE
Hovedelv_sf  <- sf::read_sf("https://app.box.com/index.php?rm=box_download_shared_file&shared_name=ihnd17x16lwwqpsphix9ehuuj8sw4o6t&file_id=f_799286199957")

