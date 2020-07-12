library(readxl)
library(openxlsx)

path_vote <- "Presidentielle2017ResultatsCommunesTour1.xlsx"
vote <- read.xlsx(path_vote, sheet = "Feuil1", startRow = 4)

votepercanidate <- data.frame(
"Code.du.département" = character(), "Libellé.du.département" = character(),
"Code.de.la.commune" = numeric(),"Libellé.de.la.commune" = character(),
"Votants" = numeric(), 
"VoixMacron" = numeric(), "%.Voix/ExpMacron" = numeric(),
"VoixLepen" = numeric(), "%.Voix/ExpLepen" = numeric(),
"VoixFillon" = numeric(), "%.Voix/ExpFillon" = numeric()
)

NbCommunes <- length(vote[,"Libellé.de.la.commune"])
for(i in 1:NbCommunes){
   voix <- list()
   for(name in c("MACRON","LE PEN","FILLON")){
      for(nbCandidates in 1:11){
        if(vote[i,paste0("Nom",nbCandidates)] == name){
           voix[paste0("Voix",name)] = vote[i,paste0("Voix",nbCandidates)]
           voix[paste0("%.Voix/Exp",name)] = vote[i,paste0("%.Voix/Exp",nbCandidates)]
        }
      }
   }
   votepercanidate[nrow(votepercanidate) + 1,] = list(vote[i,"Code.du.département"],vote[i,"Libellé.du.département"],vote[i,"Code.de.la.commune"],
									vote[i,"Libellé.de.la.commune"],vote[i,"Votants"],
        								voix[["VoixMACRON"]],voix[["%.Voix/ExpMACRON"]],
									voix[["VoixLE PEN"]],voix[["%.Voix/ExpLE PEN"]],
									voix[["VoixFILLON"]],voix[["%.Voix/ExpFILLON"]]
 									)
}

write.xlsx(votepercanidate,"Presidentielle2017ResultatsCommunesParCandidatTour1.xlsx")
