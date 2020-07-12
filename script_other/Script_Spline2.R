library(spdep)   
library(Matrix)
library(dplyr)

library(bayestestR)
library(dplyr)
library(R2WinBUGS)
bugsdir <- "C:/Program Files/WinBUGS14"

source("init\\Vendee.Shape.R")
source("init\\Vendee.Covariates.2016.R")
source("init\\Vendee.Presidentielle.2017.Tour2.R")

knot.nb <- 7
knot.quantile <- quantile(vendee.sf$CHOMAGE.PERCENTAGE.2016,  probs = c(0.1, 0.5, 1, 2, 5, 10, 50, NA)/100)
knot <- c()
for(i in 1:knot.nb){
 knot[i] <- knot.quantile[i][[1]]
}

data <- list(n = length(vendee.sf$NbVotes.Realises.Macron.2017.Tour2), nknots= knot.nb, degree = 2,
Y = samples.sf$NbVotes.Realises.Macron.2017.Tour2, 
E = samples.sf$NbVotes.Attendus.Macron.2017.Tour2, 
Covariate = vendee.sf$CHOMAGE.PERCENTAGE.2016,
knot = knot
)

myinits <- list(list(b = rep(0,data$nknots), beta = rep(0,data$degree+1)), 
                list(b = rep(0,data$nknots), beta = rep(0,data$degree+1))
) 

parameters <- c("m1","ystar")

model.path <- paste0(getwd(),"/models/ModelSpline2.bug")

samples <- bugs(data,parameters,inits=myinits , model.file = model.path, 
 n.chains=2,n.iter= 8000, n.burnin=500, n.thin=20, DIC=T, 
bugs.directory=bugsdir, codaPkg=F, debug=T)
