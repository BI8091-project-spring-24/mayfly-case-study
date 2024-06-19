################################################################################

# 5. CORINE Land Cover

################################################################################

# 1. LOAD CORINE 2018 STATUS LAYER ---------------------------------------------

# Add download link
U2018_CLC2018_V2020_20u1 <- ("https://ntnu.box.com/shared/static/iub514rfjnkopg3nu4nc18j4axq5jfon.tif")

# Download the file
download.file(U2018_CLC2018_V2020_20u1, here("data", "U2018_CLC2018_V2020_20u1.tif"))

# Read in the layer
corine_2018 <- rast(here("data", "U2018_CLC2018_V2020_20u1.tif"))

# 2. CUT AND MASK CORINE LAYER TO NORWAY ---------------------------------------

## 2.1. Download country shapefile ---------------------------------------------

norway <- geodata::gadm(country = "NOR", level = 0, 
                        path = tempdir(),
                        version = "latest")
# Check shapefile
plot(norway)

## 2.2. Re-project shapefile to match projection of CORINE layers --------------

# Check projections of Norway and CORINE layers
crs(norway, proj = TRUE) #"+proj=longlat +datum=WGS84 +no_defs"
crs(corine_2018, proj = TRUE) #"+proj=laea +lat_0=52 +lon_0=10 +x_0=4321000 +y_0=3210000 +ellps=GRS80 +units=m +no_defs"

# Re-project Norway shapefile to the CORINE layers
norway_corine_projection <- project(norway, crs(corine_2018))

# Check projection
crs(norway_corine_projection, proj = TRUE) #"+proj=laea +lat_0=52 +lon_0=10 +x_0=4321000 +y_0=3210000 +ellps=GRS80 +units=m +no_defs"

## 2.3. Crop and mask CORINE 2018 to Norway ------------------------------------
norway_corine_2018 <- terra::crop(corine_2018, norway_corine_projection,
                            mask = TRUE, overwrite = TRUE)

## 2.4. Save cropped layer -----------------------------------------------------
terra::writeRaster(norway_corine_2018,
                   here("data", "derived_data" , "norway_corine_2018.tif"),
                   overwrite = TRUE)

# 3. CHANGE COVER LAYER VALUES -------------------------------------------------

## 3.1. Change layer values ----------------------------------------------------

# The CORINE 2018 Land Cover Status Layer values will be aggregated to only maintain the values relevant for the analysis

# Urban Fabric
  # all the urban classes are pooled together, due to their sparse distribution across Norway
norway_corine_modified <- app(norway_corine_2018,
                              fun = function(x){x[x %in% c(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11)] <- 1; 
                              return(x)})

# Complex agricultural patterns
norway_corine_modified <- app(norway_corine_modified,
                              fun = function(x){x[x %in% c(12, 18, 20)] <- 20; 
                              return(x)})

#Agriculture and significant natural vegetation
norway_corine_modified <- app(norway_corine_modified,
                              fun = function(x){x[x == 21] <- 21; 
                              return(x)})

#Forests
norway_corine_modified <- app(norway_corine_modified,
                              fun = function(x){x[x %in% c(23, 24, 25)] <- 25; 
                              return(x)})

#Moors, Heathland & Natural Grassland
norway_corine_modified <- app(norway_corine_modified,
                              fun = function(x){x[x %in% c(26, 27)] <- 26; 
                              return(x)})
#Transitional woodland shrub
norway_corine_modified <- app(norway_corine_modified,
                              fun = function(x){x[x == 29] <- 29; return(x)})

#Sparsely vegetated areas
norway_corine_modified <- app(norway_corine_modified,
                              fun = function(x){x[x == 32] <- 32; return(x)})

# Water courses
norway_corine_modified <- app(norway_corine_modified,
                              fun = function(x){x[x == 40] <- 40; return(x)})

# Water bodies
norway_corine_modified <- app(norway_corine_modified,
                              fun = function(x){x[x == 41] <- 41; return(x)})

#Other classes
norway_corine_modified <- app(norway_corine_modified,
                              fun = function(x){x[x %in% c(30, 31, 33, 34, 35, 36, 39, 43, 44, 128)] <- 0; 
                              return(x)})

# Save the modified corine stack 
terra::writeRaster(norway_corine_modified,
                   here("data", "derived_data", "corine_2018_modified_classes.tif"),
                   overwrite = TRUE)

## 3.2.Plot map of land cover classes ------------------------------------------
  
# Convert raster to df
corine_modified_df <- as.data.frame(norway_corine_modified, xy = TRUE)

# Convert norway shapefile to sf
norway_corine_projection_sf <- st_as_sf(norway_corine_projection)

# Define labels
labels <- c("0" = "Other", "1" = "Urban", "20" = "Complex Agriculture",
            "21" = "Agriculture & Nature", "25" = "Forests", 
            "26" = "Moors, Heathland & Grassland", "29" = "Transitional Woodland", 
            "32" = "Sparse Vegetation","40" = "Water Courses", "41" = "Water Bodies")

# Plot map
corine_class <- ggplot(corine_modified_df, aes(x = x, y = y, fill = as.factor(lyr.1))) +
  geom_tile() +
  annotation_north_arrow(location = "br", which_north = "true",
                         pad_y = unit(0.8, "cm"),
                         style = north_arrow_fancy_orienteering) +
  annotation_scale(location = "br", width_hint = 0.35) +
  scale_fill_manual(values = c("0" = "grey", "1" = "maroon", "20" = "#E31A1C", "21" = "dodgerblue2", 
                               "25" = "green4", "26" = "#FF7F00", "29" = "gold1", 
                               "32" = "#6A3D9A", "40" = "aquamarine", "41" = "cornflowerblue"),
                    labels = labels) +
  coord_fixed() +
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
        legend.position = "bottom",
        legend.title = element_blank())

# Save to file
ggsave(here("figures", "corine_2018_norway.png"),
       width=13, height=9)

## 3.3. Aggregate raster to 1km ------------------------------------------------

# Define custom aggregation function - so we can get a count of the previous classes in the aggregated raster
count_values <- function(values) {
  unique_values <- c(0, 1, 20, 21, 25, 26, 29, 32, 40, 41)
  counts <- sapply(unique_values, function(val) sum(values == val, na.rm = TRUE))
  return(counts)
}

# Aggregate raster with custom function
agg_raster <- aggregate(norway_corine_modified, fact = 10, 
                        fun = count_values)

# Extract the counts for each value and create a data frame
unique_values <- c(0, 1, 20, 21, 25, 26, 29, 32, 40, 41)
counts_matrix <- as.matrix(agg_raster)

# Function to convert counts to a formatted string
format_counts <- function(counts) {
  count_str <- paste(unique_values, counts, sep = "x", collapse = ", ")
  return(count_str)
}

# Apply the function to each cell
formatted_values <- apply(counts_matrix, 1, format_counts)

# Create a new raster to store the formatted values
result_raster <- rast(nrows = nrow(agg_raster), ncols = ncol(agg_raster), 
                      ext = ext(agg_raster), vals = formatted_values)
 
# Print the aggregated raster values
result_matrix <- matrix(values(result_raster), nrow = nrow(result_raster), byrow = TRUE)
print(result_matrix)


# Aggregate to 1km (from 100m x 100m)
aggregated_norway_corine_2018 <- terra::aggregate(norway_corine_modified,
                                                  fact = 10, fun = "max")


# Save aggregated raster
terra::writeRaster(aggregated_norway_corine_2018,
                   here("data", "derived_data",
                        "aggregated_corine_2018_modified_classes.tif"),
                   overwrite = TRUE)