# H-SAF H90 Data Downloader and Visualizer

This repository contains an R script that downloads, processes, and visualizes H-SAF H90 accumulated precipitation rate data for a specified region and time period. It retrieves data from the H-SAF FTP server, processes the netCDF files, and generates maps and GeoTIFF files of precipitation over the specified area.

## Table of Contents

- [Introduction](#introduction)
- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
- [Usage](#usage)
  - [1. Set Up FTP Account](#1-set-up-ftp-account)
  - [2. Define Time Period](#2-define-time-period)
  - [3. Define Region](#3-define-region)
  - [4. Run the Script](#4-run-the-script)
- [Output](#output)
- [Understanding the Script](#understanding-the-script)
- [Notes](#notes)
- [License](#license)
- [Acknowledgments](#acknowledgments)
- [Contact](#contact)

## Introduction

The H-SAF (EUMETSAT Satellite Application Facility on Support to Operational Hydrology and Water Management) provides satellite-derived data products related to precipitation and soil moisture. The **H90 product** is the accumulated precipitation rate derived from Meteosat Second Generation (MSG) satellites.

This R script automates the process of downloading H90 data for a specified time period and region, processes the netCDF files, and visualizes it using maps. The outputs include PNG images of the precipitation maps and GeoTIFF files for further geospatial analysis.

## Features

- **Automated Data Download**: Fetches H90 netCDF files from the H-SAF FTP server for a specified time range.
- **Data Processing**: Extracts and processes precipitation data from netCDF files.
- **Visualization**: Creates precipitation maps over a user-defined region using the `tmap` package.
- **GeoTIFF Generation**: Outputs processed data as GeoTIFF files for GIS applications.
- **Customizable Parameters**: Easily adjust time periods, regions, and visualization settings.

## Requirements

- **R** version 3.6 or higher.
- **R Packages**:
  - RCurl
  - stringr
  - lubridate
  - ncdf4
  - tmap
  - sf
  - raster

## Installation

1. **Clone the Repository**

   ```bash
   git clone https://github.com/p3tsata/H-SAF_h90_with_R.git
   
2. **Install Required R Packages**
   Install the necessary R packages if they are not already installed:
   ```r
   install.packages(c("RCurl", "stringr", "lubridate", "ncdf4", "tmap", "sf", "raster"))

3. **Set Up the Working Directory**
   Ensure that your working directory is set to the location of the cloned repository or adjust the paths in the script     accordingly.
## Usage
1. **Set Up FTP Account**
  - To access the H-SAF FTP server, you need a valid username and password. If you do not have an account, please register at H-SAF User Registration - https://hsaf.meteoam.it/User/Register
  - Set FTP Credentials
In the script, replace the placeholders with your FTP username and password:
```r
ftp_user <- "your_username"
ftp_pass <- "your_password"
```

3. **Define Time Period**
Set the start and end dates for the data you wish to download. The dates should be in the format YYYYMMDDHH.
```r
from_date <- "2024040100"  # Start date (inclusive)
to_date   <- "2024040200"  # End date (inclusive)
```
Note: The H90 data is available for the last two months.

4. **Define Region**
Provide the path to a shapefile (.shp) that defines the region of interest. The script uses this shapefile to clip the data and generate maps for the specified area.
```r
shp_file_path <- "./shp_file/BgBorder_region.shp"
```
nsure that the shapefile and its associated files (.dbf, .shx, etc.) are in the specified directory.

5. **Run the Script**
Execute the R script in your R environment:
```r
source("H-SAF_h90_with_R.R")
```
Or run it line by line in an interactive R session.

## Output

The script will perform the following actions:

### Download Data

Downloads the H90 netCDF files for the specified time period from the H-SAF FTP server and saves them in the `./d_files/` directory.

### Process Data

Unzips and processes the netCDF files to extract the accumulated precipitation rate data.

### Generate Maps

Creates maps of the precipitation data overlaid on the specified region using the `tmap` package. The maps are saved as PNG images in the `./png/` directory.

### Generate GeoTIFFs

Saves the processed precipitation data as GeoTIFF files in the `./gtiff/` directory for further geospatial analysis.

### Output Directories

- **Downloaded Files**: `./d_files/` - Contains the downloaded and unzipped netCDF files.
- **PNG Images**: `./png/` - Contains the generated precipitation maps as PNG images.
- **GeoTIFF Files**: `./gtiff/` - Contains the precipitation data as GeoTIFF files.

## Notes

### Data Availability

The H90 data is typically available for the last two months. Ensure your specified time period falls within the available data range.

### Projections

The script handles coordinate transformations between the SEVIRI projection and WGS84 (EPSG:4326).

### Performance

Processing large time periods or high-resolution data may require significant computational resources.

### Error Handling

The script does basic checks for directory existence and file existence but may require additional error handling for robustness in different environments.

## License

This project is licensed under the GNU GENERAL PUBLIC LICENSE [LICENSE](LICENSE) file for details.

## Acknowledgments

- **H-SAF** - [EUMETSAT Satellite Application Facility on Support to Operational Hydrology and Water Management](https://hsaf.meteoam.it/)
- **EUMETSAT** - European Organisation for the Exploitation of Meteorological Satellites

**All intellectual property rights of the H SAF products belong to EUMETSAT. The use of these products is granted to every interested user, free of charge. If you wish to use these products, EUMETSAT's copyright credit must be shown by displaying the words "copyright (2024) EUMETSAT" on each of the products used.**
