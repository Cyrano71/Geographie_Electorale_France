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

coord <- st_coordinates(st_centroid(vendee.sf)$geometry)
xy <- data.frame(x = coord[,"X"],y = coord[,"Y"])
xy.summary <- xy  %>% 
       summarise(mind = min(dist(cbind(x,y))), 
                 meand = mean(dist(cbind(x,y))), 
                 maxd= max(dist(cbind(x,y))))
rho <- xy.summary["maxd"][[1]]

library(tmap)
tmap_mode('view') + tm_shape(vendee.sf) + 
tm_polygons('NbVotes.Realises.Macron.2017.Tour2', title = "NbVotes.Realises.Macron.2017.Tour2 Vendee", palette ="Oranges") +
tm_text("nom", size = 1/2)

knot.id <- c(85194,85152, 85191,85084,85109,85238)
knot.nb <- length(knot.id)
knot.poly <- vendee.sf[vendee.sf$insee %in% knot.id,]
knot.points <- st_coordinates(st_centroid(knot.poly)$geometry)

samples.sf <- vendee.sf[!(vendee.sf$insee %in% knot.id),]
points <- st_coordinates(st_centroid(samples.sf)$geometry)
nb_points <- length(points[,"X"])

covariance <- function(a){
 return (1 + abs(a)) * exp(- abs(a))
}

euc.dist <- function(x1, x2) sqrt(sum((x1 - x2) ^ 2))

cov.point.knot <-  matrix(list(), nrow=nb_points, ncol=knot.nb)
for(i in 1:nb_points){
 for(j in 1:knot.nb){
    d <- euc.dist(cbind(points[i,"X"],points[i,"Y"]), cbind(knot.points[j,"X"],knot.points[j,"Y"]))
    cov.point.knot[i,j] <- covariance(d / rho)
 }
}

cov.knot.knot <- matrix(list(), nrow=knot.nb, ncol=knot.nb)
for(i in 1:knot.nb){
  for(j in 1:knot.nb){
     d <- euc.dist(cbind(knot.points[i,"X"],knot.points[i,"Y"]), cbind(knot.points[j,"X"],knot.points[j,"Y"]))
     cov.knot.knot[i,j]  <- 1 / covariance(d / rho)
 }
}

data <- list(N =nb_points, Nknot = knot.nb, CovarKnotKnot = structure(
.Data = unlist(cov.knot.knot),
.Dim = c(knot.nb,knot.nb)), 
CovarPointKnot = structure(
.Data = unlist(cov.point.knot),
.Dim = c(nb_points,knot.nb)), 
Y = samples.sf$NbVotes.Realises.Macron.2017.Tour2, 
E  = samples.sf$NbVotes.Attendus.Macron.2017.Tour2, 
xc = points[,"X"], yc = points[,"Y"])

myinits <- list(list(alpha0 = 0, alpha1 = 0,alpha2 = 0, tauS = 1), 
                list(alpha0 = 0, alpha1 = 0,alpha2 = 0, tauS = 1),
                list(alpha0 = 0, alpha1 = 0,alpha2 = 0,tauS = 1)
) 

parameters <- c("mu")

model.path <- paste0(getwd(),"/models/ModelSpline.bug")

samples <- bugs(data,parameters,inits=myinits , model.file = model.path, 
 n.chains=3,n.iter= 8000, n.burnin=500, n.thin=20, DIC=T, 
bugs.directory=bugsdir, codaPkg=F, debug=T)

err <- samples.sf$NbVotes.Realises.Macron.2017.Tour2 - colMeans(samples$sims.list$mu)
hist(err)

samples.sf$err <- err
tmap_mode('view') + tm_shape(samples.sf) + 
tm_polygons('err', title = "Erreurs Vendee NbVotes.Realises.Macron.2017.Tour2", palette ="Oranges") +
tm_text("nom", size = 1/2)