
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

parseEPSChartLine <- function(line, coll){
  gsub('"', "", line)
  gsub("\\\\", "", line)
  gsub("[A-z]", "", line)
  #cat(line)
  pieces <- strsplit(line, ",", fixed = TRUE)
  for(e1 in pieces){
    #cat(e1)
    pieces2 <- strsplit(e1, ":", fixed = TRUE)
    cat("Pieces2: ")
    for(e2 in pieces2){
      cat(e2)
    }
    cat("\n")
    y <- gsub("\\\\", "", pieces2[[1]][2])
    dat <- y
    price <- pieces2[[2]][2]
    eps <- pieces2[[3]][2]
    pe <- pieces2[[4]][2]
   
    cat("Date: ")
    cat(dat)
    pieces3 <- strsplit(dat, "-", fixed = TRUE)
    year = as.numeric(gsub('"',"",pieces3[[1]][1]))
    month = as.numeric(pieces3[[1]][2])
    day = as.numeric(gsub('"',"",pieces3[[1]][3]))
    cat("  Year: ")
    cat(year)
    cat("  Month: ")
    cat(month)
    cat("  Day: ")
    cat(day)
    cat("  Price: ")
    cat(price)
    cat("  EPS: ")
    cat(eps)
    cat("  P/E: ")
    cat(pe)
    cat("\n")
    
  }
 
}
