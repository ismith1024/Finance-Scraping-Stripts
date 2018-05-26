library(rvest)
library(xml2)
advfn <- read_html("https://ca.advfn.com/stock-market/NYSE/BNS/financials?btn=quarterly_reports&mode=company_data")
nodes <- advfn %>% html_nodes("td.sb") %>% html_text
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
