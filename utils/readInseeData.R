readInseeData <- function(file.name, file.sheet, file.startRow, ids, tag)
{
file.path <- paste("data", file.name, sep="\\")
data <- read.xlsx(file.path, sheet = file.sheet, startRow = file.startRow)
data.samples <- data[data$CODGEO  %in% ids,] 
l <- length(colnames(data.samples))

target_col <- c()
if(tag == ""){
  target_col <- colnames(data.samples)[3:l]
}else{
  j <- 1
  for(i in colnames(data.samples)){
     if(grepl(tag, i)){
       target_col[j] <- i
       j <- j + 1
    }
  }
}
data.samples$total <- rowSums(data.samples[,target_col])

vector1 <- c()
j <- 1
for(i in ids){
  vector1[j] <- data.samples[which(data.samples$CODGEO == i),]$total
  j <- j + 1
}

return (vector1)
}