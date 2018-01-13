library(sqldf)
require(stats)
require(lattice)

db <- dbConnect(SQLite(), dbname="~/Data/USFinance.db")


divreg <- function(symbol, todaysPrice, todaysYield){
  thisYear <- 2018
  thisMonth <- 1
  
  sqlString <- paste("SELECT * FROM Integrated WHERE Symbol = '", symbol,"' AND Yld IS NOT NULL AND Yld < 50", sep = "");
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
