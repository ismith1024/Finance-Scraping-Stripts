library(sqldf)
db <- dbConnect(SQLite(), dbname="~/Data/USFinance.db")

writediv <- function(symbol){
  fil <- paste("~/R_Scrape/", symbol, "divs.csv", sep = "")
  tab <- read.csv(file=fil, header = TRUE, sep = ",")
  
  for(row in 1:nrow(tab)){
    year <- tab[row, 2]
    month <- tab[row, 3]
    day <- tab[row, 4]
    ticker <- symbol
    sqlQuery = paste("INSERT INTO divs(year, month, day, ticker) VALUES(", year, ",", month, ",", day, ",'", symbol,"');" , sep = "")
    dbSendQuery(conn = db, sqlQuery)
  }
  
  for(row in 1:nrow(tab)){
    year <- tab[row,2]
    month <- tab[row,3]
    day <- tab[row, 4]
    price <- tab[row, 5]
    dpr <- tab[row,6]
    yld <-tab[row,7]
    sqlQuery1 <- paste("UPDATE divs SET price = " , price, ", div = ", dpr, " , yld = ", yld, " WHERE year = ", year, " AND month = ", month, " AND day = ", day, " AND ticker = '", symbol, "';", sep = "")
    print(sqlQuery1)
    dbSendQuery(conn = db, sqlQuery1)
  }
  
}

writepe <- function(symbol){
  fil <- paste("~/R_Scrape/", symbol, "pe.csv", sep = "")
  tab <- read.csv(file=fil, header = TRUE, sep = ",")
  
  for(row in 1:nrow(tab)){
    if(! is.na(tab[row,2])){
      year <- tab[row, 2]
      month <- tab[row, 3]
      day <- tab[row, 4]
      ticker <- symbol
      sqlQuery = paste("INSERT INTO earnings(year, month, day, ticker) VALUES(", year, ",", month, ",", day, ",'", symbol,"');" , sep = "")
      dbSendQuery(conn = db, sqlQuery)
    }
  }
  
  for(row in 1:nrow(tab)){
    if(! is.na(tab[row,2])){
      year <- tab[row,2]
      month <- tab[row,3]
      day <- tab[row, 4]
      price <- tab[row, 5]
      eps <- tab[row,6]
      pe <-tab[row,7]
      sqlQuery1 <- paste("UPDATE earnings SET price = " , price, ", earnings = ", eps, " , pe = ", pe, " WHERE year = ", year, " AND month = ", month, " AND day = ", day, " AND ticker = '", symbol, "';", sep = "")
      print(sqlQuery1)
      dbSendQuery(conn = db, sqlQuery1)
    }
  }
  
}

symbols <- c("ABX", "ACM", "AQN", "BCE", "BEP", "BMO", "BNS", "BTE", "CAE", "CCJ", "CIGI", 
             "CLS", "CM", "CNI", "CNQ", "CNR", "COT", "CP", "CPG", "CVE", "ECA", "ENB",
             "ERF", "FCAP", "FSV", "FTS", "FTT", "GIB", "GIL", "GNW", "GTE", "IMO", "MFC",
             "MGA", "PBA", "PFC", "QSR", "RBA", "ROG", "RY", "SJR", "SLF", "STN", "SU", "TAC",
             "TAHO", "TD", "TECK", "TRI", "TRP", "TSG", "TU")

for(i in symbols){
  print(i)
  writepe(i)
  #writediv(i)
}

