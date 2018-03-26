# router_analysis
## /nmap
	python select_analysis.py -h
	usage: select_analysis.py [-h] [--port] [--vendor] [--cpe]
	
	Analyze results after using nmap to scan routers
	
	optional arguments:
	  -h, --help    show this help message and exit
	  --port, -p    to select port stat
	  --vendor, -v  to select vendor stat
	  --cpe, -c     to select cpe stat
## /topo
### /iffinder
	$./aliase_analysis.sh 
	./*.sh [$args]
	args:
	  <$iffinder_file_path>
	func:
	  analyze iffinder_file to give a stat

### /warts
	$./analysis.sh 
	./*.sh [$args]
	args:
	  <$warts_file_path>
	func:
	  analyze the warts file to give a stat
