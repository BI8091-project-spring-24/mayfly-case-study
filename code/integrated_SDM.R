################################################################################

# Running PointedSDMs

################################################################################

# 0. PACKAGES ----
library(here)
library(dplyr)
library(terra)
library(sf)
library(giscoR)
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

### 2.1.1. Presence-only data ----

# All data coming from datasets that do not have samplingProtocol = "Rot (1 min)"

presence_only <- insect_data |>
  filter(samplingProtocol != "Rot (1 min)") |>
  select(decimalLongitude, decimalLatitude) |>
  rename(X = decimalLongitude, Y = decimalLatitude)

### 2.1.2. Presence-absence data ----

# All data coming from datasets where samplingProtocol = "Rot (1 min)"

# Extract records with samplingProtocol = "Rot (1 min)"
rot_samples <- insect_data |>
  filter(samplingProtocol == "Rot (1 min)")

levels(as.factor(rot_samples$occurrenceStatus)) # no luck, they are all present => have to create our own presence absence df

# Group occurrences by dataset name
rot_datasets <- rot_samples |>
  group_by(datasetName) |>
  summarize(species_list = list(unique(species)), .groups = 'drop') |>
  left_join(rot_samples %>% select(decimalLongitude, decimalLatitude, datasetName) 
            %>% distinct(), by = "datasetName")

## 2.1. Run Integraded SDM ----

# Specify model -- here we run a model with one spatial covariate and a shared spatial field
model <- intModel(insect_data, spatialCovariates = bio1_scaled, 
                  Coordinates = c('decimalLongitude', 'decimalLatitude'),
                  Projection = projection, Mesh = Mesh, responsePA = 'Present')


# Run integrated model
modelRun <- fitISDM(model, options = list(control.inla = list(int.strategy = 'eb'), 
                                          safe = TRUE))
# Extract summary of the model
summary(modelRun)

# Create a "region" from the shape of bio1_scaled
#get extent of raster
bio1_extent <- terra::ext(bio1_scaled)
#create an sf polygon from the extent
bio1_extent_sf <- st_as_sfc(st_bbox(c(xmin = bio1_extent[1], xmax = bio1_extent[2], 
                                      ymin = bio1_extent[3], ymax = bio1_extent[4])), 
                            crs = st_crs(bio1_scaled))
#create "region" object
region <- bio1_extent_sf

# Create prediction plots
predictions <- predict(modelRun, mesh = mesh,
                       mask = region, 
                       spatial = TRUE,
                       fun = 'linear')

# Plot the prediction
plot(predictions)