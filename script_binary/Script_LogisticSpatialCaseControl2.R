library(spdep)   
library(bayestestR)
library(dplyr)
library(R2WinBUGS)
bugsdir <- "C:/Program Files/WinBUGS14"

source("init\\Vendee.Shape.R")
source("init\\Vendee.Covariates.2016.R")
source("init\\Vendee.Presidentielle.2017.Tour2.R")

id  <- c(85194,85288,85243,85112,85250,85214,85103,85114,85278,85231,85010,85179,85152,85099,85298,85127,85022)
samples.sf <- vendee.sf[vendee.sf$insee %in% id,]

nb_polygons <- length(st_geometry(samples.sf))
coord <- st_coordinates(st_centroid(samples.sf)$geometry)

N <- nb_polygons
y <- 0 + (vendee.sf$NbVotes.Realises.Fillon.2017.Tour1 > vendee.sf$NbVotes.Realises.Macron.2017.Tour1)

library(raster)
source <- c( -1.561050, 46.453769)
coord.pred <- st_coordinates(st_centroid(samples.sf)$geometry)
M <- length(coord.pred[,1])
dist <- c()
for(i in 1:M){
 dist[i] <-  pointDistance(source, coord.pred[i,], lonlat=TRUE) / 1000
} 

data <- list(N=N, Y=y, dis=dist, xcoords=coord[,"X"], ycoords=coord[,"Y"])

myinits <- list(list(gam0 = 0, gam1 = 0, v = rep(0,N))) 

parameters <- c("res","p")

model.path <- paste0(getwd(),"/models/ModelLogisticSpatialCaseControl2.bug")

samples <- bugs(data,parameters,inits=myinits , model.file =model.path, 
 n.chains=1,n.iter= 8000, n.burnin=500, n.thin=20, DIC=F, 
bugs.directory=bugsdir, codaPkg=F, debug=T)

hist(samples$sims.list$res[,1])
