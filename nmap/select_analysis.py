# -*- coding: UTF-8 -*-
#============================================================================
# USAGE:
#   python select_analysis.py [$args]
#   ARGS:
#       -p,--port: port stat
#       -v,--vendor: vendor stat
#       -c,--cpe: cpe stat
# INFO:
#   FILE_INPUT: nmap_output.xml
#   NMAP_CMD: nmap -Pn -T4 -O -F min-parallelism 50 -iL router -oX result.xml
#   ANALAZY: port && vendor && cpe
# AUTHOR: 
#   kimii
# TIME:
#   2018/3/24    
#============================================================================
import argparse
import port
import vendor
import cpe
    
def parser_select():
    parser = argparse.ArgumentParser(description="Analyze results after using nmap to scan routers")
    parser.add_argument('--port','-p',action='store_true',help='to select port stat')
    parser.add_argument('--vendor','-v',action='store_true',help='to select vendor stat')
    parser.add_argument('--cpe','-c',action='store_true',help='to select cpe stat')
    args = parser.parse_args()                                                         # 将变量以标签-值的字典形式存入args字典
    if args.port:
        port.main()
    if args.vendor:
        vendor.main()
    if args.cpe:
        cpe.main()
        
def main():
    parser_select()
  
if __name__ == "__main__":
    main()

