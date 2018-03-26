#! /bin/bash
#SUB
union(){
python <(
cat << "EOF"
#sub
def find(x):
  if not sets.has_key(x):
    sets[x] = [x,0]
    return x
  
  if sets[x][0] == x:
    return x
  else:
    return find(sets[x][0])

def union(x,y):
  rx = find(x)
  ry = find(y)
  if rx == ry:
    return
  if sets[rx][1] < sets[ry][1]:
    sets[rx][0] = ry
  elif sets[rx][1] > sets[ry][1]:
    sets[ry][0] = rx
  else:
    sets[ry][0] = rx
    sets[rx][1] += 1

#main
sets={}
while True:
  try:
    line=raw_input().strip()
  except:
    break
  f=line.split()
  union(f[0],f[1])

#out
d={}
for k in sets.keys():
  r=find(k)
  if not d.has_key(r):
    d[r] = [k]
  else:
    d[r].append(k)
for v in d.values():
  print ' '.join(sorted(v))
EOF
)
}
aliases(){
python <(
cat << "EOF"
sets={}
while True:
  try:
    line=raw_input().strip()
  except:
    break
  n=len(line.split())
  if not sets.has_key(n):
    sets[n]=1
  else:
    sets[n]+=1
for k,v in sets.items():
  print str(k)+' '+str(v)
EOF
)
}

#MAIN
usage(){
echo './*.sh [$args]'
echo 'args:'
echo '  <$iffinder_file_path>'
echo 'func:'
echo '  analyze iffinder_file to give a stat'
}

test $# -lt 1 && usage && exit  
#eg: $1==20171007.22110.iffinder.out 
cat $1 | awk '$6=="D" {print $1" "$2}' | tee $1.aliases | union | aliases | sort -n -k1 | uniq > aliases.stat
cat aliases.stat | python <(
cat << "EOF"
n = 0
while True:
  try:
    line=raw_input()
  except:
    break
  n+=int(line.split()[1])
print "routers_num:"+str(n)  
EOF
)>> aliases.stat
echo "aliases_num:"$(cat $1.aliases|wc -l) >> aliases.stat



#eg: $1==20171007.22110.iffinder.aliase
#cat $1 | union | aliases | sort -n -k1 | uniq > aliases.stat

