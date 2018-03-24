# -*- coding: UTF-8 -*-
from pymongo import MongoClient
from pyecharts import Bar
import os
CURRENT_PATH = os.getcwd() 

# input config
MONGODB_DB_URL = "mongodb://localhost:27017/"
MONGODB_DB_NAME = "test"
MONGODB_DB_CC_NAME = "router"

# output config 
VENDOR_STAT_FILE_PATH = CURRENT_PATH+'/stat/'+'vendor_freq'
VENDOR_TOP10_PIC_PATH = CURRENT_PATH+'/pic/'+'vendor_top10.html'

# db connect
def connect():
    client = MongoClient(MONGODB_DB_URL)
    db = client[MONGODB_DB_NAME]
    return db
    
def vendor_stat(db):
    project = {"$project":{"vendor":"$os.osmatch.osclass.@vendor","_id":0}}
    group = {"$group":{"_id":"$vendor","count":{'$sum':1}}}
    # todo:del sort
    sort = {"$sort":{"count":-1,"_id":-1}}
    pipeline = [project,group,sort]
    vendor_list = list(db[MONGODB_DB_CC_NAME].aggregate(pipeline))
    # three types: list[(list or str),...],unicode,None
    for i in range(len(vendor_list)):
        if isinstance(vendor_list[i][u'_id'],list):
            if isinstance(vendor_list[i][u'_id'][0],list):
                vendor_list[i][u'_id'] = vendor_list[i][u'_id'][0][0]
            else:
                vendor_list[i][u'_id'] = vendor_list[i][u'_id'][0]  
    vendor_set = {}
    for v in vendor_list:
        if(vendor_set.has_key(v[u'_id'])):
            vendor_set[v[u'_id']] += v[u'count']
        else:
            vendor_set[v[u'_id']] = v[u'count']
    # sorted return a list of tuple
    vendor_sorted = sorted(vendor_set.items(),key=lambda item:item[1],reverse=True)
    return vendor_sorted

def vendor_stat_file(vendor_sorted):
    with open(VENDOR_STAT_FILE_PATH,'w') as f:
        for v in vendor_sorted:
            f.write(str(v[0])+' '+str(v[1])+'\n')

def generate_top10_pic(top10):
    bar = Bar("运营商 TOP 10")
    x,y = [],[]
    for v in top10:
        x.append(v[0])
        y.append(int(v[1]))
    bar.add('频率',x,y)
    bar.render(VENDOR_TOP10_PIC_PATH)
            
def main():
    db = connect()
    vendor_sorted = vendor_stat(db)
    vendor_stat_file(vendor_sorted)
    # vendor_sorted[0] is (None,count)
    generate_top10_pic(vendor_sorted[1:11])
    
    
if __name__ == "__main__":
    main()


