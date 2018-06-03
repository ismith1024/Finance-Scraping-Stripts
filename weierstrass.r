library(sqldf)
require(stats)
require(lattice)

db <- dbConnect(SQLite(), dbname="~/Data/CADFinance.db")

#get the time series
getTimeSeries <- function(symb){
  sqlQuery <- paste("SELECT close, day_, month_, year_ FROM xtse WHERE symbol = '", symb, "';", sep = "")
  rs <- dbSendQuery(db, sqlQuery) #time series
  while (!dbHasCompleted(rs)) {
    values <- dbFetch(rs)
  }
  
  timeSeries <- values
  return(timeSeries)
}

# provides the annualized return of the equity to the most recent date on record
# (today's value / initial value)^(1/time); time in years
# ser is the time series of values
getAnnualizedReturn <- function(initDay, initMonth, initYear, initVal, finalDay, finalMonth, finalYear, finalVal){
  years <- finalYear - initYear
  years <- years + (finalMonth - initMonth) / 12
  years <- years + (finalDay - initDay) / 252
  
  change <- (finalVal/initVal)^(1/years) 
  return(change)
}

timeSeries <- getTimeSeries("BNS")
today <- tail(timeSeries, 1)

plot(timeSeries, pch = ".")


#get time series and compute the return data for a symbol
run <- function(symb){
  timeSer <- getTimeSeries(symb)
  #generate the kernel from here for now:
  #http://dev.theomader.com/gaussian-kernel-calculator/
  kern = c(0,0.000001,0.000002,0.000005,0.000012,0.000027,0.00006,0.000125,0.000251,0.000484,0.000898,0.001601,0.002743,0.004514,0.00714,0.010852,0.015849,0.022242,0.029993,0.038866,0.048394,0.057904,0.066574,0.073551,0.078084,0.079656,0.078084,0.073551,0.066574,0.057904,0.048394,0.038866,0.029993,0.022242,0.015849,0.010852,0.00714,0.004514,0.002743,0.001601,0.000898,0.000484,0.000251,0.000125,0.00006,0.000027,0.000012,0.000005,0.000002,0.000001,0)
  wTrans = convolve(timeSer[["close"]], kern, type = "filter")
  plot(wTrans, pch = ".")
  
  fYear <- today[["year_"]]
  fMon <- today[["month_"]]
  fDay <- today[["day_"]]
  fVal <- tail(wTrans,1)
  rets <- vector("numeric", nrow(timeSer))
  
  for(i in 1:nrow(timeSer)){
    iYear <- timeSeries[i, "year_"]
    iMon <- timeSeries[i, "month_"]
    iDay <- timeSeries[i, "day_"]
    iVal <- wTrans[i]
    rets[i] <- getAnnualizedReturn(iDay, iMon, iYear, iVal, fDay, fMon, fYear, fVal)
  }
  
  plot(rets, pch = ".")
  
}


#example return calculation
iYear <- timeSeries[250, "year_"]
iMon <- timeSeries[250, "month_"]
iDay <- timeSeries[250, "day_"]
iVal <- wTrans[250]

getAnnualizedReturn(iDay, iMon, iYear, iVal, fDay, fMon, fYear, fVal)

