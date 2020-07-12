#SpatioTemporel

library(spdep)   
library(Matrix)
library(dplyr)

library(bayestestR)
library(dplyr)
library(R2WinBUGS)
bugsdir <- "C:/Program Files/WinBUGS14"

source("init\\Vendee.Shape.R")
source("init\\Vendee.Covariates.2012.R")
source("init\\Vendee.Covariates.2016.R")
source("init\\Vendee.Presidentielle.2012.Tour2.R")
source("init\\Vendee.Presidentielle.2017.Tour2.R")

coord <- st_coordinates(st_centroid(vendee.sf)$geometry)
xy <- data.frame(X = coord[,"X"],Y = coord[,"Y"])

#performance issue
NbCommunes <- 50 #length(coord[,"X"])

Nannees = 2
votes.centregauche.2ans <-  c()
votes.centregauche.attendu.2ans <- c()
j <- 1
for(i in 1:NbCommunes){
 votes.centregauche.2ans[j] <- vendee.sf$NbVotes.Realises.Hollande.2012.Tour2[i]
 votes.centregauche.attendu.2ans[j] <- vendee.sf$NbVotes.Attendus.Hollande.2012.Tour2[i]
 j <- j + 1
}
for(i in 1:NbCommunes){
 votes.centregauche.2ans[j] <- vendee.sf$NbVotes.Realises.Macron.2017.Tour2[i]
 votes.centregauche.attendu.2ans[j] <- vendee.sf$NbVotes.Attendus.Macron.2017.Tour2[i]
 j <- j + 1
}

euc.dist <- function(x1, x2) sqrt(sum((x1 - x2) ^ 2))

d.points <-  matrix(, nrow=NbCommunes, ncol=NbCommunes)
rho <- 0
for(i in 1:NbCommunes){
 for(j in 1:NbCommunes){
    d.points[i,j] <- euc.dist(cbind(xy[i,"X"],xy[i,"Y"]), cbind(xy[j,"X"],xy[j,"Y"]))
    if(d.points[i,j] > rho){
       rho <- d.points[i,j]
    }
 }
}

covariance <- function(a){
 return (exp((-1)*abs(a)))
}

cov.points <-  matrix(, nrow=NbCommunes, ncol=NbCommunes)
for(i in 1:NbCommunes){
 for(j in 1:NbCommunes){
    cov.points[i,j] <- covariance(d.points[i,j] / rho)
 }
}

data <- list(N = NbCommunes , T = Nannees, Cov.N = cov.points,  
Y = matrix(votes.centregauche.2ans,NbCommunes,2), E = matrix(votes.centregauche.attendu.2ans,NbCommunes,2))

myinits <- list(list(tau.a = 0.5, tau.b = 0.5, tau.c = 0.5), 
                list(tau.a = 0.5, tau.b = 0.5, tau.c = 0.5)
) 

parameters <- c("mu","PPL")

model.path <- paste0(getwd(),"/models/ModelSpatioTemporel.bug")

samples <- bugs(data,parameters,inits=myinits , model.file = model.path, 
 n.chains=2,n.iter= 6500, n.burnin=650, n.thin=10, DIC=F, 
bugs.directory=bugsdir, codaPkg=F, debug=T)

source("utils\\computeGoodnessOfFit.R")
fit1.mspe <- computeMspe(samples$sims.list$PPL[,,1])
fit1.waic <- computeWaicPoisson(data$Y[,1], samples$sims.list$mu[,,1])

fit2.mspe <- computeMspe(samples$sims.list$PPL[,,2])
fit2.waic <- computeWaicPoisson(data$Y[,2], samples$sims.list$mu[,,2])