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
IP_STAT = 0
PORT_OPEN_STAT_FILE_PATH = CURRENT_PATH+'/stat/'+'port_open_freq'
PORT_OPEN_TOP10_PIC_PATH = CURRENT_PATH+'/pic/'+'port_open_top10.html'

# db connect
def connect():
    client = MongoClient(MONGODB_DB_URL)
    db = client[MONGODB_DB_NAME]
    return db
    
def ip_stat(db):
    return db[MONGODB_DB_CC_NAME].find().count()

def port_open_stat(db):
    project = {"$project":{"port":"$ports.port.@portid","_id":0,"state":"$ports.port.state.@state"}}
    group = {"$group":{"_id":{"port":"$port","st":"$state"},"count":{'$sum':1}}}
    pipeline = [project,group]
    pp_list = list(db[MONGODB_DB_CC_NAME].aggregate(pipeline))
    pp_set = {}
    for i in range(len(pp_list)):
        if pp_list[i][u'_id'].has_key(u'port'):
            if isinstance(pp_list[i][u'_id'][u'port'],list):
                for j in range(len(pp_list[i][u'_id'][u'port'])):
                    if pp_list[i][u'_id'][u'st'][j]==u'open':
                        if pp_set.has_key(pp_list[i][u'_id'][u'port'][j]):
                            pp_set[pp_list[i][u'_id'][u'port'][j]] += pp_list[i][u'count']
                        else:
                            pp_set[pp_list[i][u'_id'][u'port'][j]] = pp_list[i][u'count']
            else:
                if pp_list[i][u'_id'][u'st']==u'open':
                    if pp_set.has_key(pp_list[i][u'_id'][u'port']):
                        pp_set[pp_list[i][u'_id'][u'port']] += pp_list[i][u'count']
                    else:
                        pp_set[pp_list[i][u'_id'][u'port']] = pp_list[i][u'count']
                
    pp_sorted = sorted(pp_set.items(),key=lambda item:item[1],reverse=True)          
    return pp_sorted

def port_open_stat_file(pp_sorted):
    with open(PORT_OPEN_STAT_FILE_PATH,'w') as f:
        for v in pp_sorted:
            f.write(str(v[0])+' '+str(v[1])+'\n')   
            
def generate_top10_pic(top10,path):
    bar = Bar("开放端口 TOP 10")
    x,y = [],[]
    for v in top10:
        x.append(v[0])
        y.append(int(v[1]))
    bar.add('频率',x,y)
    bar.render(path)
            
def main():
    db = connect()
    IP_STAT = ip_stat(db)
    print('IP_TOTAL is %s' % str(IP_STAT))
    pp_sorted = port_open_stat(db)
    port_open_stat_file(pp_sorted)
    generate_top10_pic(pp_sorted[:10],PORT_OPEN_TOP10_PIC_PATH)
  
if __name__ == "__main__":
    main()


    
 # todo
 # 1.*.cfg
 # 2.port: def -> class