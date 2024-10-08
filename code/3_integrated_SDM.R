################################################################################

# 3. Integrated SDM

################################################################################

# Source packages
source(here::here("code", "0_setup.R"))

# Prepare data for PointedSDMs -------------------------------------------------

# Set options for the INLA package to use it "experimental" features
bru_options_set(inla.mode = "experimental")

# Load occurrences data
load(here("data", "derived_data", "cleaned_insectdata.rda"))
load(here("data", "derived_data", "presence_absence_dataset.Rda"))

# Define projection
projection <- "+proj=longlat +ellps=WGS84"

# Extract species occurrence records
presence_only <- cleaned_insectdata
presence_absence_dataset <- events_NTNU

# Read in climate data
bio10 <- terra::rast(here("data", "derived_data", "bio10_norway.tif"))
bio11 <- terra::rast(here("data", "derived_data", "bio11_norway.tif"))

# Normalize environmental varaibles  by scaling it
bio10_scaled <- scale(bio10)
bio11_scaled <- scale(bio11)
#corine2018_scaled <- scale(corine2018)
#river_distance_scaled <- scale(river_distance) # we're not using these right?

# Create mesh object ----------------------------------------------------------- 

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
                           cutoff = 20,
                           max.edge=c(60, 120) * 0.75,
                           min.angle = 20,
                           offset= c(40,80), 
                           crs = st_crs(CRS))



# Define datasets --------------------------------------------------------------

# Presence-only data - keep only X and Y coordinates (all data)
presence_only_full <- presence_only |>
  select(decimalLatitude, decimalLongitude) |>
  rename(Y = decimalLatitude,
         X = decimalLongitude)

# Presence-only excluding Vitenskapsmuseet
presence_only_no_vm <- presence_only |>
  filter(institutionCode != "NTNU-VM") |>
  select(decimalLatitude, decimalLongitude) |>
  rename(Y = decimalLatitude,
         X = decimalLongitude)

# Presence-absence data - keep only X, Y and presence/absence columns from NTNU-VM
presence_absence <- presence_absence_dataset |>
  select(decimalLatitude, decimalLongitude, presence) |>
  rename(Y = decimalLatitude,
         X = decimalLongitude,
         Present = presence)

# Create list with the two datasets
b_rhodani <- list(NTNU = presence_absence,
                Gbif = presence_only_no_vm)

# Run IntegradedSDM ------------------------------------------------------------

# Model covariates
covars <- c(bio10_scaled, bio11_scaled)

# Specify models -- here we run a model with one spatial covariate and a shared spatial field

# all data as presence-only
model_po_full <- intModel(presence_only_full, spatialCovariates = c(bio10_scaled, bio11_scaled), 
                  Coordinates = c('X', 'Y'),
                  Projection = projection, Mesh = Mesh, responsePA = 'Present')

# only presence-only not from VM
model_po_partial <- intModel(presence_only_no_vm, spatialCovariates = c(bio10_scaled, bio11_scaled),
                  Coordinates = c('X', 'Y'),
                  Projection = projection, Mesh = Mesh, responsePA = 'Present')

# only presence-absence from VM
model_pa_only <- intModel(presence_absence, spatialCovariates = c(bio10_scaled, bio11_scaled),
                             Coordinates = c('X', 'Y'),
                             Projection = projection, Mesh = Mesh, responsePA = 'Present')

# integrated model
model_integrated <- intModel(b_rhodani, spatialCovariates = c(bio10_scaled, bio11_scaled),
                             Coordinates = c('X', 'Y'),
                             Projection = projection, Mesh = Mesh, responsePA = 'Present')




# Run models and save predictions ----------------------------------------------
dir.create(here("data", "model_fits"), showWarnings = FALSE)

# full presence-only
modelRun_po_full <- fitISDM(model_po_full, 
                            options = list(control.inla = list(int.strategy = 'eb'), safe = TRUE))
pred_po_full <- predict(modelRun_po_full, mesh = Mesh, 
                        mask = Norway, spatial = TRUE,  fun = 'linear')
save(modelRun_po_full, pred_po_full, file = here("data","model_fits","po_full.rda"))

# partial presence-only
modelRun_po_partial <- fitISDM(model_po_partial, 
                               options = list(control.inla = list(int.strategy = 'eb'),  safe = TRUE))
pred_po_partial <- predict(modelRun_po_partial, mesh = Mesh,
                        mask = Norway, spatial = TRUE, fun = 'linear')
save(modelRun_po_partial, pred_po_partial, file = here("data", "model_fits", "po_partial.rda"))

# presence-absence only
modelRun_pa_only <- fitISDM(model_pa_only, 
                            options = list(control.inla = list(int.strategy = 'eb'), safe = TRUE))
pred_pa_only <- predict(modelRun_pa_only, mesh = Mesh,
                        mask = Norway, spatial = TRUE, fun = 'linear')
save(modelRun_pa_only, pred_pa_only, file = here("data","model_fits","pa_only.rda"))

# presence-absence only
modelRun_integrated <- fitISDM(model_integrated, 
                            options = list(control.inla = list(int.strategy = 'eb'), safe = TRUE))
pred_integrated <- predict(modelRun_integrated, mesh = Mesh,
                        mask = Norway, spatial = TRUE, fun = 'linear')
save(modelRun_integrated, pred_integrated, file = here("data","model_fits","integrated.rda"))