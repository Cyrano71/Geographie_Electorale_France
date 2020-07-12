#Shared Component

library(spdep)   
library(bayestestR)
library(dplyr)
library(R2WinBUGS)
bugsdir <- "C:/Program Files/WinBUGS14"

source("init\\Vendee.Shape.R")
source("init\\Vendee.Covariates.2016.R")
source("init\\Vendee.Presidentielle.2017.Tour2.R")

#remove island
vendee.sf <- vendee.sf[which(vendee.sf$insee != "85113"),]

#Sainte-Foy => data error, vote = 0
vendee.sf[vendee.sf$insee == 85214,]$NbVotes.Realises.Lepen.2017.Tour2 = NA
vendee.sf[vendee.sf$insee == 85214,]$NbVotes.Realises.Macron.2017.Tour2 = NA

nb_polygons <- length(st_geometry(vendee.sf))

shape_nb <- poly2nb(vendee.sf, queen = FALSE)
NumCells= length(shape_nb)
num=sapply(shape_nb,length)
adj=unlist(shape_nb)
sumNumNeigh=length(unlist(shape_nb))
N <- nb_polygons

data <- list(N = N,sumNumNeigh=sumNumNeigh, num=num, adj=adj,
Y1 = vendee.sf$NbVotes.Realises.Macron.2017.Tour2, E1 = vendee.sf$NbVotes.Attendus.Macron.2017.Tour2,
Y2 = vendee.sf$NbVotes.Realises.Lepen.2017.Tour2, E2 = vendee.sf$NbVotes.Attendus.Lepen.2017.Tour2)

myinits <- list(list(beta0 = 0,beta1 = 0), 
                list(beta0 = 0,beta1 = 0)) 

parameters <- c("mu1","PPL")

model.path <- paste0(getwd(),"/models/ModelSharedComponent.bug")

samples <- bugs(data,parameters,inits=myinits , model.file = model.path, 
 n.chains=2,n.iter= 8000, n.burnin=500, n.thin=20, DIC=T, 
bugs.directory=bugsdir, codaPkg=F, debug=T)

data$Y1[253] <- floor(mean(samples$sims.list$mu[,253]))

source("utils\\computeGoodnessOfFit.R")
fit.mspe <- computeMspe(samples$sims.list$PPL)
fit.waic <- computeWaicPoisson(data$Y1, samples$sims.list$mu)