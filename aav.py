import requests
import pandas as pd
import sqlite3
import json
from sqlite3 import Error
import sqlalchemy
from sqlalchemy import create_engine
import time


api_key = 'CTECN021MT4UQAJ2'
#sqlite_db = '/home/ian/Data/yahoo.db'
sqlite_db = '/home/ian/Data/tsx_analysis.db'
database = sqlite3.connect(sqlite_db)
curs = database.cursor()

#################
## Gets the daily time series data in JSON format from alphavantage for the symbol selected
##  In: the ticker symbol in Yahoo notation (no exchange)
##  Out: Writes time sereis to SQLite database
def get_daily_data(sym):
    #alphavantage uses a '-' to separate share classes or designate a unit, yahoo uses a '.'
    symbol = sym.replace('.','-')
    url_to_get = 'https://www.alphavantage.co/query?function=TIME_SERIES_DAILY&symbol={}.TO&apikey=CTECN021MT4UQAJ2'.format(symbol)
    resp = requests.get(url_to_get)
    json_data = resp.text 
    time_ser_data = json.loads(json_data)

    #for valid response
    if 'Time Series (Daily)' in time_ser_data:
        df = pd.DataFrame.from_dict(time_ser_data['Time Series (Daily)']).T
        df['symbol'] = symbol
        df['Date'] = df.index
        df['Adj Close'] = ''
        df.columns = ['Open','High', 'Low','Close','Volume', 'symbol','Date', 'Adj Close']
        
        for index, row in df.iterrows():
            sql = '''INSERT OR IGNORE INTO aav_prices(symbol, Date) VALUES (?, ?)'''
            job = (symbol, row['Date'])
            #print(sql + str(job))
            curs.execute(sql, job)
            database.commit()

            sql = '''UPDATE aav_prices SET Open = ?, High = ?, Low = ?, Close = ?, Volume = ? WHERE symbol = ? AND Date = ?'''
            job = (row['Open'], row['High'], row['Low'], row['Close'], row['Volume'], symbol, row['Date'])
            curs.execute(sql, job)
            database.commit()



def main():

    #get the symbols and max index from the database
    #engine = create_engine('sqlite:////home/ian/Data/advfn.db')
    engine = create_engine('sqlite:////home/ian/Data/tsx_analysis.db')
    symbol_df = pd.read_sql_table('tsx_companies', engine)

    for index, symbol in enumerate(symbol_df['company_ticker']):
        #Need to sleep for a minute after five scrapes - API rules
        if index %5 == 0:
            print('(need to wait 1 minute)')
            time.sleep(60)
        print('Scrape : {}'.format(symbol))
        get_daily_data(symbol)
        print('  .. done!')

if __name__ == '__main__':
    main()