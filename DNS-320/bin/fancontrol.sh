#!/bin/sh

PERIOD=30
LOGFILE=/var/log/fan.log
SysHigh=60
SysLow=55
HddHigh=50
HddLow=45
Hyst=2
SL=$((SysLow-Hyst))
DL=$((HddLow-Hyst))
FAN="init"

if [ -n  "`pidof syslogd`" ] ; then
   logcommand() 
   {
   logger $1
   }
else
   logcommand()
   { 
   echo "`/bin/date '+%b %e %H:%M:%S'`:" $1 >> $LOGFILE
   }
fi

disk_temp() {
	if [ -s /tmp/hdd ]; then
		T=-1
	else
		Ta=`smartctl -d marvell --all /dev/sda |grep -e ^194 | head -c 40 | tail -c 2`
		Tb=`smartctl -d marvell --all /dev/sdb |grep -e ^194 | head -c 40 | tail -c 2`
		if [ -z "$Ta"]; then
		Ta=0
		fi
		if [ -z "$Tb"]; then
		Tb=0
		fi
		if [ $Ta -gt $Tb ]; then
		# Assign the higher temperature
			T=$Ta                        
		else   
			T=$Tb
		fi
	fi
}
	
system_temp() {
	ST=`FT_testing -T | tail -c 3 | head -c 2`
}

logcommand "  Starting DNS-320 Fancontrol script"
disk_temp
system_temp
logcommand "  Current temperatures: Sys: "$ST"C, HDD: "$T"C "

while /ffp/bin/true; do
    #killall fan_control >/dev/null 2>/dev/null &
    /bin/sleep $PERIOD
	disk_temp
	system_temp
	if [ $ST -ge $SysHigh -o $T -ge $HddHigh ]; then
		if [ $FAN != high ]; then
			logcommand "Running fan on high, temperature too high: Sys: "$ST"C, HDD: "$T"C "
		fi
		fanspeed h >/dev/null 2>/dev/null &
		FAN=high
	else
		if [ $ST -ge $SysLow -o $T -ge $HddLow ]; then
			if [ $FAN != low ]; then
				logcommand "Running fan on low, temperature high: Sys: "$ST"C, HDD: "$T"C "
			fi
			fanspeed l >/dev/null 2>/dev/null &
			FAN=low
		else
			if [ $ST -le $SL -a $T -le $DL ]; then
				if [ $FAN != 'stop' ]; then
					logcommand "Stopping fan, temperature low: Sys: "$ST"C, HDD: "$T"C "
				fi
				fanspeed s >/dev/null 2>/dev/null &
				FAN=stop
			fi
		fi
	fi
done

	