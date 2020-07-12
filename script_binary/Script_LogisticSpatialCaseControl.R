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
y <-  0 + (vendee.sf$NbVotes.Realises.Fillon.2017.Tour1 > vendee.sf$NbVotes.Realises.Macron.2017.Tour1)

library(raster)
source <- c( -1.561050, 46.453769)
coord.pred <- st_coordinates(st_centroid(vendee.sf)$geometry)
M <- length(coord.pred[,1])
dist <- c()
for(i in 1:M){
 dist[i] <-  pointDistance(source, coord.pred[i,], lonlat=TRUE) / 1000
} 

data <- list(N=N, Y=y, dis=dist)

myinits <- list(list(gam0 = 0, gam1 = 0, v = rep(0,N))) 

parameters <- c("res","p")

model.path <- paste0(getwd(),"/models/ModelLogisticSpatialCaseControl.bug")

samples <- bugs(data,parameters,inits=myinits , model.file =model.path, 
 n.chains=1,n.iter= 8000, n.burnin=500, n.thin=20, DIC=F, 
bugs.directory=bugsdir, codaPkg=F, debug=T)

hist(samples$sims.list$res[,1])
