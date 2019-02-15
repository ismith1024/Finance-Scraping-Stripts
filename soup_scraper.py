import pandas as pd
from bs4 import BeautifulSoup
import requests
import sqlite3

sqlite_db = 'hi.db'
database = sqlite3.connect(sqlite_db)
curs = database.cursor()

tickers = curs.get_all('SELECT * FROM TICKERS')

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
url_to_test2 = 'https://ca.advfn.com/stock-market/TSX/BNS/financials?btn=istart_date&istart_date=69&mode=quarterly_reports'

def get_quarter_report(url):

    resp = requests.get(url)
    page = resp.text 
    soup = BeautifulSoup(page, 'html.parser')

    row_heads = soup.find_all('td', attrs={'class': 's', 'align' : 'left'})
    row_data = soup.find_all('td', attrs={'class': 's', 'align' : 'right'})

    for index, val in enumerate(row_heads):
        print_str = str(val.text.strip()) + ' : '
        for index2 in range(5):
            print_str += ' -- ' + str(row_data[5*index + index2].text.strip())

        print(print_str)

    ret = print_str

    return ret

print("   SCRAPE CURRENT FINANCIALS")
get_current_financials(url_to_get)
print("   SCRAPE A QUARTER")
get_quarter_report(url_to_test2)



