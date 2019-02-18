import pandas as pd
from bs4 import BeautifulSoup
import requests


#database libraries
import sqlite3
from sqlite3 import Error
import sqlalchemy
from sqlalchemy import create_engine

sqlite_db = '/home/ian/Data/advfn.db'
database = sqlite3.connect(sqlite_db)
curs = database.cursor()

################### Get all column headers
## Utility function to find all items for all quarterly reports
def get_column_headers():

    curs.execute("select company_ticker from tsx_companies;")
    results = curs.fetchall()
    
    tickers = []

    for res in results:
        tickers.append(res[0])

    column_headers = set()
    #for index, row in df.head(2).iterrows():
    
    for ticker in tickers:
        print("Check: " + ticker)#row['company_ticker'])
        url = 'https://ca.advfn.com/stock-market/TSX/' + ticker + '/financials?btn=istart_date&istart_date=1&mode=quarterly_reports'

        resp = requests.get(url)
        page = resp.text 
        soup = BeautifulSoup(page, 'html.parser')

        row_heads = soup.find_all('td', attrs={'class': 's', 'align' : 'left'})
        
        for tag in row_heads:
            col_header = str(tag.text.strip())            
            column_headers.add(col_header)

    for header in column_headers:
        sql = '''INSERT INTO column_headers(header) VALUES(?)'''
        curs.execute(sql, (header,))
    
    database.commit()


###################
## In: a symbol to check
## Out: the greatest end_date from the company's quarterly report page
## Used to determine how many quarterly report pages need to be scraped
def get_quarter_indices(symbol):
    url_to_get = 'https://ca.advfn.com/stock-market/TSX/' + symbol + '/financials?btn=istart_date&istart_date=1&mode=quarterly_reports'

    resp = requests.get(url_to_get)
    page = resp.text 
    soup = BeautifulSoup(page, 'html.parser')

    #start_dates = [opt["value"] for opt in soup.select("#istart_dateid")]
    print('Start dates:')
    
    #options = soup.find_all('option')
    options = soup.select('option[value]')
    values = [item.get('value') for item in options]
    values_numeric = []

    for val in values:
        try:
            value = int(val)
            values_numeric.append(value)
        except ValueError:
            pass
    
    max_value = max(values_numeric)
    return max_value

################### Get present-day financials

url_to_get = 'https://ca.advfn.com/stock-market/TSX/BNS/financials'

def get_current_financials(url):

    resp = requests.get(url)

    page = resp.text 

    soup = BeautifulSoup(page, 'html.parser')

    #table_keys = []
    #table_vals = []

    #for i in soup.find_all('td', attrs={'class': 's', 'align' : 'left'}):
    #       if i.find(attrs = {})

    table_keys = soup.find_all('td', attrs={'class': 's', 'align' : 'left'})
    table_vals = soup.find_all('td', attrs={'class': 's', 'align' : 'right'})

    table_data = {}

    for index, val in enumerate(table_keys):
       
        printVal = str(val.text.strip()) + ' : '
        #if index in enumerate(table_vals):
        printVal += str(table_vals[index].text.strip())
        #print(printVal)
        table_data[val.text.strip()] = table_vals[index].text.strip()

    print(str(table_data))

    ret = str(table_data)

    return ret

####################### Get a quarterly report
## TODO: need to count the cells with align:right
## PageIndex: starts at 1 (the earliest quarterly report) and increases
##            database intializes last_report_index to 0

url_to_test2 = 'https://ca.advfn.com/stock-market/TSX/BNS/financials?btn=istart_date&istart_date=69&mode=quarterly_reports'

url_to_test3 = 'https://ca.advfn.com/stock-market/TSX/BNS/financials?btn=istart_date&istart_date=92&mode=quarterly_reports'


def get_quarter_report(symbol, index):

    url = 'https://ca.advfn.com/stock-market/TSX/' + symbol + '/financials?btn=istart_date&istart_date=' + str(index) + '&mode=quarterly_reports'
 
    resp = requests.get(url)
    page = resp.text 
    soup = BeautifulSoup(page, 'html.parser')

    row_heads = soup.find_all('td', attrs={'class': 's', 'align' : 'left'})
    row_data = soup.find_all('td', attrs={'class': 's', 'align' : 'right'})

    #print('Row headers: ' + str(len(row_heads)))
    #print('Row data: ' + str(len(row_data)))

    num_cols = int(len(row_data) / len(row_heads))
    print('Found ' + str(num_cols) + ' columns')
    
    #extract dates from first row
    #and set up a null quarterly report
    dates = []
    for i in range(num_cols):
        dates.append(row_data[i].text.strip())
        sql = '''INSERT OR IGNORE INTO quarterly_reports(company_ticker, report_date) VALUES(?,?)'''
        job = (symbol, row_data[i].text.strip())
        print('Symbol: ' + symbol + ' date: ' + str(row_data[i].text.strip()))
        curs.execute(sql, job)

    database.commit()

    for index, val in enumerate(row_heads):
        
        sql_col = val.text.strip();

        print_str = str(val.text.strip()) + ' : '
        for index2 in range(num_cols):            
            curr_date = dates[index2];
            curr_val = row_data[num_cols*index + index2].text.strip()
            curs.execute("UPDATE quarterly_reports SET `{cn}` = ? WHERE company_ticker = ? AND report_date = ?;".format(cn=sql_col), (curr_val, symbol, curr_date))
    
    database.commit()

    return True

def main():

    #get the symbols and max index from the database
    engine = create_engine('sqlite:////home/ian/Data/advfn.db')
    symbol_df = pd.read_sql_table('tsx_companies', engine)

    #get_quarter_report('BNS', 1)

    for index, row in symbol_df.iterrows():
        previous_max = row['last_report_index']
        symbol = row['company_ticker']
        new_max = get_quarter_indices(symbol)

        print('Data for symbol: ' + symbol)

        if new_max > previous_max:
            #get quarterly report data for the pages and add to the database
            for option in range(previous_max, new_max + 1):
                print('  new data for option ' + str(option))
                get_quarter_report(symbol, option)

            #write the new_max to the database
            sql = '''UPDATE tsx_companies SET last_report_index = ? WHERE company_ticker = ?'''
            job = (new_max, symbol)
            curs.execute(sql, job)
            database.commit()

#get_quarter_indices('BNS')
#get_column_headers()

#print("   SCRAPE CURRENT FINANCIALS")
#get_current_financials(url_to_get)
#print("   SCRAPE A QUARTER")
#get_quarter_report(url_to_test2)



if __name__ == '__main__':
    main()