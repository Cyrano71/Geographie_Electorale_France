computeMspe <- function(PPL){

n.samples.ppl <- length(PPL[,1])
n.cases.ppl <-  length(PPL[1,])
mspe <- sum(PPL) / (n.samples.ppl * n.cases.ppl)

results <- list("mspe" = mspe)
return (results)
}

computeWaicBinomial <- function(Y, mu, size){

n_cases <- length(Y)
n_samples <- length(mu[,1])

ll <- matrix(,nrow=n_cases,ncol=n_samples)
for(i in 1:n_cases){
 ll[i,] <- sapply(1:n_samples, function(s){
   dbinom(Y[i], size[i], mu[s,i])
})
}

lppd <- sapply(1:n_cases, function(i) log(sum(ll[i,])) - log(n_samples))

pWAIC <- sapply(1:n_cases, function(i) var(ll[i,]))

waic <- -2 * (sum(lppd) - sum(pWAIC)) 

results <- list("waic" = waic)
return (results)

}

computeWaicPoisson <- function(Y, mu){

n_cases <- length(Y)
n_samples <- length(mu[,1])

ll <- matrix(,nrow=n_cases,ncol=n_samples)
for(i in 1:n_cases){
 ll[i,] <- sapply(1:n_samples, function(s){
   dpois(Y[i], mu[s,i])
})
}

lppd <- sapply(1:n_cases, function(i) log(sum(ll[i,])) - log(n_samples))

pWAIC <- sapply(1:n_cases, function(i) var(ll[i,]))

waic <- -2 * (sum(lppd) - sum(pWAIC)) 

results <- list("waic" = waic)
return (results)

}
