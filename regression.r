library(sqldf)
db <- dbConnect(SQLite(), dbname="~/Data/USFinance.db")


divreg <- function(symbol, todaysPrice){
  thisYear <- 2018
  thisMonth <- 1
  
  sqlString <- paste("SELECT * FROM Integrated WHERE Symbol = '", symbol,"' AND Yld IS NOT NULL", sep = "");
  divTable <- dbGetQuery(db, sqlString);
  
  divTable$CADPrice <- divTable$Xchange * divTable$Price
  divTable$Elapsed <- thisYear - divTable$Y - (divTable$M - thisMonth)/12
  divTable$Return <- todaysPrice / divTable$CADPrice
  divTable$Annualized <- divTable$Return ^ (1/divTable$Elapsed)
  
  print(divTable)
  
}
