# The distribution of a mayfly species in Norway

## Description

The present repository contains the data, scripts and description of the steps taken to analyse the distribution of *Baetis rhodani* in Norway. This project is carried out as part of the BI8091 Advanced Biology course.

### Aims & Study Questions

The present study aims to answer the following study questions:

1.  Can unstructured GBIF occurrence records of *B. rhodani* be used in combination with data originating from structured sampling programs to map the distribution of *B. rhodani* across Norway?
2.  Do Species Distribution Models (SDMs) using both types of data perform better to map the distribution of the species than single-data source SDMs?
3.  What is the distribution of *B. rhodani* across Norway, when mean temperature of the warmest quarter and land cover are considered?

![](http://www.rakkenes.com/wp-content/uploads/2017/06/0F5R8264-Edit-Edit-1030x579.jpg)

Image credits: rakkenes.com

## Data and Methodology

The data used in this project are:

1.  GBIF-downloaded occurrences of *B. rhodani*
    1.  Structured dataset: the Freshwater benthic invertebrates ecological collection NTNU University Museum was used to create a presence-absence dataset
    2.  Unstructured dataset: all occurrences of *B. rhodani* in Norwayfrom 1950 to the present day
2.  Bioclimatic variables were downloaded from <https://worldclim.org/>
3.  CORINE Land Cover Status rasters were downloaded from <https://land.copernicus.eu/en/products/corine-land-cover>

To map the distribution of *B. rhodani* was mapped using the R package "PointedSDMs" ([https://github.com/PhilipMostert/PointedSDMs](#0))

# Script

The analysis done as part of this project is done within the following scripts:

-   0_setup = Setup required for running the analysis

-   1_1_GBIF_download = Download GBIF records for the unstructured dataset

-   1_2_GBIF_import = Import GBIF records downloaded before

-   1_3_GBIF_data_cleaning = Data cleaning steps for the *B.rhodani* unstructured dataset

-   1_4_GBIF_data_exploration = Exploration of the records contained in the *B.rhodani* unstructured dataset

-   1_5_GBIF_presence_absence_dataset = Download of the Freshwater benthic invertebrates ecological collection NTNU University Museum (structured dataset) and creation of the presence-absence matrix required for the PointedSDM

-   2_CORINE_land_cover = Download of CORINE 2018 Land Cover Status, cropping and masking to Norway and modification of classes included to better suit our analysis

-   3_NVE_distance_to_river = Download of the network of main rivers in Norway and calculation of the distance to river for each CORINE cell

-   4_WORLDCLIM_environmental_variables_prep = Download, cropping and masking of Worldclim bioclimatic variables to Norway

-   5_integrated_SDM = Running of the integrated SDM
