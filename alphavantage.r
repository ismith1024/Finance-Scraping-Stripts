# Obtain time series price data from ALphavantage using the API
# key is:
# CTECN021MT4UQAJ2
# https://www.alphavantage.co/documentation/
# example query - full range
# https://www.alphavantage.co/query?function=TIME_SERIES_DAILY&symbol=BNS&&outputsize=full&apikey=CTECN021MT4UQAJ2
# example query - default range
# https://www.alphavantage.co/query?function=TIME_SERIES_DAILY&symbol=BNS&apikey=CTECN021MT4UQAJ2

# Libraries used by the script
library(rvest)
library(xml2)
library(sqldf)
require(stats)
require(lattice)
library(jsonlite)

#obtains the USD daily time series data for the symbol
scrapeAVdata <- function(sym){
  theURL <- paste("https://www.alphavantage.co/query?function=TIME_SERIES_DAILY&symbol=",sym,"&apikey=CTECN021MT4UQAJ2",sep = "")
  jsonText <- fromJSON(theURL, simplifyDataFrame = TRUE)
  #the dates from the jsonText DataFrame
  frames <- jsonText[[2]]
  dates = names(frames)
  vals <- vector(mode="numeric", length=length(frames))
  for(i in 1:length(frames)){
    vals[i] <- frames[i][[1]][[4]]
  }
  
  for(k in 1:length(frames)){
    print(paste(dates[k], ":",vals[k], sep = ""))
  }
  
  #TODO: write to SQL
}


