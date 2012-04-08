#!/bin/sh

# how often to read and store temperatures in seconds
PERIOD="30"
# if you have just one HDD set to "0"
SECOND_HDD=0
LOGFILE="/var/log/fan.log"
# writing temperature to this file :
LOGTEMPFILE="/var/log/fan_temp"
LOGTEMPEXT=".log"

# temperatures and hysteresis
SysHigh="60"
SysLow="55"
HddHigh="48"
HddLow="45"
Hyst="2"


# do not edit bellow this line
# ----------------------------
SL=$((SysLow-Hyst))
DL=$((HddLow-Hyst))

logcommand() {
	logger "$1"
	echo "`/bin/date +"%b %e %H:%M:%S"`: $1" >> $LOGFILE
}

logtemperature() {
	if [ "$5" = "$1" ]; then
		TEXT=""
	else
		TEXT="$1"
	fi
	case $TEXT in
		stop) POSITION=5;;
		low) POSITION=10;;
		high) POSITION=15;;
		*) POSITION=20;;
	esac
	echo "`/bin/date +"%Y-%m-%d %H:%M:%S"`:" "\"$TEXT\" $2 $3 $4 $POSITION" >> $LOGTEMPFILE$(/bin/date +"%y%m%d")$LOGTEMPEXT
}

disk1_temp() {
	if hdparm -C /dev/sda | grep -q standby ; then
		Ta=-1
	else
		Ta=`smartctl -d marvell --all /dev/sda |grep -e ^194 | head -c 40 | tail -c 2`
	fi
}
disk2_temp() {
	 if hdparm -C /dev/sdb | grep -q standby ; then
		Tb=-1
	else
		Tb=`smartctl -d marvell --all /dev/sdb |grep -e ^194 | head -c 40 | tail -c 2`
	fi
}
	
system_temp() {
	ST=`FT_testing -T | tail -c 3 | head -c 2`
}

logcommand "Starting DNS-320 Fancontrol script"
disk1_temp
if [ $SECOND_HDD -eq "1" ]; then
	disk2_temp
else
	Tb="-1"
fi
system_temp
logcommand "Current temperatures: Sys: "$ST"C, HDD1: "$Ta"C, HDD2: "$Tb"C"

FAN=`fanspeed g`

while /ffp/bin/true; do
	/bin/sleep $PERIOD
	disk1_temp
	if [ $SECOND_HDD -eq "1" ]; then
        disk2_temp
    else
        Tb="-1"
    fi
    OLD_FAN=$FAN
	system_temp
	if [ $ST -ge $SysHigh -o $Ta -ge $HddHigh -o $Tb -ge $HddHigh ]; then
		if [ $FAN != high ]; then
			logcommand "Running fan on high, temperature too high: Sys: "$ST"C, HDD1: "$Ta"C, HDD2: "$Tb"C "
			fanspeed h
			FAN=high
		fi
	else
		if [ $ST -ge $SysLow -o $Ta -ge $HddLow -o $Tb -ge $HddLow ]; then
			if [ $FAN != low ]; then
				logcommand "Running fan on low, temperature high: Sys: "$ST"C, HDD1: "$Ta"C, HDD2: "$Tb"C "
				fanspeed l
				FAN=low
			fi
		else
			if [ $ST -le $SL -a $Ta -le $DL -a $Tb -le $DL ]; then
				if [ $FAN != 'stop' ]; then
					logcommand "Stopping fan, temperature low: Sys: "$ST"C, HDD1: "$Ta"C, HDD2: "$Tb"C "
					fanspeed s >/dev/null 2>/dev/null &
					FAN=stop
				fi
			fi
		fi
	fi
	logtemperature $FAN $ST $Ta $Tb $OLD_FAN
done
