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

#performance issue
id  <- c(85194,85288,85243,85112,85250,85214,85103,85114,85278,85231,85010,85179,85152,85099,85298,85127,85022)
vendee.sf <- vendee.sf[vendee.sf$insee %in% id,]
NbCommunes <- length(st_geometry(vendee.sf))

shape_nb <- poly2nb(vendee.sf, queen = FALSE)
NumCells= length(shape_nb)
num=sapply(shape_nb,length)
adj=unlist(shape_nb)
sumNumNeigh=length(unlist(shape_nb))

Nannees = 2
votes.total.2ans <- c()
votes.centregauche.2ans <-  c()
j <- 1
for(i in 1:NbCommunes){
 votes.centregauche.2ans [j] <- vendee.sf$NbVotes.Realises.Hollande.2012.Tour2[i]
 votes.total.2ans[j] <- vendee.sf$Total.votants.2012.Tour2[i]
 j <- j + 1
}
for(i in 1:NbCommunes){
 votes.centregauche.2ans [j] <- vendee.sf$NbVotes.Realises.Macron.2017.Tour2[i]
 votes.total.2ans[j] <- vendee.sf$Total.votants.2017.Tour2[i]
 j <- j + 1
}

data <- list(N = NbCommunes , T = Nannees, 
sumNumNeigh=sumNumNeigh, num=num, adj=adj, 
Y = matrix(votes.centregauche.2ans ,NbCommunes,2), Size = matrix(votes.total.2ans,NbCommunes,2))

myinits <- list(list(tau.v = 0.5, tau.u = 0.5, tau.g = 0.5, tau.psi = 0.5,alpha0 = 0), 
                list(tau.v = 0.5, tau.u = 0.5, tau.g = 0.5, tau.psi = 0.5,alpha0 = 0)
) 

parameters <- c("p","PPL")

model.path <- paste0(getwd(),"/models/ModelSpatioTemporel.bug")

samples <- bugs(data,parameters,inits=myinits , model.file = model.path, 
 n.chains=2,n.iter= 6500, n.burnin=650, n.thin=10, DIC=T, 
bugs.directory=bugsdir, codaPkg=F, debug=T)

source("utils\\computeGoodnessOfFit.R")
fit1.mspe <- computeMspe(samples$sims.list$PPL[,,1])
fit1.waic <- computeWaicBinomial(data$Y[,1], samples$sims.list$p[,,1], data$Size[,1])

fit2.mspe <- computeMspe(samples$sims.list$PPL[,,2])
fit2.waic <- computeWaicBinomial(data$Y[,2], samples$sims.list$p[,,2], data$Size[,2])