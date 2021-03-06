#!/bin/bash
############################# Created and written by Matthias Luettermann ############### 
#
#
#			special thnaks to 
#			Nicola Bandini n.bandini@gmail.com
#			Tom Lesniak and Hugo Geijteman 
#			for the nice and useful inspiratipon
#
# This progmem is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; 
#
# This progmem is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# contact the author directly for more information at: matthias@xcontrol.de
##########################################################################################

#Version 1.40


usage="
-ver Check_qnap Version
-C community		default public
-t timeout 			default 10 secdons
-v snmpversion		default 2c
-p snmpport			defauilt 161
-a 					checks you can use
					cpuload: check´s the system CPU load in perent
					cputemp: check´s the sytem CPU Temperature
					systemp: check´s the system Temperature
					hdtemp: check´s the Harddive Temperature
					diskusage: check´s the diskusage on perent
					mem: check´s the mem usage in perent
					volstatus: check´s the Volume status
					fan: check´s the Fan Speed
					hdstatus: check´s the Harddive status
					cachediskstatus: check´s the Cachedisk status
					lunstatus: check´s the LUN status
					raidstatus: check´s the Raid status
					powerstatus: check´s the Power status
					sysinfo: provides the QNAP infos
example

check_qanp -H 192.168.0.2 -a mem

responce: OK: Memory Total=15976MB used=9177MB free:6799MB|Memory usage=43%;80;90;0;100

or 

check_qanp -H myqnap.domain.com -C public -v 1 -p 123 -a cputemp -u F -w 40 -c 45 -t 60
checked host myqnap.domain.com
community public
snmpversion 1
snmpport 123
check cpu Temperature
unit fahrenheit
warning 40 F
critical 45 F
timeout 60 seconds

"

while getopts H:b:C:t:v:p:a:w:c:u:help:h option; 
do
	case $option in
		H) hostaddress=$OPTARG;;
		b) version=$OPTARG;;
		C) community=$OPTARG;;
		t) timeout=$OPTARG;;
		v) snmpversion=$OPTARG;;
		p) snmpport=$OPTARG;;
		a) check=$OPTARG;;
		w) warning=$OPTARG;;
		c) critical=$OPTARG;;
		u) unit=$OPTARG;;
		h) help=1;;
	esac
done

check()
{

if [[ "$help" == "1" ]]; then
echo "$usage"
exit;
fi

if  [[ -z "$hostaddress" ]] || [[ -z "$check" ]] && [[ "$help" != "1" ]];then
        echo "
** Hostaddress and checkprocedure are mandatory **
"
        echo "$usage"
        exit;
fi

}
check

if [[ -z "$community" ]]; then 
	community=public; 
fi

if [[ -z "$timeout" ]]; then 
	timeout=10; 
fi

if [[ -z "$snmpversion" ]]; then 
	snmpversion=2c; 
fi

if [[ -z "$snmpport" ]]; then 
	snmpport=161; 
fi

if [[ -z "$warning" ]]; then 
	warning=80; 
fi

if [[ -z "$critical" ]]; then 
	critical=90; 
fi

if [[ -z "$unit" ]]; then 
	unit=C; 
fi

if [[ "$unit" == "C" ]]; then
	var1="-c2-3";
	if [[ "$check" == "cputemp" ]]; then
		var2=20
		var3=90
	else
		var2=20
		var3=60
	fi
else
	var1="-c7-9";
	if [[ "check" == "cputemp" ]]; then
		var2=32
		var3=194
	else
		var=32
		var=140
	fi
fi

output=""
niu=0
count=0
counter=0
status=""
criticalqty=0
warningqty=0
okqty=0
avg=0

mysnmpcheck="snmpget -v $snmpversion -c $community -t $timeout $hostaddress:$snmpport"


# DISKUSAGE

if [[ "$check" == "diskusage" ]]; then
	capacity=$($mysnmpcheck 1.3.6.1.4.1.24681.1.2.17.1.4.1 | awk '{print $4}' | sed 's/.\(.*\)/\1/')
	free=$($mysnmpcheck 1.3.6.1.4.1.24681.1.2.17.1.5.1 | awk '{print $4}' | sed 's/.\(.*\)/\1/')
	unit=$($mysnmpcheck 1.3.6.1.4.1.24681.1.2.17.1.4.1 | awk '{print $5}' | sed 's/.*\(.B\).*/\1/')
	unit2=$($mysnmpcheck 1.3.6.1.4.1.24681.1.2.17.1.5.1 | awk '{print $5}' | sed 's/.*\(.B\).*/\1/')
	
		if [[ "$unit" == "TB" ]]; then
			factor=$(echo "scale=0; 1000000" | bc -l)
		elif [[ "$unit" == "GB" ]]; then
			factor=$(echo "scale=0; 1000" | bc -l)
		else
			factor=$(echo "scale=0; 1" | bc -l)
		fi

		if [[ "$unit2" == "TB" ]]; then
			factor2=$(echo "scale=0; 1000000" | bc -l)
		elif [[ "$unit2" == "GB" ]]; then
			factor2=$(echo "scale=0; 1000" | bc -l)
		else
			factor2=$(echo "scale=0; 1" | bc -l)
		fi

	capacitybytes=$(echo "scale=0; $capacity*$factor" | bc -l)
	freebytes=$(echo "scale=0; $free*$factor2" | bc -l)
	usedbytes=$(echo "scale=0; $capacitybytes-$freebytes" | bc -l)
	used=$(echo "scale=0; $usedbytes/$factor" | bc -l)
	usedperc=$(echo "scale=0; $usedbytes*100/$capacitybytes" | bc -l)
	freeperc=$(echo "scale=0; $freebytes*100/$capacitybytes" | bc -l)

	output="Total=$capacity $unit Used=$used $unit Free=$free $unittest2|Used=$usedperc%;$warning;$critical;0;100"
	
		if [[ $usedperc -ge $critical ]]; then
			echo "critical: "$output
			exit 2
		elif [[ $usedperc -ge $warning ]]; then
			echo "warning: "$output
		exit 1
		else 
			echo "OK: "$output
			exit 0
		fi

# CPULOAD
elif [[ "$check" == "cpuload" ]]; then
    cpuload=$($mysnmpcheck 1.3.6.1.4.1.24681.1.2.1.0 | awk '{print $4 $5}' | sed 's/.\(.*\)...../\1/')
	
	output="CPU-load=$cpuload%|CPU-load=$cpuload%;$warning;$critical;0;100"

	   	if [[ $cpuload -ge $critical ]]; then
			echo "critical: "$output
			exit 2 
		elif [[ $cpuload -ge $warning ]]; then
			echo "warning: "$output
			exit 1
		else 
			echo "OK: "$output
			exit 0
		fi

# CPUTEMP
elif [[ "$check" == "cputemp" ]]; then
    temp=$($mysnmpcheck .1.3.6.1.4.1.24681.1.2.5.0 | awk '{print $4,$5}' | cut $var1)

	output="CPU-temperature=$temp $unit|CPU-temperature=$temp%unit;$warning;$critical;$var2;$var3"

    	if  [[ $temp -ge $critical ]]; then
            echo "critical: "$output
            exit 2
        elif [[ $temp -ge $warning ]]; then
            echo "warning: "$output
            exit 1
        else
            echo "OK: "$output
            exit 0
        fi

# System Temperature
elif [[ "$check" == "systemp" ]]; then

    temp=$($mysnmpcheck .1.3.6.1.4.1.24681.1.2.6.0 | awk '{print $4,$5}' | cut $var1)

	output="System-temperature=$temp $unit|System-temperature=$temp$unit;$warning;$critical;$var2;$var3"

    	if [[ $temp -ge $critical ]]; then
            echo "critical: "$output
            exit 2

        elif [[ $temp -ge $warning ]]; then
            echo "warning: "$output
            exit 1
        else
            echo "OK: "$output
            exit 0
    	fi

# HD Temperature
elif [[ "$check" == "hdtemp" ]]; then
	count=$($mysnmpcheck .1.3.6.1.4.1.24681.1.2.10.0 | awk '{print $4}')

	for (( c=1; c<=$count; c++ ))
	do

		temp=$($mysnmpcheck .1.3.6.1.4.1.24681.1.2.11.1.3.$c | awk '{print $4,$5}' | cut $var1)

		if [[ "$temp" -ge "$critical" ]]; then
			crt="$crt| HD-$c $temp $unit"
			criticalqty=$(echo "scale=0; $criticalqty+1" | bc -l)
			avg=$(echo "scale=4; $avg + $temp" | tr , . | bc)
		elif [[ "$temp" -ge "$warning" ]]; then
			wrn="$wrn| HD-$c $temp $unit"
			warningqty=$(echo "scale=0; $warningqty+1" | bc -l)
			avg=$(echo "scale=4; $avg + $temp" | tr , . | bc)
		else
			okqty=$(echo "scale=0; $okqty+1" | bc -l)
			avg=$(echo "scale=4; $avg + $temp" | tr , . | bc) 
		fi
	done

		avg=$(echo $avg/$count | bc )

		if [[ "$criticalqty" -ge "1" ]]; then
    		echo "critical: $criticalqty $crt Average temperature= $avg $unit|Average-HD-temp=$avg$unit;$warning;$critical;$var2;$var3"
    		exit 2
    	elif [[ "$warningqty" -ge "1" ]]; then
    		echo "warning: $warningqty $wrn Average temperature= $avg $unit|Average-HD-temp=$avg$unit;$warning;$critical;$var2;$var3"
    		exit 1
    	else
    		echo "OK: $okqty HD´s Average temperature= $avg $unit|Average-HD-temp=$avg$unit;$warning;$critical;$var2;$var3"
    		exit 0
    	fi

# Free mem
elif [[ "$check" == "mem" ]]; then
	total=$($mysnmpcheck 1.3.6.1.4.1.24681.1.2.2.0 | awk '{print $4 $5}' | sed 's/.\(.*\)...../\1/')
	used=$($mysnmpcheck 1.3.6.1.4.1.24681.1.2.3.0 | awk '{print $4 $5}' | sed 's/.\(.*\)...../\1/')
	perc=$(echo "scale=0; 100-($used*100)/$total" | bc -l)
	unit=$($mysnmpcheck 1.3.6.1.4.1.24681.1.2.2.0 | awk '{print $5}'  | sed 's/.*\(.B\).*/\1/')
	free=$(echo "scale=0; $total-$used" | bc -l)
	
	output="Memory Total=$total$unit used=$used$unit free:$free$unit|Memory-usage=$perc%;$warning;$critical;0;100"
		
		if [[ $perc -ge $critical ]]; then
			echo "critical: "$output
			exit 2
		elif [[ $perc -ge $warning ]]; then
			echo "warning: "$output
			exit 1
		else
			echo "OK: "$output
			exit 0
		fi

# Volumestatus
elif [[ "$check" == "volstatus" ]]; then
	count=$($mysnmpcheck .1.3.6.1.4.1.24681.1.2.16.0 | awk '{print $4}')

    for (( c=1; c<=$count; c++ ))
	do
        status=$($mysnmpcheck .1.3.6.1.4.1.24681.1.2.17.1.6.$c | awk '{print $4}' | sed 's/^"\(.*\).$/\1/')
        if [[ $status == "Ready" ]]; then
        	okqty=$(echo "scale=0; okqty+1" |bc -l)
        elif [[ $status == "Rebuilding..." ]]; then
        	warningqty=$(echo "scale=0; $warningqty+1" | bc -l)
        else
            criticalqty=$(echo "scale=0; $criticalqty+1" | bc -l)
        fi

	    capacity=$($mysnmpcheck .1.3.6.1.4.1.24681.1.2.17.1.4.$c | awk '{print $4}' | sed 's/^"\(.*\).$/\1/')
	    free=$($mysnmpcheck .1.3.6.1.4.1.24681.1.2.17.1.5.$c | awk '{print $4}' | sed 's/^"\(.*\).$/\1/')
	    unit=$($mysnmpcheck 1.3.6.1.4.1.24681.1.2.17.1.4.$c | awk '{print $5}' | sed 's/.*\(.B\).*/\1/')
		unit2=$($mysnmpcheck 1.3.6.1.4.1.24681.1.2.17.1.5.$c | awk '{print $5}' | sed 's/.*\(.B\).*/\1/')
		if [[ "$unit" == "TB" ]]; then
			factor=$(echo "scale=0; 1000" | bc -l)
		elif [[ "$unit" == "GB" ]]; then
			factor=$(echo "scale=0; 100" | bc -l)
		else
			factor=$(echo "scale=0; 1" | bc -l)
		fi

		if [[ "$unit2" == "TB" ]]; then
			factor2=$(echo "scale=0; 1000" | bc -l)
		elif [[ "$unit2" == "GB" ]]; then
			factor2=$(echo "scale=0; 100" | bc -l)
		else
			factor2=$(echo "scale=0; 1" | bc -l)
		fi
		
		capacitybytes=$(echo "scale=0; $capacity*$factor" | bc -l)
		freebytes=$(echo "scale=0; $free*$factor2" | bc -l)
		usedbytes=$(echo "scale=0; $capacitybytes-$freebytes" | bc -l)
		used=$(echo "scale=0; $usedbytes/$factor" | bc -l)
		usedperc=$(echo "scale=0; $usedbytes*100/$capacitybytes" | bc -l)
		freeperc=$(echo "scale=0; $freebytes*100/$capacitybytes" | bc -l)

        if [[ $usedperc -ge $critical ]]; then
        	crt="$usedperc"
        	criticalqty=$(echo "scale=0; $criticalqty+1" | bc -l)
        elif [[ $perc -ge $warning ]]; then
        	wrn="$usedperc"
        	warningqty=$(echo "scale=0; $warningqty+1" | bc -l)
        fi

        if [[ $c -lt $count ]]; then
        	output="$output Volume-$c $status, Total=$capacity $unit, Used=$used $unit, Free=$free $unit2, "
        else
        	output="$output Volume-$c $status, Total=$capacity $unit, Used=$used $unit, Free=$free $unit2"
        fi
    done

		if [[ $criticalqty -ge 1 ]]; then
    		echo "critical: $criticalqty $crt, $output|Used=$usedperc%;$warning;$critical;0;100"
    		exit 2
    	elif [[ $warningqty -ge 1 ]]; then
    		echo "warning: $warningqty $wrn, $output|Used=$usedperc%;$warning;$critical;0;100"
    		exit 1
    	else
    		echo "OK: $okqty Volumes, $output|Used=$usedperc%;$warning;$critical;0;100"
    		exit 0
    	fi

# Fan
elif [[ "$check" == "fan" ]]; then
	count=$($mysnmpcheck .1.3.6.1.4.1.24681.1.2.14.0 | awk '{print $4}')

	for (( c=1; c<=$count; c++ ))
	do
		speed=$($mysnmpcheck .1.3.6.1.4.1.24681.1.2.15.1.3.$c | awk '{print $4}' | cut -c 2-5 )

    	if [[ $speed -le 5000 ]]; then
    		okqty=$(echo "scale=0; $okqty+1" | bc -l)
    		avg=$(echo "scale=4; $avg + $speed" | tr , . | bc)
    	else 
    		crt="$crt| HD-$c $speed RPM"
    		criticalqty=$(echo "scale=0; $criticalqty+1" | bc -l)
    		avg=$(echo "scale=4; $avg + $speed" | tr , . | bc)
    	fi
    done

    	avg=$(echo $avg/$count | bc )

    	if [[ "$criticalqty" -ge "1" ]]; then
    		echo "CRITICAL: $criticalqty Average Speed=$avg RPM"
    		exit 2
    	else
    		echo "OK Fans $okqty Average Speed=$avg RPM|Average-Speed=$avg RPM;4800;5200"
    		exit 0
    	fi

# HD Status
elif [[ "$check" == "hdstatus" ]]; then
	count=$($mysnmpcheck .1.3.6.1.4.1.24681.1.2.10.0 | awk '{print $4}')

	for (( c=1; c<=$count; c++ ))
	do
	   status=$($mysnmpcheck 1.3.6.1.4.1.24681.1.2.11.1.7.$c | awk '{print $4}' | sed 's/^"\(.*\).$/\1/')
	   
	   if [[ $status == "GOOD" ]]; then
	   	okqty=$(echo "scale=0; $okqty+1" | bc -l)
	   elif [[ "$status" == "--" ]]; then
	   	niu=$(echo "scale=0; $niu+1" | bc -l)
	   	else
	   		crt=" Disk ${c}"
	   		criticalqty=$(echo "scale=0; $criticalqty+1" | bc -l)
	   	fi
	done 
	if [[ "$criticalqty" -ge "1" ]]; then
		echo "CRITICAL: ${crt}"
		exit 2 
	else
		echo "OK: Online Disk $okqty, HD status = GOOD, Free Slot $niu"
		exit 0
	fi

# Cachedisstatus
elif [[ "$check" == "cachediskstatus" ]]; then
	count=$($mysnmpcheck .1.3.6.1.4.1.24681.1.4.1.1.1.1.6.1.0 | awk '{print $4}')
     
    for (( c=1; c<=$count; c++ ))
	do
        status=$($mysnmpcheck .1.3.6.1.4.1.24681.1.4.1.1.1.1.6.2.1.4.$c | awk '{print $4}' | sed 's/^"\(.*\).$/\1/')
        
        if [[ "$status" -eq "0" ]]; then
        	okqty=$(echo "scale=0; $okqty+1" | bc -l)
        else
        	crt="Cachedisk NOK $c"
        	criticalqty=$(echo "scale=0; $criticalqty+1" | bc -l)
        fi
     done

    if [[ "$criticalqty" -ge "1"  ]]; then
        echo "CRITICAL: ${criticalqty}"
        exit 2
    else
    	echo "OK: Cachedisk $okqty "
	exit 0
	fi     

# LUN Status
elif [[ "$check" == "lunstatus" ]]; then
	count=$($mysnmpcheck .1.3.6.1.4.1.24681.1.4.1.1.2.1.10.1.0 | awk '{print $4}')

	for (( c=1; c<=$count; c++ ))
	do
	   status=$($mysnmpcheck .1.3.6.1.4.1.24681.1.4.1.1.2.1.10.2.1.5.$c | awk '{print $4}' | sed 's/^"\(.*\).$/\1/')

	   if [[ $status == "Enabled" ]]; then
	   	okqty=$(echo "scale=0; $okqty+1" | bc -l)
	   else
	   	crt=" LUN NOK ${c}"
	   	criticalqty=$(echo "scale=0; $criticalqty+1" | bc -l)
	   fi
	done

    if [[ "$criticalqty" -ge "1" ]]; then
        echo "CRITICAL: ${criticalqty}"
        exit 2
    else
    	echo "OK: LUN´s $okqty"
	exit 0
	fi    

# raid Status
elif [[ "$check" == "raidstatus" ]]; then
	count=$($mysnmpcheck  .1.3.6.1.4.1.24681.1.4.1.1.1.2.1.1.0 | awk '{print $4}')

	for (( c=1; c<=$count; c++ ))
	do
	   status=$($mysnmpcheck  .1.3.6.1.4.1.24681.1.4.1.1.1.2.1.2.1.5.$c | awk '{print $4}' | sed 's/^"\(.*\).$/\1/')
	   
	   if [[ $status == "Ready" ]]; then
	   	okqty=$(echo "scale=0; $okqty+1" | bc -l)
	   else
	   	crt=" Raid NOK $c"
    	   fi
	done

    if [[ "$criticalqty" -ge "1" ]]; then
    	echo "CRITICAL: $crt"
        criticalqty=$(echo "scale=0; $criticalqty+1" | bc -l)
        exit 2
    else
    	echo "OK: Raid $okqty Ready"
	exit 0
	fi   

# Power stuply status
elif [[ "$check" == "powerstatus" ]]; then
	count=$($mysnmpcheck .1.3.6.1.4.1.24681.1.4.1.1.1.1.3.1.0 | awk '{print $4}')
     
    for (( c=1; c<=$count; c++ ))
	do
        status=$($mysnmpcheck .1.3.6.1.4.1.24681.1.4.1.1.1.1.3.2.1.4.$c | awk '{print $4}')
        
        if [[ "$status" -eq "0" ]]; then
        	okqty=$(echo "scale=0; $okqty+1" | bc -l)
        else
        	crt="Powersupply NOK $c"
        	criticalqty=$(echo "scale=0; $criticalqty+1" | bc -l)
        fi
     done

    if [[ "$criticalqty" -ge "1"  ]]; then
        echo "CRITICAL: ${criticalqty}"
        exit 2
    else
    	echo "OK: Powersupply $okqty "
	exit 0
	fi 

#Model
elif [[ "$check" == "sysinfo" ]]; then
	model=$($mysnmpcheck  .1.3.6.1.4.1.24681.1.2.12.0 | awk '{print $4}' | sed 's/^"\(.*\).$/\1/')
	hdnum=$($mysnmpcheck   .1.3.6.1.4.1.24681.1.2.10.0 | awk '{print $4}')
	count=$($mysnmpcheck  .1.3.6.1.4.1.24681.1.2.16.0 | awk '{print $4}')
	name=$($mysnmpcheck   .1.3.6.1.4.1.24681.1.2.13.0  | awk '{print $4}' | sed 's/^"\(.*\)$/\1/')
	firmware=$($mysnmpcheck   .1.3.6.1.2.1.47.1.1.1.1.9.1 | awk '{print $4}' | sed 's/^"\(.*\)$/\1/')
	netuptime=$($mysnmpcheck .1.3.6.1.2.1.1.3.0 | awk '{print $5, $6, $7, $8}')
    sysuptime=$($mysnmpcheck .1.3.6.1.2.1.25.1.1.0 | awk '{print $5, $6, $7, $8}') 

	echo NAS $name, Model $model, Firmware $firmware, Max HD number $hdnum, No. volume $count, system Uptime $sysuptime, Network Uptime $netuptime
	exit 0


	#statements    	
#
else
    echo -e "\nUnknown check!" && exit "3"
fi
exit 0