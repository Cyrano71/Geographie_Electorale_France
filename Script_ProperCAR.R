#Proper CAR

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
cum <- cumsum(num)
cum <- append(cum, 0, after = 0)
pick <- array(numeric(),dim = c(sumNumNeigh,N))
for (i in 1:N){
  for(k in 1:sumNumNeigh){
     if(k > cum[i] && k <= cum[i+1]){
         pick[k,i] <- 1
     }
     else{
         pick[k,i] <- 0
      }
  }
}

weight <- c()
for (k in 1:sumNumNeigh){
  weight[k] <- num[] %*% pick[k,]
}

weight <- 1/weight

m <- c()
for (k in 1:N)
{
  m[k] <- 1 / num[k]
}

data <- list(N = N, num=num, adj=adj, C = weight, M = m,
Y = vendee.sf$NbVotes.Realises.Macron.2017.Tour2, 
E = vendee.sf$NbVotes.Attendus.Macron.2017.Tour2,
Covariate = (vendee.sf$CHOMAGE.PERCENTAGE.2016 - mean(vendee.sf$CHOMAGE.PERCENTAGE.2016)) / sd(vendee.sf$CHOMAGE.PERCENTAGE.2016))

myinits <- list(list(beta0 = 0, beta1 = 0)) 

parameters <- c("mu","PPL")

model.path <- paste0(getwd(),"/models/ModelProperCAR.bug")

samples <- bugs(data,parameters,inits=myinits , model.file = model.path, 
n.chains=1,n.iter= 8000, n.burnin=500, n.thin=10, DIC=T, 
bugs.directory=bugsdir, codaPkg=F, debug=T)

data$Y[253] <- floor(mean(samples$sims.list$mu[,253]))

source("utils\\computeGoodnessOfFit.R")
fit.mspe <- computeMspe(samples$sims.list$PPL)
fit.waic <- computeWaicPoisson(data$Y, samples$sims.list$mu)

