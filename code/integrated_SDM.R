################################################################################

# Running PointedSDMs

################################################################################

# 0. PACKAGES ----
library(here)
library(dplyr)
library(terra)
library(sf)
library(PointedSDMs)

# 1. RUN POINTEDSDMS ----

# Set options for the INLA package to use it "experimental" features
bru_options_set(inla.mode = "experimental")

# Load data in
load(here("data", "cleaned_insectdata.rda"))

# Define projection
projection <- "+proj=longlat +ellps=WGS84"

# Extract species occurrence records
species <- SolitaryTinamou$datasets

# Normalize climate data by scaling it
# here they use NPP but we should use one of the climate variables
NPP <- scale(terra::rast(system.file('extdata/SolitaryTinamouCovariates.tif', 
                                     package = "PointedSDMs"))$NPP)

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