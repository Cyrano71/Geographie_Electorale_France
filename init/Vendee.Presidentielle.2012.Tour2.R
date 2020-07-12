library(readxl)
library(openxlsx)

if(!exists("vendee.sf")){
 source("init\\Init.Vendee.Shape.R")
}

path_vote <- "data\\Presidentielle2012ResultatsCommunesTour1Tour2.xlsx"
vote <- read.xlsx(path_vote, sheet = "Tour 2", startRow = 1)

vote_groupe <- transform(vote, group=cut(Votants,  breaks=c(-Inf,500,1000, 2000, 3000, Inf),
                             labels=c('<500', '500-1000', '1000-2000', '2000-3000', '>3000')))
vote <- vote_groupe
communes_moyenne <- do.call(data.frame,aggregate(cbind(X..Voix.ExpHollande,X..Voix.ExpSarkozy)~group, vote_groupe, 
        FUN=function(x) c(Count=length(x), Average=mean(x))))

vote_vendee <- vote[vote$Code.du.département == 85, ]
vote_vendee$insee <- as.numeric(vote_vendee$Code.du.département) * 1000 + as.numeric(vote_vendee$Code.de.la.commune)

nbvotes.realise.hollande <- c()
nbvotes.realise.sarkozy <- c()
communes.nbVotes.attendus.hollande <- c()
communes.nbVotes.attendus.sarkozy <- c()
total.votants <- c()
j <- 1
for(i in vendee.sf$insee){
  matched_vote <- vote_vendee[which(vote_vendee$insee == i),]
  votants <- matched_vote$Votants
  total.votants[j] <- votants

  nbvotes.realise.hollande[j] <- votants * matched_vote$"X..Voix.ExpHollande" / 100
  nbvotes.realise.sarkozy[j] <- votants *  matched_vote$"X..Voix.ExpSarkozy" / 100

  commune_group <- matched_vote$"group"
  commune_moyenne <- communes_moyenne[communes_moyenne$group == commune_group,]

  communes.nbVotes.attendus.hollande[j] <- votants * commune_moyenne$"X..Voix.ExpHollande.Average" / 100
  communes.nbVotes.attendus.sarkozy[j] <- votants * commune_moyenne$"X..Voix.ExpSarkozy.Average" / 100

  j <- j + 1
}

vendee.sf$Total.votants.2012.Tour2 <- total.votants
vendee.sf$NbVotes.Realises.Hollande.2012.Tour2 <- floor(nbvotes.realise.hollande)
vendee.sf$NbVotes.Realises.Sarkozy.2012.Tour2 <- floor(nbvotes.realise.sarkozy)
vendee.sf$NbVotes.Attendus.Hollande.2012.Tour2 <- floor(communes.nbVotes.attendus.hollande)
vendee.sf$NbVotes.Attendus.Sarkozy.2012.Tour2 <- floor(communes.nbVotes.attendus.sarkozy)


