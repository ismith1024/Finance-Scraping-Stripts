run <- function(text){
  #get the URL
  divsURL <- paste("http://www.macrotrends.net/assets/php/dividend_yield.php?t=", text , sep = "")
  peURL <- paste("http://www.macrotrends.net/assets/php/fundamental_ratio.php?t=", text , "&chart=pe-ratio" , sep = "")
  
  #read the data
  divWebText <- readLines(divsURL)
  peWebText <- readLines(peURL)
  #cat(divWebText)
  
  
  #get the chart
  divChart <- ""
  peChart <- ""
  
  for(e1 in divWebText){
    if(grepl("chartData", e1, fixed=TRUE)){
      divChart <- e1
      break
      #cat(divChart)
    } 
  }
  
  #cat("== Div Chart ========== ")
  #cat(divChart)
  #cat("\n")
  
  for(e2 in peWebText){
    if(grepl("chartData", e2, fixed=TRUE)){
      peChart <- e2
      break
    } 
  }
  
  #cat("== PE Chart ========== ")
  #cat(peChart)
  #cat("\n")
  
  #split the chart rows
  divChartRows <- parseChart(divChart)[[1]]
  peChartRows <- parseChart(peChart)[[1]]
  
  #global results
  divResults <<- matrix(nrow = length(divChartRows), ncol = 6)
  peResults <<- matrix(nrow = length(peChartRows), ncol = 6)
  
  #cat("Div Result has ")
  #cat(length(divChartRows))
  #cat(" rows \n")
  #cat("Pe Result has ")
  #cat(length(peChartRows))
  #cat(" rows \n")

  #parse each row
  i <- 0
  #cat("===DIV CHART ROWS ++\n")
  for(e1 in divChartRows){
    #cat(e1)
    cat("\n")
    #cat(".........")
    i <- i + 1
    rp <- strsplit(e1, "[:,]")
    rowPieces <- rp[[1]]
    
    if(length(rowPieces) > 7){
      #for(e4 in rowPieces){
      #  cat(e4)
      #}
      
      dp <- strsplit(rowPieces[2], "-", fixed = TRUE)
      datepieces <- dp[[1]]
      datepieces[1] <- gsub("c(\\","",datepieces[1], fixed = TRUE)
      datepieces[3] <- gsub("\\)","",datepieces[3], fixed = TRUE)
      
      #cat(datepieces[1])
      #cat(datepieces[2])
      #cat(datepieces[3])
      
      divResults[i, 1] <- gsub('"',"", datepieces[1])
      divResults[i, 2] <- gsub('"',"", datepieces[2])
      divResults[i, 3] <- gsub('"',"", datepieces[3])
      divResults[i, 4] <- rowPieces[4]
      divResults[i, 5] <- rowPieces[6]
      divResults[i, 6] <- gsub("}];","",rowPieces[8],fixed = TRUE)
      
      cat(divResults[i, 1])
      cat(" .. ")
      cat(divResults[i, 2])
      cat(" .. ")
      cat(divResults[i, 3])
      cat(" .. ")
      cat(divResults[i, 4])
      cat(" .. ")
      cat(divResults[i, 5])
      cat(" .. ")
      cat(divResults[i, 6])
      cat("\n")
    }
  }
  
  cat("== Div Results ===========\n")
  divFile <- paste(text,"divs.csv", sep = "")
  write.csv(divResults, file = divFile)
  
  #cat("===PE CHART ROWS ++\n")
  i <- 0
  for(e2 in peChartRows){
    #cat(e2)
    #cat("\n")
    #cat(".........")
    i <- i + 1
    rp <- strsplit(e2, "[:,]")
    rowPieces <- rp[[1]]
    
    if(length(rowPieces) > 7){
      dp <- strsplit(rowPieces[2], "-", fixed = TRUE)
      datepieces <- dp[[1]]
      datepieces[1] <- gsub("c(\\","",datepieces[1], fixed = TRUE)
      datepieces[3] <- gsub("\\)","",datepieces[3], fixed = TRUE)
      peResults[i, 1] <- as.numeric(gsub('"',"", datepieces[1]))
      peResults[i, 2] <- as.numeric(gsub('"',"", datepieces[2]))
      peResults[i, 3] <- as.numeric(gsub('"',"", datepieces[3]))
      peResults[i, 4] <- as.numeric(rowPieces[4])
      peResults[i, 5] <- as.numeric(rowPieces[6])
      peResults[i, 6] <- as.numeric(gsub("}];","",rowPieces[8],fixed = TRUE))
    }
  }
  
  cat("== P_E Results ===========\n")
  divFile <- paste(text,"pe.csv", sep = "")
  write.csv(divResults, file = divFile)
}


parseEPSChartLine <- function(line){
  gsub('"', "", line)
  gsub("\\\\", "", line)
  gsub("[A-z]", "", line)
  #cat(line)
  #########
  # Split a:b,c:d into: [b, d]
  #########
  pieces <- strsplit(line, ",:")
  for(e1 in pieces){
    cat(e1)
  }
  #  pieces2 <- strsplit(e1, ":", fixed = TRUE)
  #  cat("Pieces2: ")
  #  for(e2 in pieces2){
  #    cat(e2)
  #  }
  #  cat("\n")
  
  
  if(length(pieces) == 8){
  
  y <- gsub("\\\\", "", pieces[2])
    dat <- y
    price <- pieces[4]
    eps <- pieces[6]
    pe <- pieces[8]
    
    cat("Date: ")
    cat(dat)
    pieces3 <- strsplit(dat, "-", fixed = TRUE)
    year <- as.numeric(gsub('"',"",pieces3[[1]][1]))
    month <- as.numeric(pieces3[[1]][2])
    day <- as.numeric(gsub('"',"",pieces3[[1]][3]))
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
    
    x <- c(year, month, day, price, eps, pe)
    #coll <- rbind(coll, x)
    return(x)
  }
  return(c(0, 0, 0, 0,0,0))
}


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
    chart <- getChart(text)
    cat("CHART")
    cat(chart)
    text2 <- parseChart(chart)
    results <<- matrix(nrow = length(text2), ncol = 9)
    i <- 0
    for(line in text2){
      i <- i + 1
      ro <- parseEPSChartLine(line)
      results[i,1] = ro[1]
      results[i,2] = ro[2]
      results[i,3] = ro[3]
      results[i,4] = ro[4]
      results[i,5] = ro[5]
      results[i,6] = ro[6]
    }
    
    results
    #return(text) 
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



