################################################################################

# Running PointedSDMs

################################################################################

# 1. PREPARE DATA FOR POINTEDSDMS ----

## 1.1. Load data ----

# Set options for the INLA package to use it "experimental" features
bru_options_set(inla.mode = "experimental")

# Load occurrences data
load(here("data", "derived_data", "cleaned_insectdata.rda"))
load(here("data", "derived_data", "presence_absence_dataset.rda"))

# Define projection
projection <- "+proj=longlat +ellps=WGS84"

# Extract species occurrence records
presence_only <- cleaned_insectdata
presence_absence_dataset <- events_NTNU

# Read in climate data
bio10 <- terra::rast(here("data", "derived_data", "bio10_norway.tif"))
bio11 <- terra::rast(here("data", "derived_data", "bio11_norway.tif"))

# Read in land cover and distance to river rasters
corine2018 <- terra::rast(here("data", "derived_data", "corine_2018_modified_classes.tif"))
#river_distance <- terra::rast(here("data", "distance_to_river_raster.tif"))

# Normalize environmental variables  by scaling it
bio10_scaled <- scale(bio10)
bio11_scaled <- scale(bio11)
corine2018_scaled <- scale(corine2018)
#river_distance_scaled <- scale(river_distance)

## 1.2. Create mesh object ---- 

# Credits for code: Philip Mostert
# Set CRS
CRS <- '+proj=utm +zone=32 +ellps=WGS84 +datum=WGS84 +units=km +no_defs'

# Download geographical data for Norway 
Norway <- giscoR::gisco_get_countries(resolution = 60)
Norway <- Norway[Norway$NAME_ENGL == 'Norway',]

# Transform object to the CRS set above
Norway <- sf::st_transform(Norway, CRS)

# Crate mesh
Mesh <- INLA::inla.mesh.2d(boundary = fm_sp2segment(Norway),
                           cutoff = 10,
                           max.edge=c(60, 80) * 0.25,
                           min.angle = 20,
                           offset= c(20,50), 
                           crs = st_crs(CRS))



# 2. RUN INTEGRATED SDM ----

## 2.1. Prepare list with presence-only and presence-absence data ----

# Presence-only data - keep only X and Y coordinates
presence_only_full <- presence_only |>
  #filter(institutionCode != "NTNU-VM") |>
  select(decimalLatitude, decimalLongitude) |>
  rename(Y = decimalLatitude,
         X = decimalLongitude)

presence_only_no_vm <- presence_only |>
  filter(institutionCode != "NTNU-VM") |>
  select(decimalLatitude, decimalLongitude) |>
  rename(Y = decimalLatitude,
         X = decimalLongitude)



# Presence-absence data - keep only X, Y and presence/absence columns
presence_absence <- presence_absence_dataset |>
  select(decimalLatitude, decimalLongitude, presence) |>
  rename(Y = decimalLatitude,
         X = decimalLongitude,
         Present = presence)

# Create list with the two datasets
b_rhodani <- list(NTNU = presence_absence,
                Gbif = presence_only_no_vm)

## 2.1. Run Integraded SDM ----

# Specify model -- here we run a model with one spatial covariate and a shared spatial field

# all data as presence-only
model_po_full <- intModel(presence_only_full, spatialCovariates = bio10_scaled, 
                  Coordinates = c('X', 'Y'),
                  Projection = projection, Mesh = Mesh, responsePA = 'Present')

# only presence-only not from VM
model_po_partial <- intModel(presence_only_no_vm, spatialCovariates = bio10_scaled, 
                  Coordinates = c('X', 'Y'),
                  Projection = projection, Mesh = Mesh, responsePA = 'Present')

# only presence-absence from VM
model_pa_only <- intModel(presence_absence, spatialCovariates = bio10_scaled, 
                             Coordinates = c('X', 'Y'),
                             Projection = projection, Mesh = Mesh, responsePA = 'Present')

# integrated model
model_integrated <- intModel(b_rhodani, spatialCovariates = bio10_scaled, 
                             Coordinates = c('X', 'Y'),
                             Projection = projection, Mesh = Mesh, responsePA = 'Present')



# Run integrated models and save them
dir.create("data/model_fits", showWarnings = FALSE)
modelRun_po_full <- fitISDM(model_po_full, options = list(control.inla = list(int.strategy = 'eb'), 
                                          safe = TRUE))
save(modelRun_po_full, file = here("data","model_fits","modelRun_po_full.rda"))


modelRun_po_partial <- fitISDM(model_po_partial, options = list(control.inla = list(int.strategy = 'eb'), 
                                                           safe = TRUE))
save(modelRun_po_partial, file = here("data","model_fits","modelRun_po_partial.rda"))


modelRun_pa_only <- fitISDM(model_pa_only, options = list(control.inla = list(int.strategy = 'eb'), 
                                                              safe = TRUE))
save(modelRun_pa_only, file = here("data","model_fits","modelRun_pa_only.rda"))


modelRun_integrated <- fitISDM(model_integrated, options = list(control.inla = list(int.strategy = 'eb'), 
                                                              safe = TRUE))
save(modelRun_integrated, file = here("data","model_fits","modelRun_integrated.rda"))


### load models (new script?) ###
load("data/model_fits/modelRun_po_full.rda")
load("data/model_fits/modelRun_po_partial.rda")
load("data/model_fits/modelRun_pa_only.rda")
load("data/model_fits/modelRun_integrated.rda")

# Extract summary of the model
summary(modelRun_po_full)
summary(modelRun_po_partial)
summary(modelRun_pa_only)
summary(modelRun_integrated)

# Create a "region" from the shape of bio1_scaled
#get extent of raster
bio10_extent <- terra::ext(bio10_scaled)
#create an sf polygon from the extent
bio10_extent_sf <- st_as_sfc(st_bbox(c(bio10_extent[1], bio10_extent[2], 
                                       bio10_extent[3], bio10_extent[4])), 
                             crs = st_crs(bio10_scaled))
#create "region" object
region <- bio10_extent_sf

# Create prediction plots
predictions <- predict(modelRun_integrated, 
                       mesh = Mesh,
                       mask = Norway, 
                       spatial = TRUE,
                       fun = 'linear')

# Plot the prediction
plot(predictions)



