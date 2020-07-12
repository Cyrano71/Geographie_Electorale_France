library(spdep)   
library(Matrix)

library(bayestestR)
library(dplyr)
library(R2WinBUGS)
bugsdir <- "C:/Program Files/WinBUGS14"

source("init\\Vendee.Shape.R")
source("init\\Vendee.Covariates.2016.R")
source("init\\Vendee.Presidentielle.2017.Tour2.R")

id  <- c(85194,85288,85243,85112,85250,85214,85103,85114,85278,85231,85010,85179,85152,85099,85298,85127,85022)
samples.sf <- vendee.sf[vendee.sf$insee %in% id,]

lebernard <- samples.sf[which(samples.sf$insee == "85022"),]
coord.pred <- st_coordinates(st_centroid(lebernard)$geometry)

samples.sf <- samples.sf[which(samples.sf$insee != "85022"),]
nb_polygons <- length(st_geometry(samples.sf))
coord <- st_coordinates(st_centroid(samples.sf)$geometry)

data <- list(NS = nb_polygons, xcoords=coord[,"X"], ycoords=coord[,"Y"],
y = samples.sf$CHOMAGE.PERCENTAGE.2016, xcoordpred = coord.pred[,"X"], ycoordpred = coord.pred[,"Y"])

myinits <- list(list(beta0 = 0)) 

parameters <- c("phi1", "beta0", "pred")

model.path <- paste0(getwd(),"/models/ModelKriging.bug")

samples <- bugs(data,parameters,inits=myinits , model.file = model.path, 
 n.chains=1,n.iter= 2500, n.burnin=300, n.thin=1, DIC=T, 
bugs.directory=bugsdir, codaPkg=F, debug=T)

meanpred <- samples$sims.list$beta0 + samples$sims.list$pred
errors <- lebernard$CHOMAGE.PERCENTAGE.2016 - meanpred
hist(errors)