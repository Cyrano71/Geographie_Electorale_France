library(readxl)
library(openxlsx)

if(!exists("vendee.sf")){
 source("init\\Init.Vendee.Shape.R")
}

if(!exists("readInseeData")){
 source("utils\\readInseeData.R")
}

vendee.sf$POPU.TOTAL.2012 <- readInseeData("BTX_TD_POP1A_2012.xlsx", "COM", 11, vendee.sf$insee, "")
vendee.sf$CHOMAGE.TOTAL.2012 <- readInseeData("BTX_TD_ACT1_2012.xlsx", "COM", 11, vendee.sf$insee, "TACTR_212")
vendee.sf$CHOMAGE.PERCENTAGE.2012 <- 100 * vendee.sf$CHOMAGE.TOTAL.2012 / vendee.sf$POPU.TOTAL.2012

