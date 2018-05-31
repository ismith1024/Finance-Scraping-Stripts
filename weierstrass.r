library(sqldf)
require(stats)
require(lattice)


db <- dbConnect(SQLite(), dbname="~/Data/tsx.db")

#get the time series
rs <- dbSendQuery(db, "SELECT close FROM XTSE WHERE symbol = 'BNS';") #time series
while (!dbHasCompleted(rs)) {
  values <- dbFetch(rs)
}

timeSeries <- values[[1]]

plot(timeSeries, pch = ".")

#generate the kernel from here for now:
#http://dev.theomader.com/gaussian-kernel-calculator/
kern = c(0,0.000001,0.000002,0.000005,0.000012,0.000027,0.00006,0.000125,0.000251,0.000484,0.000898,0.001601,0.002743,0.004514,0.00714,0.010852,0.015849,0.022242,0.029993,0.038866,0.048394,0.057904,0.066574,0.073551,0.078084,0.079656,0.078084,0.073551,0.066574,0.057904,0.048394,0.038866,0.029993,0.022242,0.015849,0.010852,0.00714,0.004514,0.002743,0.001601,0.000898,0.000484,0.000251,0.000125,0.00006,0.000027,0.000012,0.000005,0.000002,0.000001,0)
wTrans = convolve(timeSeries, kern, type = "filter")
plot(wTrans, pch = ".")


