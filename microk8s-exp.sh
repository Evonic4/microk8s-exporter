#!/bin/bash
export PATH="$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin"
ver="v0.2"
fhome=/usr/share/microk8s-exporter/
export KUBECONFIG=$fhome"k8sconf.txt"
cd $fhome

function init() 
{
logger "Init"
ne_port=$(sed -n 1"p" $fhome"sett.conf" | tr -d '\r')
job=$(sed -n 2"p" $fhome"sett.conf" | tr -d '\r')
sec4=$(sed -n 3"p" $fhome"sett.conf" | tr -d '\r')

logger "Init ne_port="$ne_port
logger "Init job="$job
logger "Init sec4="$sec4
}


function logger()
{
local date1=$(date '+ %Y-%m-%d %H:%M:%S')
echo $date1" microk8s-exporter start: "$1
}


zapushgateway ()
{
logger "--------zapushgateway start-------------"$i2
logger "top_pod ns="$ns
logger "top_pod pod="$pod
logger "top_pod cpu="$cpu
logger "top_pod mem="$mem

#push_time_seconds{instance="",job="microk8s",ns="aurora",pod="gds-integration-6684cd98b5-6kz9g"} 1.7255590571115856e+09
#echo "top_cpu_usage "$cpu | curl -m $max_time_wpg --data-binary @- "http://"$pushg_ip":"$pushg_port"/metrics/job/"$job"/ns/"$ns"/pod/"$pod
#echo "top_mem_usage "$mem | curl -m $max_time_wpg --data-binary @- "http://"$pushg_ip":"$pushg_port"/metrics/job/"$job"/ns/"$ns"/pod/"$pod

echo "top_cpu_usage{job=\""$job"\",ns=\""$ns"\",pod=\""$pod"\"} "$cpu >> $fhome"ne2/"$ns".prom"
echo "top_mem_usage{job=\""$job"\",ns=\""$ns"\",pod=\""$pod"\"} "$mem >> $fhome"ne2/"$ns".prom"

}


to_ns ()
{
logger "to_ns start"

rm $fhome"top"
mkdir $fhome"top"

for (( i1=2;i1<=$str_col1;i1++)); do
	test=$(sed -n $i1"p" $fhome"ns1.txt" | tr -d '\r')	#ns
	logger "to_ns test="$test
	to_pods;
done
}


to_pods ()
{
logger "to_pods start"
kubectl get po -n $test | awk '{print $1}' > $fhome"po1.txt"
str_col2=$(grep -c '' $fhome"po1.txt")
logger "to_pods str_col2="$str_col2
if [ "$str_col2" -gt "1" ]; then
	to_pods2;
fi

}


to_pods2 ()
{
logger "to_pods2 start"
for (( i2=2;i2<=$str_col2;i2++)); do
	test2=$(sed -n $i2"p" $fhome"po1.txt" | tr -d '\r')		#pod
	logger "to_pods2 test2="$test2
	kubectl top pod $test2 -n $test > $fhome"top/"$i2".txt"
	str_col3=$(grep -c '' $fhome"top/"$i2".txt")
	logger "to_pods2 str_col3="$str_col3
	[ "$str_col3" -gt "1" ] && top_pod;
done
}

top_pod ()
{
logger "top_pod start"
ns=$test
pod=$(sed -n "2p" $fhome"top/"$i2".txt" | awk '{print $1}' | tr -d '\r')
cpu=$(sed -n "2p" $fhome"top/"$i2".txt" | awk '{print $2}' | tr -d '\r')
mem=$(sed -n "2p" $fhome"top/"$i2".txt" | awk '{print $3}' | tr -d '\r')

logger "top_pod pod="$pod
logger "top_pod cpu="$cpu
logger "top_pod mem="$mem

if [ "$(echo $cpu | grep -c 'm')" -gt "0" ]; then
	cpu2=$(echo $cpu | awk -F"m" '{print $1}')
	#cpu3=$(echo "$cpu2/1000" | bc)
	cpu=$cpu2
	logger "top_pod _cpu2="$cpu2
	#logger "top_pod _cpu3="$cpu3
fi

if [ "$(echo $mem | grep -c 'Mi')" -gt "0" ]; then
	mem2=$(echo $mem | awk -F"Mi" '{print $1}')
	mem3=$((mem2*1000000))
	mem=$mem3
	logger "top_pod _mem2="$mem2
	logger "top_pod _mem3="$mem3
fi

zapushgateway;

}


#START
logger " "
logger "start, ver "$ver
init;

logger "start local ne"
cp -f $fhome"0.sh" $fhome"start_pg.sh"
#echo "su pushgateway -c '/usr/local/bin/pushgateway --web.listen-address=0.0.0.0:${pushg_port} --web.enable-admin-api' -s /bin/bash 1>/dev/null 2>/dev/null &" >> $fhome"start_pg.sh"
echo $fhome"node_exporter --collector.textfile --collector.textfile.directory "$fhome"ne --web.listen-address=\":"$ne_port"\" 1>/dev/null 2>/dev/null &" >> $fhome"start_pg.sh"
chmod +rx $fhome"start_pg.sh"
$fhome"start_pg.sh"


#kkik=0
while true
do
sleep $sec4
logger " "
logger "healthscheck ok "

mkdir -p $fhome"ne2"
kubectl get ns | awk '{print $1}' > $fhome"ns1.txt"
str_col1=$(grep -c '' $fhome"ns1.txt")
logger "str_col1="$str_col1
if [ "$str_col1" -gt "1" ]; then
	to_ns;
fi


rm -r $fhome"ne"
mv -f $fhome"ne2" $fhome"ne"


#kkik=$(($kkik+1))
#if [ "$kkik" -ge "$progons" ]; then
#	curl -X PUT "http://"$pushg_ip":"$pushg_port"/api/v1/admin/wipe" &
#	kkik=0
#fi

done

