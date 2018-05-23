#! /bin/bash
# basic_stat.sh : to give a basic stat of the geo file 
# INPUT:
#	geo file
# OUTPUT:
#	stat e.g. node_num edge_num rtrnode_num rtredge_num inedge_num inrtredge_num

# generate iface_file
geo2iface(){
test $# -lt 1 && echo 'geo2iface $prefix.geo' && exit

input=$1
prefix=$(echo $input)

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
geo2node(){
test $# -lt 1 && echo 'geo2node $prefix.geo' && exit

input=$1
prefix=$(echo $input)

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

stat(){
nn=`cat $3 | wc -l`
rnn=`cat $2 | wc -l`
en=`cat $1 | wc -l`
ren=$(cat $2 <(echo '#') $1 | python <(
cat <<"EOF"
ifaces=set()
while True:
  l=raw_input().strip()
  if l[0] == '#':
    break
  ifaces.add(l)
ren=0 
while True:
  try:
    l=raw_input().strip()
  except:
    break
  f=l.split()
  if f[1] in ifaces:
    ren+=1
print ren
EOF
)
)
echo "nn rnn en ren"
echo $nn $rnn $en $ren
}

area_stat(){
geo=$1; ifaces=$2; nodes=$3; area=$4
nn=`cat $nodes | wc -l`
rnn=`cat $ifaces | wc -l`
en=`cat $geo | wc -l`
ren_ien_iren=$(cat $ifaces <(echo '#') $geo | python <(
cat <<"EOF"
ifaces=set()
while True:
  l=raw_input().strip()
  if l[0] == '#':
    break
  ifaces.add(l)
ren=0 
ien=0
iren=0
while True:
  try:
    l=raw_input().strip()
  except:
    break
  f=l.split()
  if f[1] in ifaces:
    ren+=1
  if f[-1] == f[-2]:
    ien+=1
    if f[1] in ifaces:
      iren+=1 
print str(ren)+' '+str(ien)+' '+str(iren)
EOF
)
)
echo $area $nn $rnn $en $ren_ien_iren
}

area_split(){
al=$( #area list
cat <<"EOF"
US
CN
KR
JP
TW
HK
IR
PK
SY
IQ
AF
EOF
)
mkdir -p .tmp/; cd .tmp/
echo "area nn rnn en ren ien iren"
for a in ${al[@]}; do
  geo=$1
  cat ../$geo | grep $a > $geo.$a
  geo2iface $geo.$a
  geo2node $geo.$a
  area_stat $geo.$a $geo.$a.ifaces $geo.$a.nodes $a
done
cd ../
}

area_total(){
stat=$1
cat $stat | python <(
cat <<"EOF"
data=[]
while True:
  try:
    l=raw_input().strip()
  except:
    break
  f=l.split()
  data.append(f)
out=[0]*7
out[0]="11"
for i in range(1,7):
  for j in range(1,12):
    out[i]+=int(data[j][i])
for o in out:
  print o,
EOF
) >> $stat
cat $stat | awk 'BEGIN{c=0;} {for(i=1;i<=NF;i++) {num[c,i] = $i;} c++;} \
 END{ for(i=1;i<=NF;i++){str=""; for(j=0;j<NR;j++){ if(j>0){str = str" "} \
str= str""num[j,i]}printf("%s\n", str)} }' | tr " " "," >area.csv
}

usage(){
echo './*.sh [$cmd] [$args]'
echo 'cmd:'
echo '  geo_stat | area_stat | area_total'
echo 'args:'
echo '  <$geo_file_path>'
echo 'func:'
echo '  analyze the geo file to give a stat'
}

test $# -lt 2 && usage && exit
cmd=$1
case $cmd in
  "geo_stat")
    geo2iface $2
    geo2node $2
    stat $2 $2.ifaces $2.nodes > geo.stat
    ;;
  "area_stat")
    area_split $2 > area.stat
    ;;
  "area_total")
    area_total area.stat
    ;;
  *)
    usage
    exit
    ;;
esac

# TODO
## geo2iface --> area_geo2iface
## geo2node  --> area_geo2node
