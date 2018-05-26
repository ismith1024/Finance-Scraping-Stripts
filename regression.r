library(sqldf)
symbolsrequire(stats)
require(lattice)

db <- dbConnect(SQLite(), dbname="~/Data/USFinance.db")


divreg <- function(symbol, todaysPrice, todaysYield){
  thisYear <- 2018
  thisMonth <- 5
  
  sqlString <- paste("SELECT * FROM Integrated WHERE Symbol = '", symbol,"' AND Yld IS NOT NULL AND Yld < 10 AND (Y < 2017 OR M < 6)", sep = "");
  divTable <- dbGetQuery(db, sqlString);
  
  divTable$CADPrice <- divTable$Xchange * divTable$Price
  divTable$Elapsed <- thisYear - divTable$Y - (divTable$M - thisMonth)/12
  divTable$Return <- todaysPrice / divTable$CADPrice
  divTable$Annualized <- divTable$Return ^ (1/divTable$Elapsed)
  
  #print(divTable)
  
  dv.mod1 <- lm(Annualized ~ Yld, data = divTable)
  
  #summary(dv.mod1)
  plot(divTable$Yld, divTable$Annualized, main = paste("Yield Regression: ", symbol, sep = ""), xlab = "Dividend Yield", ylab = "Annualized Return")
  
  abline(dv.mod1)

  print("Predicted annualized yeld: ")  
  predict(dv.mod1, data.frame(Yld = c(todaysYield)))
  
}

pereg <- function(symbol, todaysPrice, todaysPE){
  thisYear <- 2018
  thisMonth <- 1
  
  sqlString <- paste("SELECT * FROM Integrated WHERE Symbol = '", symbol,"' AND PE IS NOT NULL AND pe < 70 AND (Y < 2017 OR M < 6)", sep = "");
  peTable <- dbGetQuery(db, sqlString);
  
  peTable$CADPrice <- peTable$Xchange * peTable$Price
  peTable$Elapsed <- thisYear - peTable$Y - (peTable$M - thisMonth)/12
  peTable$Return <- todaysPrice / peTable$CADPrice
  peTable$Annualized <- peTable$Return ^ (1/peTable$Elapsed)
  
  #print(peTable)
  
  pe.mod1 <- lm(Annualized ~ PE, data = peTable)
  
  #summary(dv.mod1)
  plot(peTable$PE, peTable$Annualized, main = paste("P-E Regression: ", symbol, sep = ""), xlab = "P-E Ratio", ylab = "Annualized Return")
  
  abline(pe.mod1)
  
  print("Predicted annualized yeld: ")
  td <- data.frame(PE = c(todaysPE))
  
  #print(td)
  
  predict(pe.mod1, data.frame(PE = c(todaysPE)))
  
}
