
# function to get raw dividend text from a web page
# urlString is the URL
readDivs <- function(symbol){
    urlString <- paste("http://www.macrotrends.net/assets/php/dividend_yield.php?t=", symbol , sep = "")
    text <- readLines(urlString)
    return(text) 
}

# function to get raw EPS text from a web page
# urlString is the URL
readPE <- function(symbol){
    urlString <- paste("http://www.macrotrends.net/assets/php/fundamental_ratio.php?t=", symbol , "&chart=pe-ratio" , sep = "")
    text <- readLines(urlString)
    return(text) 
}

getChart <- function(text){
    for(e1 in text){
        #cat(e1)
        if(grepl("chartData", e1, fixed=TRUE)){
            cat(e1)
            return(e1)
        }    
    }
    return("")
}

parseChart <- function(text){
  pieces <- strsplit(text, "},{", fixed = TRUE)
  return(pieces)
}

printVals <- function(a){
  for(i in a){
    if(grepl("chartData", i, fixed=TRUE)){
      cat(i)
    }
    #cat(i)
  }
}
