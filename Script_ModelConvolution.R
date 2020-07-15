#Convolution

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
startIndexCumAdj <- c()
endIndexCumAdj <- c()
for (i in 1:N){
  startIndexCumAdj[i] <- cum[i] + 1
  endIndexCumAdj[i] <- cum[i+1]
}

model.id <- 2

if(model.id == 1){
   
   data <- list(N = N, adj=adj,
                startIndexCumAdj = startIndexCumAdj, endIndexCumAdj = endIndexCumAdj,
                 Y = vendee.sf$NbVotes.Realises.Macron.2017.Tour2, E = vendee.sf$NbVotes.Attendus.Macron.2017.Tour2)

}else if(model.id == 2){

 data <- list(N = N,sumNumNeigh=sumNumNeigh, num=num, adj=adj,
                 Y = vendee.sf$NbVotes.Realises.Macron.2017.Tour2, E = vendee.sf$NbVotes.Attendus.Macron.2017.Tour2)

}else{
  
  data <- list(N = N,sumNumNeigh=sumNumNeigh, num=num, adj=adj,
               Y = vendee.sf$NbVotes.Realises.Macron.2017.Tour2, E = vendee.sf$NbVotes.Attendus.Macron.2017.Tour2,
               Covariate = vendee.sf$CHOMAGE.PERCENTAGE.2016)
}

if(model.id == 3){
  myinits <- list(list(beta0 = 0, beta1 = 0), 
                list(beta0 = 0, beta1 = 0),
                list(beta0 = 0, beta1 = 0)) 
}else{
  myinits <- list(list(beta0 = 0), 
                list(beta0 = 0),
                list(beta0 = 0)) 
}

parameters <- c("mu","PPL")

model.name <- paste0("/models/ModelConvolution",model.id,".bug") 
model.path <- paste0(getwd(),model.name)

samples <- bugs(data,parameters,inits=myinits , model.file = model.path, 
 n.chains=3,n.iter= 8000, n.burnin=500, n.thin=20, DIC=T, 
bugs.directory=bugsdir, codaPkg=F, debug=T)

data$Y[253] <- floor(mean(samples$sims.list$mu[,253]))

source("utils\\computeGoodnessOfFit.R")
fit.mspe <- computeMspe(samples$sims.list$PPL)
fit.waic <- computeWaicPoisson(data$Y, samples$sims.list$mu)

vendee.sf$PPL <- sqrt(colMeans(samples$sims.list$PPL))

library(tmap)

jpeg("ppl\\ConvolutionPPL.jpg", width = 850, height = 850)

tmap_mode('plot') + tm_shape(vendee.sf) + 
tm_polygons('PPL', title = "PPL", palette ="Oranges", breaks = c(0, 20, 40, 60, 80, 100, 130, 200, 300, 400)) 

dev.off()