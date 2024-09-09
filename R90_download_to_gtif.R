# Install the necessary libraries if not already installed
# install.packages("RCurl")
# install.packages("stringr")
# install.packages("lubridate")
# install.packages("ncdf4")
# install.packages("tmap")
# install.packages("sf")
# install.packages("raster")


# Load the necessary libraries
require("RCurl")
require("stringr")
require("lubridate")
require("tmap")
require("ncdf4")
require("sf")
require("raster")

#Set up your FTP account details. 
#If you do not have a login, please visit https://hsaf.meteoam.it/User/Register

ftp_user <- "--------"
ftp_pass <- "--------"
userpwd <- paste0(ftp_user, ":", ftp_pass)

# Define a time preriod YYYYMMDDHH in last 2 months
from_date = "2024040100"
to_date = "2024040200"

interval = "01"

#Define an SHP file with a region for which you want to visualise data.

shp_file_path = "./shp_file/BgBorder_region.shp"

shp_file <- read_sf(shp_file_path)

proj_seviri <- "+proj=geos +lon_0=0 +h=35785831 +a=6378169 +b=6356584 +units=m +no_defs"
shp_file = st_transform(shp_file, proj_seviri)
shp_file_long_lat = st_transform(shp_file, 4326)


date_seq <- seq(ymd_h(from_date), ymd_h(to_date), by = "hour")
date_str <- format(date_seq, "%Y%m%d_%H%M")
files_to_download <- paste0("h90_", date_str, "_", interval, "_fdk.nc.gz")

ftp_dir <- "ftphsaf.meteoam.it/products/h90/h90_cur_mon_data/" 

# in Long lats limits <- raster::extent(28.7, 29.9, 41.8, 43.5)
limits <- raster::extent(shp_file_long_lat)

pixcoord2geocoord <- function(rig, col) {
  # Use global variables. In R, global variables can be passed as function arguments
  # or you can use `<<-` to modify them within the function.
  
  SAT_HEIGHT <<- satheight  # distance from the center of the earth to the satellite
  R_EQ <<- radius_eq       # radius of the earth at the equator
  R_POL <<- radius_pole    # radius of the earth at the pole
  resolution <<- resolution
  
  CFAC <- -781648343  # ColumnScalingFactor
  LFAC <- -781648343  # LineScalingFactor
  COFF <- resolution / 2  # ColumnOffSet
  LOFF <- resolution / 2  # LineOffSet
  
  factor <- 2^(-16) * CFAC
  
  x <- as.numeric(rig - COFF) / factor
  y <- as.numeric(col - LOFF) / factor
  
  dim1 <- length(x)
  
  X <- as.vector(t(matrix(x, nrow=dim1)))
  Y <- as.vector(t(matrix(y, nrow=dim1)))
  
  CX <- cos(X)
  CY <- cos(Y)
  SX <- sin(X)
  SY <- sin(Y)
  
  AUX <- CY * CY + 1.006803 * SY * SY
  
  SA <- (SAT_HEIGHT * CX * CY)^2 - 1737121856.0 * AUX
  
  SD <- sqrt(SA)
  
  SN <- SAT_HEIGHT * CX * CY - SD / AUX
  
  S1 <- SAT_HEIGHT - SN * CX * CY
  S2 <- SN * SX * CY
  S3 <- -SN * SY
  SXY <- sqrt(S1 * S1 + S2 * S2)
  
  LONG <- atan(S2 / S1) * 180 / pi + satlon
  LATG <- atan(1.006803 * S3 / SXY) * 180 / pi
  
  LONG[SA < 0] <- NA
  LATG[SA < 0] <- NA
  
  lon <- matrix(LONG, nrow = dim1)
  lat <- matrix(LATG, nrow = dim1)
  
  return(list(lon = lon, lat = lat))
}

file = files_to_download[2]

for (file in files_to_download) {
  ftp_url = paste0("ftp://", ftp_user, ":", ftp_pass, "@", ftp_dir,  file)

    directory_path <- "./d_files/"
    destfile = paste0(directory_path, file)
    
    if (!dir.exists(directory_path)) {
      dir.create(directory_path, recursive = TRUE)
      cat("Directory created:", directory_path, "\n")
    } else {
      cat("Directory already exists:", directory_path, "\n")
    }
  
    if (file.exists(destfile)) {
      cat("File exists:", destfile, "\n")
    } else {
      cat("Dowloading file:", destfile, "\n")
      download.file(ftp_url, destfile, method = "wget")
    }
  
  system(paste0("gunzip -k -f ", destfile))
  
  {
  ncname <- substr(destfile, 1, nchar(destfile) - 3)
  ncin <- nc_open(ncname)
  radius_eq <- ncatt_get(ncin, 0, 'r_eq')$value
  radius_pole <- ncatt_get(ncin, 0, 'r_pol')$value
  satlat <- 0.0
  satlon <- as.numeric(gsub('f', '', ncatt_get(ncin, 0, 'sub-satellite_longitude')$value))
  satheight <- as.numeric(ncatt_get(ncin, 0, 'satellite_altitude')$value) / 1000 + as.numeric(radius_eq)
  names(ncin$var)
  rr <- ncvar_get(ncin, 'acc_rr')
  resolution <- dim(rr)[1]
  nc_close(ncin)
  unlink(ncname)
  }
  
  grid_data <- expand.grid(rows = 1:resolution, cols = 1:resolution)
  
  coords <- pixcoord2geocoord(grid_data$rows, grid_data$cols)
  lonG <- matrix(coords$lon, nrow = resolution, ncol = resolution)
  latG <- matrix(coords$lat, nrow = resolution, ncol = resolution)
  rr[rr == "NaN"] = NA
  
  combine.df = data.frame("long" = as.vector(lonG), "latg" = as.vector(latG), "values" = as.vector(rr))
  combine.df = na.omit(combine.df)
  
  filtered_df <- subset(combine.df, long > limits@xmin & long < limits@xmax & latg > limits@ymin & latg < limits@ymax)
  
  sf_coords <- st_as_sf(filtered_df, coords = c("long", "latg"), crs = 4326)
  
  combine.df = filtered_df
  coordinates(combine.df) = ~long+latg
  crs(combine.df) = crs(4326)
  
  sf_coords_seviri <- st_transform(sf_coords, crs = proj_seviri)

  r_extent <- extent(st_bbox(sf_coords_seviri))  
  
  r <- raster(r_extent, res = resolution)
  rasterized_sf <- rasterize(sf_coords_seviri, r, "values", fun = mean, background = NA)
  gc()
  
  legend.L = "Precip"
  
  jet.colors <- colorRampPalette(c("white", "#007FFF", "blue", "#00007F", "yellow", "#FF7F00", "red", "#7F0000"))
  
  colormap <- c(jet.colors(80))
  tmap_mode("plot")
    legend.L = "precip rate"
  map_shp = tm_shape(shp_file) + tm_polygons(col = "gray30", lwd=0.4, alpha = 0, border.col = rgb(0, 0, 0, alpha = 1)) 
  
  reaster_bg <- tm_shape(rasterized_sf) +
    tm_raster(style = "fixed", title= paste0(legend.L, " [mm/h]") ,
              breaks = c(0, 0.1, 0.5, 1, 2, 5, 10, 20, 30, 50 ,70),
              palette = colormap,
              alpha = 0.95)+
    tm_legend(outside = TRUE) + tm_layout(legend.text.size = 0.8, legend.title.size = 1.2, legend.show = TRUE)
  
  label <- paste0(gsub("_", " ", file, ""), "; GEO proj: SEVIRI")
  
  result =  map_shp + reaster_bg + tm_credits(label, position = c("left", "BOTTOM"), size = 0.6)
  result 
  
  directory_path_png = "./png/"
  if (!dir.exists(directory_path_png)) {
    dir.create(directory_path_png, recursive = TRUE)
    cat("Directory created:", directory_path_png, "\n")
  } else {
    cat("Directory already exists:", directory_path_png, "\n")
  }
  
  directory_path_gtiff = "./gtiff/"
  if (!dir.exists(directory_path_gtiff)) {
    dir.create(directory_path_gtiff, recursive = TRUE)
    cat("Directory created:", directory_path_gtiff, "\n")
  } else {
    cat("Directory already exists:", directory_path_gtiff, "\n")
  }
  
  tmap_save(result, paste0(directory_path_png, file, ".png"), width=1550, height=1200)   
  writeRaster(rasterized_sf, filename=paste0(directory_path_gtiff, file, ".tif"), format="GTiff", overwrite=TRUE)
  }
