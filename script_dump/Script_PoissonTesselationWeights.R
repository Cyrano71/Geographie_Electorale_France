library(spdep)   
library(bayestestR)
library(dplyr)
library(R2WinBUGS)
bugsdir <- "C:/Program Files/WinBUGS14"

source("init\\Vendee.Shape.R")
source("init\\Vendee.Covariates.2016.R")
source("init\\Vendee.Presidentielle.2017.Tour2.R")

nb_polygons <- length(st_geometry(vendee.sf))
N <- nb_polygons

library(raster)
source <- c( -1.561050, 46.453769)
coord.pred <- st_coordinates(st_centroid(vendee.sf)$geometry)
multipolygon <- st_geometry(vendee.sf)
M <- length(coord.pred[,1])

dist <- c()
area_sqkm <- c()
for(i in 1:M){
 dist[i] <-  pointDistance(source, coord.pred[i,], lonlat=TRUE) / 1000
 area_sqkm[i] <- st_area(multipolygon[i,]) / 1000000
} 

data <- list(N = N, Y=vendee.sf$NbVotes.Realises.Macron.2017.Tour2 , E=vendee.sf$NbVotes.Attendus.Macron.2017.Tour2, dis=dist, w=area_sqkm)

myinits <- list(list(gam0 = 0, gam1 = 0)) 

parameters <- c("res","L")

model.path <- paste0(getwd(),"/models/ModelPoissonTesselationWeights.bug")

samples <- bugs(data,parameters,inits=myinits , model.file =model.path, 
 n.chains=1,n.iter= 8000, n.burnin=500, n.thin=20, DIC=F, 
bugs.directory=bugsdir, codaPkg=F, debug=T)

hist(samples$sims.list$res[,1])
