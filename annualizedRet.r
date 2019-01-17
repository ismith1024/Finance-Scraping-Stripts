library(sqldf)
require(stats)
require(lattice)

db <- dbConnect(SQLite(), dbname="~/Data/CADFinance.db")

#get the time series
getTimeSeries <- function(symb){
  sqlQuery <- paste("SELECT close, day_, month_, year_ FROM xtse WHERE symbol = '", symb, "';", sep = "")
  #print(sqlQuery)
  rs <- dbSendQuery(db, sqlQuery) #time series
  while (!dbHasCompleted(rs)) {
    values <- dbFetch(rs)
  }
  
  timeSeries <- values
  return(timeSeries)
}


#retrieve a [eps, div, year, month] dataframe
#for the given symbol
#NOTE: earnings uses a '.' instead of a '_' character, need to substitute
getEarnings <- function(symb){
  theSym <- gsub("_", ".", symb)
  sqlQuery <- paste("SELECT eps, div, year_, month_ FROM earnings WHERE symbol = '", theSym, "' ORDER BY year_, month_ ASC;", sep = "")
  rs <- dbSendQuery(db, sqlQuery)
  while (!dbHasCompleted(rs)) {
    values <- dbFetch(rs)
  }
  
  earn<-values
  return(earn)
}

#get the last four quarters of EPS values from the date
last4eps <- function(symb, year, month, day, earns){
  i <- 1
  found <- FALSE
  while(found == FALSE){
    if(earns[i, "year_"] == year && earns[i, "month_"] == month){
      found <- TRUE
    }
    i = i + 1
  }
  if(i <= 3) return(0)
  
  val = earns[i, "eps"] + earns[i-1, "eps"] + earns[i-2, "eps"] + earns[i-3, "eps"] 
  return(val)
}

#get the last four quarters of dividend values from the date
last4divs <- function(symb, year, month, day, earns){
  i <- 1
  found <- FALSE
  while(found == FALSE){
    if(earns[i, "year_"] == year && earns[i, "month_"] == month){
      found <- TRUE
    }
    i = i + 1
  }
  if(i <= 3) return(0)
  
  val = earns[i, "div"] + earns[i-1, "div"] + earns[i-2, "div"] + earns[i-3, "div"] 
  return(val)
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

#get time series and compute the return data for a symbol
#time series is smoothed using a Weiersrass transform -- intended to remove Gaussian noise
#Kernel prameters:
#n = 51
#sigma = 10
runRets <- function(symb){
  timeSer <- getTimeSeries(symb)
  #generate the kernel from here for now:
  #http://dev.theomader.com/gaussian-kernel-calculator/
  kern = c(0,0.000001,0.000002,0.000005,0.000012,0.000027,0.00006,0.000125,0.000251,0.000484,0.000898,0.001601,0.002743,0.004514,0.00714,0.010852,0.015849,0.022242,0.029993,0.038866,0.048394,0.057904,0.066574,0.073551,0.078084,0.079656,0.078084,0.073551,0.066574,0.057904,0.048394,0.038866,0.029993,0.022242,0.015849,0.010852,0.00714,0.004514,0.002743,0.001601,0.000898,0.000484,0.000251,0.000125,0.00006,0.000027,0.000012,0.000005,0.000002,0.000001,0)
  wTrans = convolve(timeSer[["close"]], kern, type = "filter")
  #plot(wTrans, pch = ".")
  today <- tail(timeSer, 1)
  
  fYear <- today[["year_"]]
  fMon <- today[["month_"]]
  fDay <- today[["day_"]]
  fVal <- tail(wTrans,1)
  rets <- vector("numeric", nrow(timeSer))
  
  #for(i in 1:10){
  for(i in 1:nrow(timeSer)){
    iYear <- timeSer[i, "year_"]
    iMon <- timeSer[i, "month_"]
    iDay <- timeSer[i, "day_"]
    iVal <- wTrans[i]
    rets[i] <- getAnnualizedReturn(iDay, iMon, iYear, iVal, fDay, fMon, fYear, fVal)
    
    #print(timeSer[i,])
    #print(rets[i])
  }
  
  print(today)
  plot(rets, pch = ".")
  
}

runTS <- function(symb){
  timeSer <- getTimeSeries(symb)
  #generate the kernel from here for now:
  #http://dev.theomader.com/gaussian-kernel-calculator/
  kern = c(0,0.000001,0.000002,0.000005,0.000012,0.000027,0.00006,0.000125,0.000251,0.000484,0.000898,0.001601,0.002743,0.004514,0.00714,0.010852,0.015849,0.022242,0.029993,0.038866,0.048394,0.057904,0.066574,0.073551,0.078084,0.079656,0.078084,0.073551,0.066574,0.057904,0.048394,0.038866,0.029993,0.022242,0.015849,0.010852,0.00714,0.004514,0.002743,0.001601,0.000898,0.000484,0.000251,0.000125,0.00006,0.000027,0.000012,0.000005,0.000002,0.000001,0)
  wTrans = convolve(timeSer[["close"]], kern, type = "filter")
  plot(wTrans, pch = ".")
}

#example return calculation
#iYear <- timeSeries[250, "year_"]
#iMon <- timeSeries[250, "month_"]
#iDay <- timeSeries[250, "day_"]
#iVal <- wTrans[250]

#getAnnualizedReturn(iDay, iMon, iYear, iVal, fDay, fMon, fYear, fVal)


#########################
# Getintegrated
# Integrates the earnings and price tables
# I dont want a view due to the computational complexity of the full table join
# (takes 4 sec after the SELECTS already)
#########################
#The query is ugly
#SELECT DISTINCT day_, month_, year_, close, eps, div FROM
#(SELECT	day_, month_, year_ 
#  FROM xtse 
#  WHERE
#  symbol = "BNS"
#  UNION all
#  SELECT 15 as day_, month_, year_ 
#  FROM earnings 
#  WHERE symbol = "BNS")													
#LEFT JOIN(
#  SELECT 15 as day2, month_ as month2, year_ as year2, div, eps
#  FROM earnings 
#  WHERE symbol = "BNS"
#) 
#ON day_ = day2 AND month_ = month2 AND year_ = year2
#LEFT JOIN(
#  SELECT day_ as day3, month_ as month3, year_ as year3, close
#  FROM xtse
#  WHERE symbol = "BNS"
#)
#ON day_ = day3 AND month_ = month3 AND year_ = year3
#ORDER BY year_, month_, day_
#;
getIntegrated <- function(symb){
  sqlQuery <- paste("SELECT DISTINCT day_, month_, year_, close, eps, div, date_ FROM (SELECT day_, month_, year_ FROM xtse WHERE symbol = '", symb, "' UNION all SELECT 15 as day_, month_, year_ FROM earnings WHERE symbol = '", symb, "') LEFT JOIN( SELECT 15 as day2, month_ as month2, year_ as year2, div, eps FROM earnings WHERE symbol = '", symb, "') ON day_ = day2 AND month_ = month2 AND year_ = year2 LEFT JOIN ( SELECT day_ as day3, month_ as month3, year_ as year3, close, date_ FROM xtse WHERE symbol = '", symb, "') ON day_ = day3 AND month_ = month3 AND year_ = year3 ORDER BY year_, month_, day_;", sep = "")
  print(sqlQuery)
  rs <- dbSendQuery(db, sqlQuery) 
  
  while (!dbHasCompleted(rs)) {
    values <- dbFetch(rs)
    #print(dbFetch(rs))
  }
  
  ret <- values
  
  #counts the number of valid data points we have for earnings
  earnsCount <- 0
  
  #track the last four eps and div
  earns <- c(0,0,0,0)
  divs <- c(0,0,0,0)
  anEPS <- 0.0
  anDiv <- 0.0
  
  for(i in 1:nrow(ret)){
    if(!is.na(ret[[i, "eps"]])){
      earnsCount <- earnsCount + 1
      earns[1] <- earns[2]
      earns[2] <- earns[3]
      earns[3] <- earns[4]
      earns[4] <- ret[i, "eps"]
      anEPS <- earns[1] + earns[2] + earns[3] + earns[4]
      
      divs[1] <- divs[2]
      divs[2] <- divs[3]
      divs[3] <- divs[4]
      divs[4] <- ret[i, "div"]
      anDiv <- divs[1] + divs[2] + divs[3] + divs[4]
      
      #print(paste("EPS: ", anEPS, " Div: ", anDiv, sep = ""))
    }
    
    if(!is.na(ret[i, "close"]) && earnsCount >= 4){
      ret[i, "p-e"] <- ret[i, "close"] / anEPS
      ret[i, "divYld"] <- 100 * anDiv / ret[i, "close"] 
    }
  }
  
  return(ret)
  
}

runInt <- function(symb){
  intData <- getIntegrated(symb)

  #for(rec in intData){
  #  print(paste(rec["year_"], rec["month_"], rec["day_"], sep = '-'))
    #rec["date"] <- as.Date(paste(rec["year_"], rec["month_"], rec["day_"], sep = '-'))
  #}
  
  #intData

}

