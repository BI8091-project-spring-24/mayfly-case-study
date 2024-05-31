################################################################################

# 0. Setup

################################################################################

# Install packages function
install.load.package <- function(x) {
  if (!require(x, character.only = TRUE)) {
    install.packages(x, repos = "http://cran.us.r-project.org")
  }
  require(x, character.only = TRUE)
}

# Vector specifying which packages to download/load
package_vec <- c("here","dplyr","knitr",
                 "ggplot2","rgbif",
                 "here", "CoordinateCleaner",
                 "terra", "sf","mapview",
                 "PointedSDMs","stringr",
                 "stars", "geodata")

## Executing install & load for each package
sapply(package_vec, install.load.package)


# INLA is not on CRAN, so has to be installed separately
#install.packages("INLA",repos=c(getOption("repos"),INLA="https://inla.r-inla-download.org/R/stable"), dep=TRUE) 
library("INLA")

# Conditional download function, which can be used to check if a file already exists
conditional_download <- function(url, target) {
  if (!file.exists(target)) {
    download.file(url=url, destfile=target)
  }
  else {
    print("File already downloaded!")
  }
}
