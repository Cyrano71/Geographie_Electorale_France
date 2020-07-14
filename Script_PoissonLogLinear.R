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

nb <- length(vendee.sf$NbVotes.Attendus.Macron.2017.Tour2)
maximum <- max(vendee.sf$NbVotes.Attendus.Macron.2017.Tour2)

model.id <- 2

if(model.id == 1){
   data <- list(N = nb,
                Y = vendee.sf$NbVotes.Realises.Macron.2017.Tour2,
                E = vendee.sf$NbVotes.Attendus.Macron.2017.Tour2,
                Covariate1 = (vendee.sf$IMMI.TOTAL.2016 - mean(vendee.sf$IMMI.TOTAL.2016)) / sd(vendee.sf$IMMI.TOTAL.2016),
                Covariate2 = (vendee.sf$CHOMAGE.TOTAL.2016 - mean(vendee.sf$CHOMAGE.TOTAL.2016)) / sd(vendee.sf$CHOMAGE.TOTAL.2016)
                ) 

    myinits <- list(list(beta0 = 0, beta1 = 0, beta2 = 0), 
                 list(beta0 = 1, beta1 = 1, beta2 = 1)) 
} else {
   data <- list(N = nb,
                Y = vendee.sf$NbVotes.Realises.Macron.2017.Tour2,
                E = vendee.sf$NbVotes.Attendus.Macron.2017.Tour2
                ) 

    myinits <- list(list(beta0=0.5, alpha=0.7, theta=rep(0.5,nb)), 
                 list(beta0=0.7, alpha=0.7, theta=rep(0.5,nb))
                ) 
}

parameters <- c("mu","PPL")

model.name <- paste0("/models/ModelPoissonLogLinear",model.id,".bug") 
model.path <- paste0(getwd(),model.name)

samples <- bugs(data,parameters,inits=myinits , model.file = model.path, 
 n.chains=2,n.iter=10000, n.burnin=2500, n.thin=2, DIC=T, 
bugs.directory=bugsdir, codaPkg=F, debug=T)

#we didn't remove the island
data$Y[254] <- floor(mean(samples$sims.list$mu[,254]))

source("utils\\computeGoodnessOfFit.R")
fit.mspe <- computeMspe(samples$sims.list$PPL)
fit.waic <- computeWaicPoisson(data$Y, samples$sims.list$mu)

vendee.sf$PPL <- sqrt(colMeans(samples$sims.list$PPL))

library(tmap)
jpeg("ppl\\PoissonLogLinearPPL.jpg", width = 850, height = 850)
tmap_mode('plot') + tm_shape(vendee.sf) + 
tm_polygons('PPL', title = "PPL", palette ="Oranges", breaks = c(0, 20, 40, 60, 80, 100, 130, 200, 300, 400)) 
dev.off()

hist(vendee.sf$PPL)





