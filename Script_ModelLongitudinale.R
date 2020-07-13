#Longitudinale

library(spdep)   
library(bayestestR)
library(dplyr)
library(R2WinBUGS)
bugsdir <- "C:/Program Files/WinBUGS14"

source("init\\Vendee.Shape.R")
source("init\\Vendee.Covariates.2012.R")
source("init\\Vendee.Covariates.2016.R")
source("init\\Vendee.Presidentielle.2012.Tour2.R")
source("init\\Vendee.Presidentielle.2017.Tour2.R")

library("rgdal")
library("maptools")

#remove island
vendee.sf <- vendee.sf[which(vendee.sf$insee != "85113"),]

#Sainte-Foy => data error, vote = 0
vendee.sf[vendee.sf$insee == 85214,]$NbVotes.Realises.Lepen.2017.Tour2 = NA
vendee.sf[vendee.sf$insee == 85214,]$NbVotes.Realises.Macron.2017.Tour2 = NA

vendee.sp <- as(vendee.sf, "Spatial")
vendee.coords <- coordinates(vendee.sp)
vendee.id <- cut(vendee.coords[,1], quantile(vendee.coords[,1]), include.lowest=TRUE)
vendee.union <- unionSpatialPolygons(vendee.sp, vendee.id)

plot(vendee.sp)
plot(vendee.union, add = TRUE, border = "red", lwd = 2)

indexCommune <- as.numeric(as.factor(vendee.id))
NbAggregates <- nlevels(vendee.id)
NbCommunes <- length(vendee.id)

shape_nb.aggregate <- poly2nb(vendee.union, queen = FALSE)
NumCells.aggregate = length(shape_nb.aggregate)
num.aggregate =sapply(shape_nb.aggregate,length)
adj.aggregate =unlist(shape_nb.aggregate)
sumNumNeigh.aggregate =length(unlist(shape_nb.aggregate))

vote.centregauche.realises.2ans <-  c()
vote.centregauche.attendus.2ans <- c()
j <- 1
for(i in 1:NbCommunes){
 vote.centregauche.realises.2ans[j] <- vendee.sf$NbVotes.Realises.Hollande.2012.Tour2[i]
 vote.centregauche.attendus.2ans[j] <- vendee.sf$NbVotes.Attendus.Hollande.2012.Tour2[i]
 j <- j + 1
}
for(i in 1:NbCommunes){
 vote.centregauche.realises.2ans[j] <- vendee.sf$NbVotes.Realises.Macron.2017.Tour2[i]
 vote.centregauche.attendus.2ans[j] <- vendee.sf$NbVotes.Attendus.Macron.2017.Tour2[i]
 j <- j + 1
}

model.id <- 1

if(model.id == 1){
     data <- list(T = 2,
                  NbAggregates  = NbAggregates, sumNumNeigh.aggregate =sumNumNeigh.aggregate , num.aggregate =num.aggregate , adj.aggregate =adj.aggregate,
                  Y = matrix(vote.centregauche.realises.2ans,NbCommunes,2), E = matrix(vote.centregauche.attendus.2ans,NbCommunes,2),
                  N = NbCommunes,indexCommune = indexCommune
                  ) 
} else {
     data <- list(N = NbCommunes,T = 2,
                  Y = matrix(vote.centregauche.realises.2ans,NbCommunes,2), E = matrix(vote.centregauche.attendus.2ans,NbCommunes,2)                 
                  ) 
}

myinits <- list(list(beta0 = 0), 
                 list(beta0 = 0)) 

parameters <- c("mu","PPL")

model.name <- paste0("/models/ModelLongitudinale",model.id,".bug") 
model.path <- paste0(getwd(),model.name)

samples <- bugs(data,parameters,inits=myinits , model.file = model.path, 
                      n.chains=2,n.iter=10000, n.burnin=2500, n.thin=2, DIC=T, 
                      bugs.directory=bugsdir, codaPkg=F, debug=T)

source("utils\\computeGoodnessOfFit.R")
fit1.mspe <- computeMspe(samples$sims.list$PPL[,,1])
fit1.waic <- computeWaicPoisson(data$Y[,1], samples$sims.list$mu[,,1])

data$Y[253,2] <- floor(mean(samples$sims.list$mu[,253,2]))
fit2.mspe <- computeMspe(samples$sims.list$PPL[,,2])
fit2.waic <- computeWaicPoisson(data$Y[,2], samples$sims.list$mu[,,2])
