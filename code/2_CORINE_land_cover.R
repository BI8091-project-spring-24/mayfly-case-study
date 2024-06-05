################################################################################

# 5. CORINE Land Cover

################################################################################

# 1. LOAD CORINE 2018 STATUS LAYER ----

# Add download link
U2018_CLC2018_V2020_20u1 <- ("https://ntnu.box.com/shared/static/iub514rfjnkopg3nu4nc18j4axq5jfon.tif")

# Download the file
conditional_download(U2018_CLC2018_V2020_20u1, "data/source_data/U2018_CLC2018_V2020_20u1.tif")

# Read in the layer
corine_2018 <- rast(here("data", "source_data", "U2018_CLC2018_V2020_20u1.tif"))

# 2. CUT AND MASK CORINE LAYER TO NORWAY ----

## 2.1. Download country shapefile ----

norway <- geodata::gadm(country = "NOR", level = 0, 
                        path = tempdir(),
                        version = "latest")
# Check shapefile
plot(norway)

## 2.2. Re-project shapefile to match projection of CORINE layers ----

# Check projections of Norway and CORINE layers
crs(norway, proj = TRUE) #"+proj=longlat +datum=WGS84 +no_defs"
crs(corine_2018, proj = TRUE) #"+proj=laea +lat_0=52 +lon_0=10 +x_0=4321000 +y_0=3210000 +ellps=GRS80 +units=m +no_defs"

# Re-project Norway shapefile to the CORINE layers
norway_corine_projection <- project(norway, crs(corine_2018))

# Check projection
crs(norway_corine_projection, proj = TRUE) #"+proj=laea +lat_0=52 +lon_0=10 +x_0=4321000 +y_0=3210000 +ellps=GRS80 +units=m +no_defs"

## 2.3. Crop and mask CORINE 2018 to Norway ----
norway_corine_2018 <- crop(corine_2018, norway_corine_projection,
                            mask = TRUE)

## 2.4. Save cropped layer ----
terra::writeRaster(norway_corine_2018,
                   here("data", "derived_data", "norway_corine_2018.tif"),
                   overwrite = TRUE)


# 3. CHANGE COVER LAYER VALUES ----

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

