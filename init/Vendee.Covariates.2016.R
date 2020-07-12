library(readxl)
library(openxlsx)

if(!exists("vendee.sf")){
 source("init\\Init.Vendee.Shape.R")
}

if(!exists("readInseeData")){
 source("utils\\readInseeData.R")
}

vendee.sf$IMMI.TOTAL.2016 <- readInseeData("BTX_TD_IMG1A_2016.xlsx", "COM", 11, vendee.sf$insee, "IMMI1")
vendee.sf$POPU.TOTAL.2016 <- readInseeData("BTX_TD_POP1A_2016.xlsx", "COM", 11, vendee.sf$insee, "")
vendee.sf$CHOMAGE.TOTAL.2016 <- readInseeData("BTX_TD_ACT1_2016.xlsx", "COM", 11, vendee.sf$insee, "TACTR_212")

vendee.sf$IMMI.PERCENTAGE.2016 <- 100 * vendee.sf$IMMI.TOTAL.2016 / vendee.sf$POPU.TOTAL.2016
vendee.sf$CHOMAGE.PERCENTAGE.2016 <- 100 * vendee.sf$CHOMAGE.TOTAL.2016 / vendee.sf$POPU.TOTAL.2016

#tmap_mode('view') + tm_shape(vendee.sf) + 
#tm_polygons('AGE425_IMMI2_SEXE1', style="kmeans", title = "Immigration en Vendée", palette ="Oranges") +
#tm_text("nom", size = 1/2)

