#LatentMixture

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

model.id <- 1

data <- list(N = N,sumNumNeigh=sumNumNeigh, num=num, adj=adj,
               Y = vendee.sf$NbVotes.Realises.Lepen.2017.Tour2, E = vendee.sf$NbVotes.Attendus.Lepen.2017.Tour2)

myinits <- list(list(alphaphi  = 2, alphapsi =  2, alphapsi0 = 0,alphaphi0 =0,  beta0 = 0,z = round(runif(N)))) 

parameters <- c("mu","PPL","z")

model.name <- paste0("/models/ModelLatentMixture",model.id,".bug") 
model.path <- paste0(getwd(),model.name)

samples <- bugs(data,parameters,inits=myinits , model.file =model.path, 
 n.chains=1,n.iter= 8000, n.burnin=500, n.thin=20, DIC=F, 
bugs.directory=bugsdir, codaPkg=F, debug=T)

data$Y[253] <- floor(mean(samples$sims.list$mu[,253]))

source("utils\\computeGoodnessOfFit.R")
fit.mspe <- computeMspe(samples$sims.list$PPL)
fit.waic <- computeWaicPoisson(data$Y, samples$sims.list$mu)

vendee.sf$z <- colMeans(samples$sims.list$z)
vendee.sf$PPL <- sqrt(colMeans(samples$sims.list$PPL))

library(tmap)
jpeg("ppl\\LatentMixturePPL.jpg", width = 850, height = 850)
tmap_mode('plot') + tm_shape(vendee.sf) + 
tm_polygons('PPL', title = "PPL", palette ="Oranges") 
dev.off()

tmap_mode('view') + tm_shape(vendee.sf) + 
tm_polygons('PPL', title = "PPL", palette ="Oranges") +
tm_text("nom", size = 0.5)

tmap_mode('view') + tm_shape(vendee.sf) + 
tm_polygons('NbVotes.Realises.Lepen.2017.Tour2', title = "NbVotes.Realises.Lepen.2017.Tour2", palette ="Oranges") +
tm_text("nom", size = 0.5)