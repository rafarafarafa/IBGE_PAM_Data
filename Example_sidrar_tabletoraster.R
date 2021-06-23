
###############################################################
#
#   This is a very short code with a method to 
# to download soybean yield data from the SIDRA/IBGE database
# and convert it to an .nc file
###############################################################

library(sidrar)
library(terra)
library(tidyr)
library(dplyr)
library(sf)

period.list <- list(1981:1985,1986:1990,1991:1995,
                    1996:2000,2001:2005,2006:2010,
                    2011:2015,2016:2019)


mun.soy.yld <- lapply(period.list, function(x)
  get_sidra(1612, variable = 112, 
                              period = as.character(x), 
                              geo = "City",
                              classific = c("c81"),
                              category = list(2713)))

mun.soy.yld <- do.call(rbind,mun.soy.yld) %>% 
  rename(ADM2_PCODE = `Município (Código)`) %>%
  dplyr::select(Ano,ADM2_PCODE,Valor) 


BRmun <- st_read("GIS/bra_admbnda_adm2_ibge_2020.shp") %>% 
  mutate(ADM2_PCODE = substr(ADM2_PCODE,3,9))

shp.soy.yld <- left_join(BRmun,mun.soy.yld)

baserast <- rast(nrows=4860, ncol=5040,
                 extent= c(-74.25, -32.25, -34.25, 6.25),
                 crs="+proj=longlat +datum=WGS84",
                 vals=NA)

rasters <- rast(lapply(1981:2019, 
                  function(x)
  rasterize(vect(shp.soy.yld %>% 
                   filter(Ano==x)),baserast,"Valor")))
names(rasters) <- 1981:2019
varnames(rasters) <- paste0("soy_yield_",1981:2019)

writeRaster(rasters,"soy_yield_1981_2019.tif")
