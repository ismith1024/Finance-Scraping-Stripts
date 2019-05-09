import pandas as pd
from bs4 import BeautifulSoup
import requests

#database libraries
import sqlite3
from sqlite3 import Error

import re
import time
import datetime

sqlite_db = '/home/ian/Data/advfn.db'
yahoo_db =  '/home/ian/Data/yahoo.db'
database = sqlite3.connect(sqlite_db)
yahoo_database = sqlite3.connect(yahoo_db)
curs = database.cursor()
yahoo_curs = yahoo_database.cursor()

def get_yahoo_indicators(symbol):
    '''
    Gets p-e, eps, div and yield, beta from yahoo finance for a symbol
    and writes to the yahoo database
    '''
    print('Data for {0}.TO'.format(symbol))

    url = 'https://finance.yahoo.com/quote/{0}.TO/'.format(symbol)
    resp = requests.get(url)
    page = resp.text 

    soup = BeautifulSoup(page, 'html.parser')   
    
    #split the div and yeild string which is formatted 'xx.xx (yy.yy%)'
    div_raw = soup.find('td', attrs={'data-test': 'DIVIDEND_AND_YIELD-value'})
    dy = div_raw.string.split()
    if dy[0].strip() == 'N/A':
        div = 0
        div_yld = 0
    else:
        div = float(dy[0].strip().replace(',',''))
        div_yld = float(re.sub(r'[^\w.]', '', dy[1]))
    
    eps_raw = soup.find('td', attrs={'data-test': 'EPS_RATIO-value'}).string.strip()
    if eps_raw == 'N/A':
        eps = 0
    else:
        eps = float(eps_raw.replace(',',''))

    pe_raw = soup.find('td', attrs={'data-test': 'PE_RATIO-value'}).string.strip()
    if pe_raw == 'N/A':
        pe = 0
    else:
        pe = float(pe_raw.replace(',',''))

    beta_raw = soup.find('td', attrs={'data-test': 'BETA_3Y-value'}).string.strip()
    if beta_raw == 'N/A':
        beta = 0
    else:
        beta = float(beta_raw.replace(',',''))
    
    #<td class="Ta(end) Fw(600) Lh(14px)" data-test="EARNINGS_DATE-value"><span>May 28, 2019</span></td>
    #earn_date = soup.find('td', attrs={'data-test': 'EARNINGS_DATE-value'}).get_text().strip()    
    #if earn_date == 'N/A':
    #    earnings_date = 0
    #else:
    #    earnings_date = earn_date

    
    
    date_today = str(datetime.date.today())
    #one time only to run on weekend
    #date_today = '2019-05-03'


    print('  eps          {}'.format(eps))
    print('  p-e          {}'.format(pe))
    print('  div paid     {}'.format(div))
    print('  div yield    {}'.format(div_yld))
    print('  beta         {}'.format(beta))
    #print('  earn date    {}'.format(earnings_date))
    print('\n')
    
    yahoo_sql = '''INSERT OR IGNORE INTO yahoo_indicators(symbol, Date, pe, eps, div_payout, div_yield, beta) VALUES(?,?,?,?,?,?,?)'''
    #yahoo_sql_2 = '''INSERT OR IGNORE INTO earnings_dates(symbol, date) VALUES(?,?)'''
    job = (symbol, date_today, pe, eps, div, div_yld, beta)
    #job2 = (symbol, earnings_date)
    yahoo_curs.execute(yahoo_sql, job)
    #yahoo_curs.execute(yahoo_sql_2, job2)
    yahoo_database.commit()

def main():

    #get the symbols from the database
    curs.execute("select company_ticker from tsx_companies;")
    results = curs.fetchall()

    tickers = []

    '''Yahoo encodes income trusts with a hyphen
       Google uses a dot
       need to change AP.UN to AP-UN
    '''

    for res in results:
        symbol = res[0].replace('.','-')
        tickers.append(symbol)

    for symbol in tickers:
        get_yahoo_indicators(symbol)

if __name__ == '__main__':
    main()