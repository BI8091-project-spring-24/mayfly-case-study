#############################################

# Create presence/absence file 

############################################

# Download NTNU dataset ----

# Searched for the dataset in GBIF, create a download request, date 22.04.024

# GBIF download
datset_key <- "33591b80-0e31-480c-82ce-2f57211b10e6" # select freshwater ecological collection

# create download request
occurrences_NTNU_download <- occ_download(pred("datasetKey", datset_key),
                                          pred("gadm", "NOR"),
                                          pred_gte("year", 1950))
occ_download_wait(occurrences_NTNU_download)

# save as R object
occurrences_NTNU <- occ_download_get(occurrences_NTNU_download) %>%
  occ_download_import()


# Creating presence absence for B rhodani ----

# Keep occurrences with sampling methods: Kick-sampling, surber-sampling.
# These methods are suitable in running waters, and common.

sampling_methods <- c("Rot (1 min)","Surber (stor)","Rot (5 min)",
                      "Rot (1 min) x 2","Surber (liten)",
                      "Surber dominans verdi","Surber (liten)*5 (Transekt serie)",
                      "Rot (2 min)","Rot (1/2 min) x 2",
                      "Rot (3 min)","R1","Rot (3 min) x 2",
                      "Rot (2 min) x 2","Rot (1/2 min)")

occurrences_NTNU <- occurrences_NTNU %>%
  dplyr::filter(samplingProtocol %in% sampling_methods) # reduced number of occurrences from 313119 to 258105, ca 18 % removed

# Sampling event level: 
events_NTNU <- occurrences_NTNU %>%
  group_by(eventID) %>%
  dplyr::summarise(scientificNames = paste0(unique(scientificName), collapse = ", "),
                   decimalLatitude = paste0(unique(decimalLatitude), collapse = ", "),
                   decimalLongitude = paste0(unique(decimalLongitude), collapse = ", "),
                   samplingProtocol = paste0(unique(samplingProtocol), collapse = ", ")) 

# Inspect Coordinates
sorted_latitudes <- sort(events_NTNU$decimalLatitude, decreasing = FALSE) #44.45 latitude is not in Norway
sorted_longitudes <- sort(events_NTNU$decimalLongitude, decreasing = FALSE) #"-8.45843", "-8.4622", "-8.45942" not in Norway

# Add presence absence column and remove records with faulty coordinates
events_NTNU <- events_NTNU %>%
  mutate(presence = dplyr::if_else(stringr::str_detect(scientificNames, regex("Baetis rhodani")),1,0)) |>
  # remove records with faulty coordinates
  filter(!decimalLongitude %in% c("-8.45843", "-8.4622", "-8.45942")) |>
  filter(!decimalLatitude == "44.45")
# 22403 observations (unique events)

# Save file
events_NTNU$decimalLatitude <- as.numeric(events_NTNU$decimalLatitude)
events_NTNU$decimalLongitude <- as.numeric(events_NTNU$decimalLongitude)
save(events_NTNU,file = here::here("data","derived_data","presence_absence_dataset.Rda"))

# Map of presences and absences ----

# Download map of Norway
norway <- geodata::gadm(country = "NOR", level = 0, 
                        path = tempdir(),
                        version = "latest")

# Convert norway to sf object
norway_sf <- st_as_sf(norway)

# Convert occurrences to spatial dataframe for plotting
events_NTNU_sf <-st_as_sf(events_NTNU,
                         coords = c("decimalLongitude","decimalLatitude"),
                         crs = crs(norway_sf))

# Map for presences
presences <- events_NTNU_sf |>
  filter(presence == 1) |>
  ggplot() +
  geom_sf(data = norway_sf, fill = "lightgray", color = "white") +
  geom_sf(aes(color = samplingProtocol)) +
  annotation_north_arrow(location = "br", which_north = "true",
                         pad_y = unit(0.8, "cm"),
                         style = north_arrow_fancy_orienteering) +
  annotation_scale(location = "br", width_hint = 0.35) +
  theme_classic() +
  theme(panel.grid.major = element_blank(), 
        panel.grid.minor = element_blank(),
        legend.position = "none")

# Map for absences
absences <- events_NTNU_sf |>
  filter(presence == 0) |>
  ggplot() +
  geom_sf(data = norway_sf, fill = "lightgray", color = "white") +
  geom_sf( aes(color = samplingProtocol)) +
  theme_classic() +
  theme(panel.grid.major = element_blank(), 
        panel.grid.minor = element_blank(),
        legend.position = "none",
        axis.title.y = element_blank(),
        axis.text.y = element_blank(),
        axis.ticks.y = element_blank(),
        axis.line.y = element_blank())

# Arrange the two plots in a single figure
presence_absence_map_no_legend <- plot_grid(presences, absences,
                                  ncol = 2, align = "hv", rel_heights = c(1, 1),
                                  labels = c("A", "B"))

# Extract legend from one of the plots
legend <- get_legend(absences + theme(legend.position = "bottom"))

# Arrange the two plots in a single figure
presence_absence_map <- plot_grid(presence_absence_map_no_legend, legend, 
                                  ncol = 1, rel_heights = c(1, 0.1))

# Save to file
ggsave(here("figures", "presence_absence_map.png"),
       width=13, height=9)
