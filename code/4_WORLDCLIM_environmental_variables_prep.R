################################################################################

# Cut environmental variables to Norway

################################################################################

# 1. CUT BIOCLIMATIC VARIABLES TO NORWAY ---------------------------------------

# Download bioclimatic variables
bioclim <- worldclim_global(var='bio', res=0.5, path=here("data", "source_data"))

# Load bioclimatic variables
bioclim10 <- bioclim$wc2.1_30s_bio_10 # mean temp warmest quarter
bioclim11 <- bioclim$wc2.1_30s_bio_11 # mean temp coldest quarter

# Download Norway country shapefile
norway <- geodata::gadm(country = "NOR", level = 0, 
                        path = tempdir(),
                        version = "latest")

# Match projection of shapefile and bioclimatic variables
projection <- "+proj=longlat +ellps=WGS84"
norway_reprojected <- project(norway, crs(projection))
bio10_reprojected <- project(bioclim10, crs(projection))
bio11_reprojected <- project(bioclim11, crs(projection))

# Check that projections match
crs(norway_reprojected, proj = TRUE)
crs(bio10_reprojected, proj = TRUE)

# Cut and mask bioclimatic variables to Norway
bio10_norway <- crop(bio10_reprojected, norway_reprojected, 
                    mask = TRUE)
bio11_norway <- crop(bio11_reprojected, norway_reprojected, 
                     mask = TRUE)

# Save the new bioclimatic variables
terra::writeRaster(bio10_norway, 
                   here("data", "derived_data", "bio10_norway.tif"))
terra::writeRaster(bio11_norway, 
                   here("data", "derived_data", "bio11_norway.tif"))

# 2. PLOT BIOCLIMATIC VARIABLES TO NORWAY --------------------------------------

# Read in CORINE layer
norway_corine <- rast(here("data", "derived_data", "norway_corine_2018.tif"))

# Re-project bio10 to match CORINE
bio10_corine_proj <- project(bio10_norway, crs(norway_corine))

# Convert bio10 to df
bio10_corine_proj_df <- as.data.frame(bio10_corine_proj, xy = TRUE) |>
  rename(bio10 = wc2.1_30s_bio_10)

# Plot map 
bio10_map <- ggplot()+
  geom_tile(data = bio10_corine_proj_df, aes(x = x, y = y, fill = bio10)) +
  coord_fixed() +
  annotation_north_arrow(location = "br", which_north = "true",
                         pad_y = unit(0.8, "cm"),
                         style = north_arrow_fancy_orienteering) +
  annotation_scale(location = "br") +
  scale_colour_viridis_c() +
  theme_classic() +
  theme(panel.grid.major = element_blank(), 
        panel.grid.minor = element_blank(),
        axis.title.y = element_blank(),
        axis.text.y = element_blank(),
        axis.ticks.y = element_blank(),
        axis.line.y = element_blank(),
        axis.title.x = element_blank(),
        axis.text.x = element_blank(),
        axis.ticks.x = element_blank(),
        axis.line.x = element_blank(),
        legend.position = "bottom")

# Save to file
ggsave(here("figures", "bio10_norway.png"),
       width=13, height=9)

# 3. CHECK CORRELATION ---------------------------------------------------------