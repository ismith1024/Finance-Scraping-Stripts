import pandas as pd
from bs4 import BeautifulSoup
import requests
import datetime
import re


#database libraries
import sqlite3
from sqlite3 import Error
import sqlalchemy
from sqlalchemy import create_engine

#Database Connection
tmx_db = '/home/ian/Data/tmx.db'
tmx_database = sqlite3.connect(tmx_db)
tmx_curs = tmx_database.cursor()

advfn_db = '/home/ian/Data/advfn.db'
advfn_database = sqlite3.connect(advfn_db)
advfn_curs = advfn_database.cursor()


def scrape_tmx(symbol):
	url = 'https://web.tmxmoney.com/earnings.php?qm_symbol={0}'.format(symbol)
	
	#get the page from the URL
	resp = requests.get(url)
	page = resp.text 
	
	#parse the HTML using Beautiful Soup
	soup = BeautifulSoup(page, 'html.parser')

	#inspect the rows of the table 'earningstable'
	table = soup.find('div', attrs = {'class': 'earningstable'})

	if table is None:
		print('No data for {0}'.format(symbol))
		return

	rows = table.findChildren('td')
	
	#columns are not named, so count off every five table divisions
	for index, val in enumerate(rows):
		col_num = index%5
		
		if col_num == 0:
			pass
		elif col_num == 1:
			parsed_date = datetime.datetime.strptime(val.text.strip(), '%m/%d/%y').strftime("%Y-%m-%d")  
			print('Data for {0} -- {1}'.format(symbol, parsed_date))

		elif col_num == 2:
			if val.text.strip() == '--':
				eps = 0.0
			else:
				eps = float(val.text.strip())
			print('  eps          {0}'.format(str(eps)))

		elif col_num == 3:
			consensus_raw = val.text.strip()
			#missing data encoded as '--'
			if consensus_raw == '--':
				consensus = 0.0
			else:
				consensus = float(consensus_raw)
			print('  consensus    {0}'.format(str(consensus)))

		else:
			surprise_raw = val.text.strip().split()
			#missing data encoded as '-- (--)'
			if surprise_raw[1] == '(--)':
				surprise = 0.0
			else:
				#surprise encoded as 'nn (nn.nn%)'
				#storing percent since this is earnings-independent
				surprise = float(re.sub(r'[^\w.-]', '', surprise_raw[1]))
			print('  surprise     {0}'.format(str(surprise)))			

			sql = '''INSERT OR IGNORE INTO tmx_earnings(symbol, date, eps, consensus_eps, surprise) VALUES(?,?,?,?,?)'''
			job =  (symbol, parsed_date, eps, consensus, surprise)
			tmx_curs.execute(sql, job)        
	
	print('\n')
	tmx_database.commit()
    
def main():

    #get the symbols from the database
    advfn_curs.execute("select company_ticker from tsx_companies;")
    results = advfn_curs.fetchall()

    tickers = []

	#tmx uses google nomenclature (BBD.B as opposed to BBD-B)
	#so the symbols in advfn are correct
    for res in results:
    	tickers.append(res[0])

    last_good = 'WN'
    have_data = True

    for symbol in tickers:
    	if symbol == last_good:
    		have_data = False
		
    	if not have_data:
        	scrape_tmx(symbol)

if __name__ == '__main__':
    main()