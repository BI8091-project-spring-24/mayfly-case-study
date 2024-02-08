################################################################################

# Running PointedSDMs

################################################################################

# 0. PACKAGES ----
library(here)
library(dplyr)
library(terra)
library(sf)
library(PointedSDMs)
library(INLA)

# 1. PREPARE DATA FOR POINTEDSDMS ----

## 1.1. Load data ----

# Set options for the INLA package to use it "experimental" features
bru_options_set(inla.mode = "experimental")

# Load data in
load(here("data", "cleaned_insectdata.rda"))

# Define projection
projection <- "+proj=longlat +ellps=WGS84"

# Extract species occurrence records
insect_data <- cleaned_insectdata

# Read in climate data
bio1 <- terra::rast(here("data", "bio1_norway.tif"))

# Normalize climate data by scaling it
bio1_scaled <- scale(bio1)

## 1.2. Create mesh object ---- 
# Mesh objects are used by INLA to aproximate spatial model for the IntegratedSDM

# Create spatial points dataframe from occurrence records
mayfly_points <- st_as_sf(insect_data, coords = c("decimalLongitude", "decimalLatitude"),
                          crs = 4326)

# Define a study area as a bounding box from the points
study_area <- st_bbox(mayfly_points)

# Extract coordinates from mayfly_points for mesh
coords <- st_coordinates(mayfly_points)

# Create mesh with INLA
max_edge_length <- 5
offset_distance <- 5

mesh <- inla.mesh.2d(loc = coords,
                     max.edge = c(max_edge_length),
                     offset = c(offset_distance),
                     crs = projection)

plot(mesh)

# 2. RUN INTEGRATED SDM ----
# Specify model -- here we run a model with one spatial covariate and a shared spatial field

model <- intModel(insect_data, spatialCovariates = bio1_scaled, 
                  Coordinates = c('decimalLongitude', 'decimalLatitude'),
                  Projection = projection, Mesh = mesh, responsePA = 'Present')


# Run integrated model
modelRun <- fitISDM(model, options = list(control.inla = list(int.strategy = 'eb'), 
                                          safe = TRUE))
summary(modelRun)

# Create prediction plots

predictions <- predict(modelRun, mesh = mesh,
                       mask = region, 
                       spatial = TRUE,
                       fun = 'linear')

plot(predictions)