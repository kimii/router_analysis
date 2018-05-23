#! /bin/bash
# analysis.py -- to analyze the warts file 
# OUTPUT:
#	link_file:1.in 2.out 3.is_dest 4.star 5.delay 6.freq 7.ttl 8.monitor
#	    4. the number of anonymous (*) hops inbetween, e.g., 0 for directed link
#       5. the minimal delay in ms > 0, e.g., 10
#       6. the cumulative frequence of link observed, e.g., 5000
#       7. the minimal TTL of the ingress interface, e.g., 7
#

#OUTPUT 5
delay(){
input=$1
prefix=$(echo $input | sed 's/\.links$//')

cat $input | python <(
cat << "END"
out={}
while True:
  try:
    line=raw_input()
  except:
    break
  fields = line.split()
  delay = int(float(fields[4]))
  if not out.has_key(delay):
    out[delay] = 1
  else:
    out[delay] += 1
for k,v in out.items():
    print str(k)+" "+str(v)
END
) | sort -n -k 1 > delay.stat
}

# OUTPUT 4
star(){
input=$1
prefix=$(echo $input | sed 's/\.links$//')

cat $input | python <(
cat << "END"
out={}
while True:
  try:
    line=raw_input()
  except:
    break
  fields = line.split()
  if not out.has_key(fields[3]):
    out[fields[3]] = 1
  else:
    out[fields[3]] += 1
for k,v in out.items():
    print str(k)+" "+str(v)
END
) | sort -n -k 1 > star.stat
}

# OUTPUT 7
ttl(){
input=$1
prefix=$(echo $input | sed 's/\.links$//')

cat $input | python <(
cat << "END"
out={}
while True:
  try:
    line=raw_input()
  except:
    break
  fields = line.split()
  if not out.has_key(fields[6]):
    out[fields[6]] = 1
  else:
    out[fields[6]] += 1
for k,v in out.items():
    print str(k)+" "+str(v)
END
) | sort -n -k 1 > ttl.stat
}

# OUTPUT 6
freq(){
input=$1
prefix=$(echo $input | sed 's/\.links$//')

cat $input | python <(
cat << "END"
out={}
while True:
  try:
    line=raw_input()
  except:
    break
  fields = line.split()
  if not out.has_key(fields[5]):
    out[fields[5]] = 1
  else:
    out[fields[5]] += 1
for k,v in out.items():
    print str(k)+" "+str(v)
END
) | sort -n -k 1 > freq.stat
}

# generate iface_file
link2iface(){
test $# -lt 1 && echo 'link2iface $prefix.links' && exit

input=$1
prefix=$(echo $input | sed 's/\.links$//')

cat $input | python <(
cat << "END"
out={}
while True:
  try:
    line=raw_input()
  except:
    break
  fields = line.split()
  print fields[0] # 'from' must be a router iface
  if not out.has_key(fields[1]):
    out[fields[1]] = fields[2]
  elif fields[2] == "N":
    out[fields[1]] = "N"
for k,v in out.items():
  if v == "N":
    print k
END
) | sort | uniq >$prefix.ifaces
#output_file_path: $prefix.ifaces
}

# generate 
# replace:cat $prefix.links | cut -d " " -f 1-2 | tr " " "\n"| sort | uniq > $prefix.nodes
link2node(){
test $# -lt 1 && echo 'link2node $prefix.links' && exit

input=$1
prefix=$(echo $input | sed 's/\.links$//')

cat $input | python <(
cat << "END"
out={}
while True:
  try:
    line=raw_input()
  except:
    break
  fields = line.split()
  print fields[0] # 'from' must be a router iface
  print fields[1]
END
) | sort | uniq >$prefix.nodes
}

usage(){
echo './*.sh [$args]'
echo 'args:'
echo '  <$warts_file_path>'
echo 'func:'
echo '  analyze the warts file to give a stat'
}

test $# -lt 1 && usage && exit
prefix=$(echo $1 | sed 's/\.warts$//')
# cal num of traceroute
#sc_warts2text $1 > $prefix.text
echo '[traceroute_stats]'
echo 'traceroute_num:	'$(cat $prefix.text | grep traceroute|wc -l)
#cat $prefix.text | perl trace2link.pl -p $prefix - > $prefix.links
#link2iface $prefix.links
#link2node $prefix.links
echo '[node_stats]'
all_num=`cat $prefix.nodes | wc -l`
echo "nodes_total_num:	"${all_num}
not_edge=`cat $prefix.ifaces | wc -l`
echo "not_edeg_nodes_num:	"${not_edge}
edge=$[all_num-not_edge]
echo "edge_num:	"${edge}
echo '[edge_stats]'
all_edges=`cat $prefix.links | wc -l`
echo 'edges_total_num:	'${all_edges}
rr_edges=`cat $prefix.links|awk '$3=="N" {print $1" "$2}'|wc -l`
echo 'rr_edges_num:	'${rr_edges}
not_rr_edges=$[all_edges-rr_edges]
echo 'not_rr_edges:	'${not_rr_edges}
echo "generate_stat ttl freq star delay"
ttl $prefix.links
freq $prefix.links
star $prefix.links
delay $prefix.links
