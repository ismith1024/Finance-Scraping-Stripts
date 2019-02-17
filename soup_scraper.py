import pandas as pd
from bs4 import BeautifulSoup
import requests


#database libraries
import sqlite3
from sqlite3 import Error
import sqlalchemy
from sqlalchemy import create_engine


'''
engine = create_engine('sqlite:////home/ian/Data/advfn.db')
df = pd.read_sql_table('tsx_companies', engine)
'''

#print(df)
#tickers = curs.get_all('SELECT * FROM TICKERS')

################### Get all column headers
## Utility function to find all items for all quarterly reports
def get_column_headers():

    sqlite_db = '/home/ian/Data/advfn.db'
    database = sqlite3.connect(sqlite_db)
    curs = database.cursor()

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


def get_quarter_report(url):

    resp = requests.get(url)
    page = resp.text 
    soup = BeautifulSoup(page, 'html.parser')

    row_heads = soup.find_all('td', attrs={'class': 's', 'align' : 'left'})
    row_data = soup.find_all('td', attrs={'class': 's', 'align' : 'right'})

    #print('Row headers: ' + str(len(row_heads)))
    #print('Row data: ' + str(len(row_data)))

    num_cols = int(len(row_data) / len(row_heads))
    print('Found ' + str(num_cols) + ' columns')
    
    for index, val in enumerate(row_heads):
        print_str = str(val.text.strip()) + ' : '
        for index2 in range(num_cols):
            print_str += ' -- ' + str(row_data[num_cols*index + index2].text.strip())

        print(print_str)

    ret = print_str
    
    return ret

get_column_headers()

#print("   SCRAPE CURRENT FINANCIALS")
#get_current_financials(url_to_get)
#print("   SCRAPE A QUARTER")
#get_quarter_report(url_to_test2)



