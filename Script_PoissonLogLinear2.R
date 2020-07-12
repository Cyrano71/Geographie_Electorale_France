#PoissonLogLinear

library(bayestestR)
library(dplyr)
library(R2WinBUGS)
bugsdir <- "C:/Program Files/WinBUGS14"

source("init\\Vendee.Shape.R")
source("init\\Vendee.Covariates.2016.R")
source("init\\Vendee.Presidentielle.2017.Tour2.R")

#Sainte-Foy => data error, vote = 0
vendee.sf[vendee.sf$insee == 85214,]$NbVotes.Realises.Lepen.2017.Tour2 = NA
vendee.sf[vendee.sf$insee == 85214,]$NbVotes.Realises.Macron.2017.Tour2 = NA

nb <- length(vendee.sf$NbVotes.Realises.Macron.2017.Tour2)

data <- list(N = nb,
Y = vendee.sf$NbVotes.Realises.Macron.2017.Tour2,
E = vendee.sf$NbVotes.Attendus.Macron.2017.Tour2
) 

myinits <- list(list(beta0=0.5, alpha=0.7, theta=rep(0.5,nb)), 
                 list(beta0=0.7, alpha=0.7, theta=rep(0.5,nb))
) 

parameters <- c("mu","PPL")

model.path <- paste0(getwd(),"/models/ModelPoissonLogLinear2.bug")

samples <- bugs(data,parameters,inits=myinits , model.file = model.path, 
 n.chains=2,n.iter=8000, n.burnin=500, n.thin=2, DIC=T, 
bugs.directory=bugsdir, codaPkg=F, debug=T)

#we didn't remove the island
data$Y[254] <- floor(mean(samples$sims.list$mu[,254]))

source("utils\\computeGoodnessOfFit.R")
fit.mspe <- computeMspe(samples$sims.list$PPL)
fit.waic <- computeWaicPoisson(data$Y, samples$sims.list$mu)






