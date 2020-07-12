#Multiscale

library(spdep)   
library(bayestestR)
library(dplyr)
library(R2WinBUGS)
bugsdir <- "C:/Program Files/WinBUGS14"

source("init\\Vendee.Shape.R")
source("init\\Vendee.Covariates.2016.R")
source("init\\Vendee.Presidentielle.2017.Tour2.R")

library("rgdal")
library("maptools")

#remove island
vendee.sf <- vendee.sf[which(vendee.sf$insee != "85113"),]

vendee.sp <- as(vendee.sf, "Spatial")
vendee.coords <- coordinates(vendee.sp)
vendee.id <- cut(vendee.coords[,1], quantile(vendee.coords[,1]), include.lowest=TRUE)
vendee.union <- unionSpatialPolygons(vendee.sp, vendee.id)

plot(vendee.sp)
plot(vendee.union, add = TRUE, border = "red", lwd = 2)

indexCommune <- as.numeric(as.factor(vendee.id))
NbAggregates <- nlevels(vendee.id)
NbCommunes <- length(vendee.id)

vendee.sp.df <- as(vendee.sp, "data.frame")
selectColumns <- c("NbVotes.Realises.Macron.2017.Tour2","NbVotes.Attendus.Macron.2017.Tour2")
vendee.sp.df.agg <- aggregate(vendee.sp.df[, selectColumns], list(vendee.id), sum)

shape_nb.commune <- poly2nb(vendee.sp, queen = FALSE)
shape_nb.aggregate <- poly2nb(vendee.union, queen = FALSE)

NumCells.commune = length(shape_nb.commune)
NumCells.aggregate = length(shape_nb.aggregate)

num.commune =sapply(shape_nb.commune,length)
num.aggregate =sapply(shape_nb.aggregate,length)

adj.commune=unlist(shape_nb.commune)
adj.aggregate =unlist(shape_nb.aggregate)

sumNumNeigh.commune=length(unlist(shape_nb.commune))
sumNumNeigh.aggregate =length(unlist(shape_nb.aggregate))

data <- list(NbAggregates  = NbAggregates, 
sumNumNeigh.aggregate =sumNumNeigh.aggregate, num.aggregate =num.aggregate , adj.aggregate =adj.aggregate,
Y.aggregate = vendee.sp.df.agg[,"NbVotes.Realises.Macron.2017.Tour2"],
E.aggregate = vendee.sp.df.agg[,"NbVotes.Attendus.Macron.2017.Tour2"],
NbCommunes = NbCommunes,
sumNumNeigh.commune=sumNumNeigh.commune, num.commune=num.commune, adj.commune=adj.commune,
Y.commune = vendee.sf$NbVotes.Realises.Macron.2017.Tour2,
E.commune  = vendee.sf$NbVotes.Attendus.Macron.2017.Tour2,
indexCommune = indexCommune
) 

myinits <- list(list(alpha0.aggregate= 0, alpha0.commune = 0),
                list(alpha0.aggregate= 0.5, alpha0.commune = 0.5)) 

parameters <- c("mu.commune","PPL")

model.path <- paste0(getwd(),"/models/ModelMultiscale.bug")

samples <- bugs(data,parameters,inits=myinits , model.file = model.path, 
n.chains=2,n.iter=13000, n.burnin=3500, n.thin=10, DIC=T, 
bugs.directory=bugsdir, codaPkg=F, debug=T)

#data$Y.commune[253] <- floor(mean(samples$sims.list$mu[,253]))

source("utils\\computeGoodnessOfFit.R")
fit.mspe <- computeMspe(samples$sims.list$PPL)
fit.waic <- computeWaicPoisson(data$Y.commune, samples$sims.list$mu)

