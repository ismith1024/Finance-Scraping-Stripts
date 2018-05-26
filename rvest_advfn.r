# Libraries used by the script
library(rvest)
library(xml2)
library(sqldf)
require(stats)
require(lattice)

# Database connection to the Canadian finance SQLite database
db <- dbConnect(SQLite(), dbname="~/Data/CADFinance.db")

#function to create TSX URL
#takes the symbol
#returns the url
#target is https://ca.advfn.com/stock-market/TSX/BNS/financials?btn=istart_date&istart_date=44&mode=quarterly_reports
#date ranges from 0 to 89
tsxURL <- function(symb, dat){
  ret <- paste("https://ca.advfn.com/stock-market/TSX/", symb, "/financials?btn=istart_date&istart_date=", dat, "&mode=quarterly_reports", sep = "")
  return(ret)
}

#get and parse the earnings, dividends, and dates from ADVFN
#takes the URL
#writes the values to SQLite if successful
#returns 0 for success or -1 for no data
scrapeLine <- function(theURL, symb, ex){
  
  advfn <- read_html(theURL)
  #advfn <- read_html("https://ca.advfn.com/stock-market/TSX/BNS/financials?btn=istart_date&istart_date=44&mode=quarterly_reports")
  nodes <- advfn %>% html_nodes("td") %>% html_text
  epsOn <- FALSE
  datesOn <- FALSE
  divsOn <- FALSE
  last <- FALSE
  eps <- c(0.0, 0.0, 0.0, 0.0, 0.0)
  div <- c(0.0, 0.0, 0.0, 0.0, 0.0)
  dates <- c("", "", "", "", "")
  
  j<-1
  for(i in nodes){
    if(j > 5){
      epsOn <- FALSE
      datesOn <- FALSE
      divsOn <- FALSE
      j <- 1
    } else if(i == "Basic EPS - Total"){
      epsOn <- TRUE
      j <- 1
    } else if(i == "quarter end date"){
      datesOn <- TRUE
      j <- 1
    } else if(i == "dividends paid per share" || i == "Dividends Paid Per Share (DPS)"){
      divsOn <- TRUE
      j <- 1
    } else if(divsOn == TRUE && j <= 5) {
      div[j] <- i
      #print(i)
      j = j + 1
    } else if(datesOn == TRUE && j <= 5){
      dates[j] <- i
      #print(i)
      j = j + 1
    } else if(epsOn == TRUE && j <= 5){
      eps[j] <- i
      #print(i)
      j = j + 1
    }
  }
  print(j)
  print(eps)
  print(div)
  print(dates)
  
  for(k in c(1:5)){
    sqlQuery <- paste("INSERT INTO earnings(symbol, exchange, date, eps, div) VALUES('",symb, "','", ex, "','" ,dates[k], "',", eps[k], ",", div[k],");", sep = "")
    tryCatch({
      dbSendQuery(conn = db, sqlQuery)
    },
      error = function(e) print(e)
    )
  }
  return(0)
}



#The function I used to test the basic web connection and HTML parsing components
test <- function(){
  advfn <- read_html("https://ca.advfn.com/stock-market/NYSE/BNS/financials?btn=quarterly_reports&mode=company_data")
  nodes <- advfn %>% html_nodes("td") %>% html_text
  first <- FALSE
  last <- FALSE
  vals <- c("0", "0", "0", "0")
  j <- 0
  for(i in nodes){
    if(i == "Basic EPS - Total"){
      first <- TRUE
    } else if(i == "Basic EPS - Normalized"){
        last <- TRUE
    } else if(first == TRUE && last == FALSE) {
      #c[j] <- i
      print(i)
      j = j + 1
    }
  }
}

run <- function(){
  
  #fetch the symbols from the SQLite database
  rs <- dbSendQuery(db, "SELECT symbol FROM symbols;")
  while (!dbHasCompleted(rs)) {
    symbols <- dbFetch(rs)
  }
  
  syms <- symbols[[1]]
  
  for(sym in syms){
    for(dat in c(0:89)){
      aURL <- tsxURL(sym, dat)
      print(aURL)
      scrapeLine(aURL, sym, "TSX")
    }
  }

  dbClearResult(rs)   
}
