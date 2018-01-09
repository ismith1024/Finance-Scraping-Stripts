library(sqldf)
db <- dbConnect(SQLite(), dbname="~/Data/USFinance.db")

writediv <- function(symbol){
  fil <- paste("~/R_Scrape/", symbol, "divs.csv", sep = "")
  tab <- read.csv(file=fil, header = TRUE, sep = ",")
  
  for(row in 1:nrow(tab)){
    year <- tab[row, 2]
    month <- tab[row, 3]
    day <- tab[row, 4]
    #ticker <- symbol
    sqlQuery = paste("INSERT INTO divs(year, month, day, ticker) VALUES(", year, ",", month, ",", day, ",'", symbol,"');" , sep = "")
    dbSendQuery(conn = db, sqlQuery)
  }
  
}
