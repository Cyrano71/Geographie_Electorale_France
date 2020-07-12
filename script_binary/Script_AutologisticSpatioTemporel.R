library(spdep)   
library(bayestestR)
library(dplyr)
library(R2WinBUGS)
bugsdir <- "C:/Program Files/WinBUGS14"

source("init\\Vendee.Shape.R")
source("init\\Vendee.Covariates.2012.R")
source("init\\Vendee.Covariates.2016.R")
source("init\\Vendee.Presidentielle.2012.Tour2.R")
source("init\\Vendee.Presidentielle.2017.Tour2.R")

#remove island
vendee.sf <- vendee.sf[which(vendee.sf$insee != "85113"),]
vendee.sf$Binary.CentreGauche.2012.Tour2  <- (vendee.sf$NbVotes.Realises.Hollande.2012.Tour2 > vendee.sf$NbVotes.Realises.Sarkozy.2012.Tour2) + 0
vendee.sf$Binary.CentreGauche.2017.Tour2  <- (vendee.sf$NbVotes.Realises.Macron.2017.Tour2 > vendee.sf$NbVotes.Realises.Lepen.2017.Tour2) + 0

nb_polygons <- length(st_geometry(vendee.sf))
N <- nb_polygons
shape_nb <- poly2nb(vendee.sf, queen = FALSE)
NumCells= length(shape_nb)
num=sapply(shape_nb,length)
adj=unlist(shape_nb)
sumNumNeigh=length(unlist(shape_nb))

matrix.nb = nb2mat(shape_nb,zero.policy=TRUE, style="B")

vendee.data <- as.data.frame(vendee.sf)
vendee.data$id <- rownames(vendee.data)
vendee.sf$id <- rownames(vendee.data)

sumBinaryCentreGauche.2012.Tour2 <- c()
sumBinaryCentreGauche.2017.Tour2 <- c()
for (i in 1:N){
  nb <- which(matrix.nb[,i] == 1)
  nb.names <- names(nb)
  samples <- vendee.sf[which(vendee.sf$id %in% nb.names),]
  sumBinaryCentreGauche.2012.Tour2[i] <- sum(samples$Binary.CentreGauche.2012.Tour2)
  sumBinaryCentreGauche.2017.Tour2[i] <- sum(samples$Binary.CentreGauche.2017.Tour2)
}

totalBinaryCentreGauche.2ans <- c()
ssumBinaryCentreGauche.2ans <- c()
j <- 1
for(i in 1:N){
 totalBinaryCentreGauche.2ans[j] <- vendee.sf$Binary.CentreGauche.2012.Tour2[i]
 ssumBinaryCentreGauche.2ans[j] <- sumBinaryCentreGauche.2012.Tour2[i]
 j <- j + 1
}
for(i in 1:N){
 totalBinaryCentreGauche.2ans[j] <- vendee.sf$Binary.CentreGauche.2017.Tour2[i]
 ssumBinaryCentreGauche.2ans[j] <- sumBinaryCentreGauche.2017.Tour2[i]
 j <- j + 1
}

data <- list(N = N, T = 2,
Y = matrix(totalBinaryCentreGauche.2ans,N,2), 
SSum = matrix(ssumBinaryCentreGauche.2ans,N,2))

myinits <- list(list(alpha0 = rep(0,2), beta1 = rep(0,2), beta2 = rep(0,2)), 
                list(alpha0 = rep(0,2), beta1 = rep(0,2), beta2 = rep(0,2))
) 

parameters <- c("mspe")

model.path <- paste0(getwd(),"/models/ModelAutologisticSpatioTemporel.bug")

samples <- bugs(data,parameters,inits=myinits , model.file = model.path, 
 n.chains=2,n.iter= 8000, n.burnin=500, n.thin=20, DIC=T, 
bugs.directory=bugsdir, codaPkg=F, debug=T)



