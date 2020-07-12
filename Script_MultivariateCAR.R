#MultivariateCAR

library(spdep)   
library(bayestestR)
library(dplyr)
library(R2WinBUGS)
bugsdir <- "C:/Program Files/WinBUGS14"

source("init\\Vendee.Shape.R")
source("init\\Vendee.Covariates.2016.R")
source("init\\Vendee.Presidentielle.2017.Tour1.R")

#remove island
vendee.sf <- vendee.sf[which(vendee.sf$insee != "85113"),]

nb_polygons <- length(st_geometry(vendee.sf))

shape_nb <- poly2nb(vendee.sf, queen = FALSE)
NumCells= length(shape_nb)
num=sapply(shape_nb,length)
adj=unlist(shape_nb)
sumNumNeigh=length(unlist(shape_nb))

N <- nb_polygons

vectorVoix <- c()
vectorVoixAttendu <- c()
j <- 1
for(i in 1:N){
 vectorVoix[j] <- vendee.sf$NbVotes.Realises.Macron.2017.Tour1[i]
 vectorVoixAttendu[j] <- vendee.sf$NbVotes.Attendus.Macron.2017.Tour1[i]
 j <- j + 1
}
for(i in 1:N){
 vectorVoix[j] <- vendee.sf$NbVotes.Realises.Lepen.2017.Tour1[i]
 vectorVoixAttendu[j] <- vendee.sf$NbVotes.Attendus.Lepen.2017.Tour1[i]
 j <- j + 1
} 
for(i in 1:N){
 vectorVoix[j] <- vendee.sf$NbVotes.Realises.Fillon.2017.Tour1[i]
 vectorVoixAttendu[j] <- vendee.sf$NbVotes.Attendus.Fillon.2017.Tour1[i]
 j <- j + 1
}

nbDeVoix <- matrix(vectorVoix,N,3)
nbDeVoixAttendu <- matrix(vectorVoixAttendu,N,3)

#diag(3)
I <- matrix(c(0.1,0.005,0.005,0.005,0.1,0.005,0.005,0.005,0.1),3,3)

data <- list(NbCommunes = N ,NbCandidates=3,
sumNumNeigh=sumNumNeigh, num=num, adj=adj,
Y = nbDeVoix, E = nbDeVoixAttendu,
I = I)

myinits <- list(list(beta=rep(0,3)))

parameters <- c("mu","PPL")

model.path <- paste0(getwd(),"/models/ModelMultivariateCAR.bug")

samples <- bugs(data,parameters,inits=myinits , model.file = model.path, 
 n.chains=1,n.iter= 6000, n.burnin=500, n.thin=20, DIC=T, 
bugs.directory=bugsdir, codaPkg=F, debug=T)

source("utils\\computeGoodnessOfFit.R")
fit1.mspe <- computeMspe(samples$sims.list$PPL[,,1])
fit1.waic <- computeWaicPoisson(data$Y[,1], samples$sims.list$mu[,,1])

fit2.mspe <- computeMspe(samples$sims.list$PPL[,,2])
fit2.waic <- computeWaicPoisson(data$Y[,2], samples$sims.list$mu[,,2])

fit3.mspe <- computeMspe(samples$sims.list$PPL[,,3])
fit3.waic <- computeWaicPoisson(data$Y[,3], samples$sims.list$mu[,,3])