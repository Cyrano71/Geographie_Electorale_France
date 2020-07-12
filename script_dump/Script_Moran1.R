#########################################

cum <- cumsum(num)
cum <- append(cum, 0, after = 0)
startIndexCumAdj <- c()
endIndexCumAdj <- c()
for (i in 1:N){
  startIndexCumAdj[i] <- cum[i] + 1
  endIndexCumAdj[i] <- cum[i+1]
}

mu <- samples$sims.list$mu

data <- list(N = N, adj=adj, 
startIndexCumAdj = startIndexCumAdj , endIndexCumAdj=endIndexCumAdj, mu = colMeans(mu), 
Y = vendee.sf$NbVotes.Realises.Macron.2017.Tour2)

myinits <- list(dummy=1) 

parameters <- c("rho")
 
model.path <- paste0(getwd(),"/models/ModelMoran1.bug")

samples <- bugs(data,parameters,inits=myinits , model.file = model.path, 
 n.chains=1,n.iter= 8000, n.burnin=500, n.thin=20, DIC=F, 
bugs.directory=bugsdir, codaPkg=F, debug=T)

rho <- mean(samples$sims.list$rho)



