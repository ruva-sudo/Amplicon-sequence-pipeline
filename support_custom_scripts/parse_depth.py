#!/usr/bin/env python

#Import modules
import os
import glob
import zipfile
import html.parser
import pandas as pd

#Unzip table

def extract():
    table = 'table.qzv'
    with zipfile.ZipFile( table ) as zf:
        zf.extractall( 'temp' )
    
    #Create object with .html document
    os.chdir( 'temp' )
    path = glob.glob( '*' )
    os.chdir( ' '.join(map(str, path)))
    os.chdir( 'data' )
    file = glob.glob( 'index*' )
    html_doc = ' '.join( file )
    #print(html_doc)

    #html parsing with Pandas
    df_list = pd.read_html(html_doc)
    df_table = df_list[1]
    med = df_table.loc[2:2]
    median = med['Frequency']
    print(int(median))

extract()

