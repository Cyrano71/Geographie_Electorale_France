library(readxl)
library(openxlsx)

if(!exists("vendee.sf")){
 source("init\\Init.Vendee.Shape.R")
}

path_vote <- "data\\Presidentielle2017ResultatsCommunesTour2.xlsx"
vote <- read.xlsx(path_vote, sheet = "Presidentielle2017ResultatsComm", startRow = 1)

vote_groupe <- transform(vote, group=cut(Votants,  breaks=c(-Inf,500,1000, 2000, 3000, Inf),
                             labels=c('<500', '500-1000', '1000-2000', '2000-3000', '>3000')))
vote <- vote_groupe
communes_moyenne <- do.call(data.frame,aggregate(cbind(X..Voix.Exp.Lepen,X..Voix.Exp.Macron)~group, vote_groupe, 
        FUN=function(x) c(Count=length(x), Average=mean(x))))

vote_vendee <- vote[vote$Code.du.département == 85, ]
vote_vendee$insee <- as.numeric(vote_vendee$Code.du.département) * 1000 + as.numeric(vote_vendee$Code.de.la.commune)

nbvotes.realise.lepen <- c()
nbvotes.realise.macron <- c()
communes.nbVotes.attendus.lepen <- c()
communes.nbVotes.attendus.macron <- c()
total.votants <- c()
j <- 1
for(i in vendee.sf$insee){
  matched_vote <- vote_vendee[which(vote_vendee$insee == i),]
  votants <- matched_vote$Votants
  total.votants[j] <- votants

  nbvotes.realise.lepen[j] <- votants * matched_vote$"X..Voix.Exp.Lepen" / 100
  nbvotes.realise.macron[j] <- votants *  matched_vote$"X..Voix.Exp.Macron" / 100

  commune_group <- matched_vote$"group"
  commune_moyenne <- communes_moyenne[communes_moyenne$group == commune_group,]

  communes.nbVotes.attendus.lepen[j] <- votants * commune_moyenne$"X..Voix.Exp.Lepen.Average" /100
  communes.nbVotes.attendus.macron[j] <- votants * commune_moyenne$"X..Voix.Exp.Macron.Average" /100

  j <- j + 1
}

vendee.sf$Total.votants.2017.Tour2 <- total.votants
vendee.sf$NbVotes.Realises.Lepen.2017.Tour2 <- floor(nbvotes.realise.lepen)
vendee.sf$NbVotes.Realises.Macron.2017.Tour2 <- floor(nbvotes.realise.macron) 
vendee.sf$NbVotes.Attendus.Lepen.2017.Tour2 <- floor(communes.nbVotes.attendus.lepen)
vendee.sf$NbVotes.Attendus.Macron.2017.Tour2 <- floor(communes.nbVotes.attendus.macron)

#tmap_mode('view') + tm_shape(vendee.sf) + 
#tm_polygons('NbVotes.Realises.Lepen.2017.Tour2', style="kmeans", title = "NbVotes.Realises.Lepen.2017.Tour2", palette ="Oranges") +
#tm_text("nom", size = 1/2)
