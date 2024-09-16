# H-SAF H90 Visualization with R

This repository contains an R script to download and visualize H-SAF H90 precipitation data from the FTP server of the H-SAF project using shape files for custom regions. The script transforms the data to a standard projection and plots it as rasterized images.

## Installation

Ensure that the following R libraries are installed before running the script. You can install them using the following commands:

```r
# Install the necessary libraries if not already installed
install.packages("RCurl")
install.packages("stringr")
install.packages("lubridate")
install.packages("ncdf4")
install.packages("tmap")
install.packages("sf")
install.packages("raster")
