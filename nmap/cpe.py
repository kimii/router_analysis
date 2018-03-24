# -*- coding: UTF-8 -*-
from pymongo import MongoClient
from pyecharts import Bar,Grid
import os
CURRENT_PATH = os.getcwd() 

# input config
MONGODB_DB_URL = "mongodb://localhost:27017/"
MONGODB_DB_NAME = "test"
MONGODB_DB_CC_NAME = "router"

# output config 
CPE_STAT_FILE_PATH = CURRENT_PATH+'/stat/'+'cpe_freq'
CPE_TOP10_PIC_PATH = CURRENT_PATH+'/pic/'+'cpe_top10.html'

# db connect
def connect():
    client = MongoClient(MONGODB_DB_URL)
    db = client[MONGODB_DB_NAME]
    return db

def cpe_stat(db):
    project = {"$project":{"cpe":"$os.osmatch.osclass.cpe","_id":0}}
    group = {"$group":{"_id":"$cpe","count":{'$sum':1}}}
    pipeline = [project,group]
    cpe_list = list(db[MONGODB_DB_CC_NAME].aggregate(pipeline))
    # select 1st group not 1st one
    for i in range(len(cpe_list)):
        if isinstance(cpe_list[i][u'_id'],list):
            if isinstance(cpe_list[i][u'_id'][0],list):
                if isinstance(cpe_list[i][u'_id'][0][0],list):
                    cpe_list[i][u'_id'] = tuple(cpe_list[i][u'_id'][0][0])          
                else:
                    cpe_list[i][u'_id'] = tuple(cpe_list[i][u'_id'][0])
                    for j in range(len(cpe_list[i][u'_id'])):
                        if isinstance(cpe_list[i][u'_id'][j],list):
                            if(j==0):
                                cpe_list[i][u'_id'] = tuple(cpe_list[i][u'_id'][0])
                            else:
                                cpe_list[i][u'_id'] = cpe_list[i][u'_id'][0]
                    
            else:
                cpe_list[i][u'_id'] = cpe_list[i][u'_id'][0]
    cpe_set = {}
    for v in cpe_list:
        try:
            if cpe_set.has_key(v[u'_id']):
                cpe_set[v[u'_id']] += v[u'count']
            else:
                cpe_set[v[u'_id']] = v[u'count']
        except:
            print v[u'_id']
            print type(v[u'_id'])
    cpe_sorted = sorted(cpe_set.items(),key=lambda item:item[1],reverse=True)
    return cpe_sorted 

def cpe_stat_file(cpe_sorted):
    with open(CPE_STAT_FILE_PATH,'w') as f:
        for v in cpe_sorted:
            f.write(str(v[0])+' '+str(v[1])+'\n')

def generate_top10_pic(top10):
    bar = Bar("CPE TOP 10")
    x,y = [],[]
    for v in top10:
        x.append(v[0])
        y.append(int(v[1]))
    # to solve problem that x_label's cpe is too long
    bar.add('频率',x,y,xaxis_interval=0,xaxis_rotate=90,is_convert=True,is_yaxis_inverse=True)
    grid = Grid()
    grid.add(bar,grid_left="50%")
    grid.render(CPE_TOP10_PIC_PATH)
            
def main():
    db = connect()
    cpe_sorted = cpe_stat(db)
    cpe_stat_file(cpe_sorted)
    # cpe_sorted[0] is (None,count)
    generate_top10_pic(cpe_sorted[1:11])
    
    
if __name__ == "__main__":
    main()

