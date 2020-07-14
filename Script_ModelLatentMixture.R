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
#vendee.sf[vendee.sf$insee == 85214,]$NbVotes.Realises.Lepen.2017.Tour2 = NA
#vendee.sf[vendee.sf$insee == 85214,]$NbVotes.Realises.Macron.2017.Tour2 = NA

nb_polygons <- length(st_geometry(vendee.sf))

shape_nb <- poly2nb(vendee.sf, queen = FALSE)
NumCells= length(shape_nb)
num=sapply(shape_nb,length)
adj=unlist(shape_nb)
sumNumNeigh=length(unlist(shape_nb))

N <- nb_polygons

model.id <- 1

j <- 1
vote.realises.2017 <- c()
vote.attendus.2017 <- c()
for(i in 1:N){
 vote.realises.2017[j] <- vendee.sf$NbVotes.Realises.Lepen.2017.Tour2[i]
 vote.attendus.2017[j] <- vendee.sf$NbVotes.Attendus.Lepen.2017.Tour2[i]
 j <- j + 1
}
for(i in 1:N){
 vote.realises.2017[j] <- vendee.sf$NbVotes.Realises.Macron.2017.Tour2[i]
 vote.attendus.2017[j] <- vendee.sf$NbVotes.Attendus.Macron.2017.Tour2[i]
 j <- j + 1
}

data <- list(N = N,sumNumNeigh=sumNumNeigh, num=num, adj=adj,
               Y = matrix(vote.realises.2017,N,2), E = matrix(vote.attendus.2017,N,2))

myinits <- list(list(z = c(0,1),
theta.psi = matrix(rep(1,2*N),N,2),
theta.phi= matrix(rep(1,2*N),N,2),
alpha.psi0 = c(0,0),alpha.phi0= c(0,0)
 )) 

parameters <- c("mu","PPL","z")

model.name <- paste0("/models/ModelLatentMixture",model.id,".bug") 
model.path <- paste0(getwd(),model.name)

samples <- bugs(data,parameters,inits=myinits , model.file =model.path, 
 n.chains=1,n.iter= 8000, n.burnin=500, n.thin=20, DIC=F, 
bugs.directory=bugsdir, codaPkg=F, debug=T)

#data$Y[253] <- floor(mean(samples$sims.list$mu[,253]))

source("utils\\computeGoodnessOfFit.R")
fit.mspe1 <- computeMspe(samples$sims.list$PPL[,,1])
fit.waic1 <- computeWaicPoisson(data$Y[,1], samples$sims.list$mu[,,1])

vendee.sf$PPL.Lepen <- sqrt(colMeans(samples$sims.list$PPL[,,1]))

library(tmap)

jpeg("ppl\\LatentMixturePPL.jpg", width = 850, height = 850)

tmap_mode('plot') + tm_shape(vendee.sf) + 
tm_polygons('PPL.Lepen', title = "PPL", palette ="Oranges", breaks = c(0, 20, 40, 60, 80, 100, 130, 200, 300, 400)) 

dev.off()

tmap_mode('view') + tm_shape(vendee.sf) + 
tm_polygons('PPL', title = "PPL", palette ="Oranges") +
tm_text("nom", size = 0.5)

tmap_mode('view') + tm_shape(vendee.sf) + 
tm_polygons('NbVotes.Realises.Lepen.2017.Tour2', title = "NbVotes.Realises.Lepen.2017.Tour2", palette ="Oranges") +
tm_text("nom", size = 0.5)