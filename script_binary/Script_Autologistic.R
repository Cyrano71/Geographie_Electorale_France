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
vendee.sf$Binary.Macron.2017.Tour2  <- (vendee.sf$NbVotes.Realises.Macron.2017.Tour2 > vendee.sf$NbVotes.Realises.Lepen.2017.Tour2) + 0

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

library(tmap)
tmap_mode('view') + tm_shape(vendee.sf) + 
tm_polygons('Binary.Macron.2017.Tour2', title = "Binary Macron", palette ="Oranges") +
tm_text("id", size = 2)

sumBinaryMacron <- c()
for (i in 1:N){
  nb <- which(matrix.nb[,i] == 1)
  nb.names <- names(nb)
  samples <- vendee.sf[which(vendee.sf$id %in% nb.names),]
  sumBinaryMacron[i] <- sum(samples$Binary.Macron.2017.Tour2)
}

data <- list(N = N, 
Y = vendee.sf$Binary.Macron.2017.Tour2, 
SSum = sumBinaryMacron,
Covariate = vendee.sf$CHOMAGE.PERCENTAGE.2016)

myinits <- list(list(alpha0 = 0, alpha1 = 0,beta = 0), 
                list(alpha0 = 0, alpha1 = 0,beta = 0),
                list(alpha0 = 0, alpha1 = 0,beta = 0)
) 

parameters <- c("p")

model.path <- paste0(getwd(),"/models/ModelAutologistic.bug")

samples <- bugs(data,parameters,inits=myinits , model.file = model.path, 
 n.chains=3,n.iter= 8000, n.burnin=500, n.thin=20, DIC=T, 
bugs.directory=bugsdir, codaPkg=F, debug=T)

colMeans(samples$sims.list$p)
hist(samples$sims.list$p) 



