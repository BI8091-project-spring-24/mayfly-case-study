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

# Define a study area as a bounding box

# Retrieve mesh object - not sure what a mesh object is an how to fix that
mesh <- SolitaryTinamou$mesh

# Specify model -- here we run a model with one spatial covariate and a shared spatial field

model <- intModel(species, spatialCovariates = NPP, Coordinates = c('X', 'Y'),
                  Projection = projection, Mesh = mesh, responsePA = 'Present')

# Plot 1

region <- SolitaryTinamou$region

model$plot(Boundary = FALSE) + 
  geom_sf(data = st_boundary(region))

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