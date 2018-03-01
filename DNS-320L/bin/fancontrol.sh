#!/bin/sh
#
#  description: A better fan control tool for DNS-320L NAS
#  author: Jarno Kurlin
# 

# PROVIDE: fancontrol
# REQUIRE: LOGIN

#
# USER SETTINGS
#

# how often to read and store temperatures in seconds
PERIOD="30"
# where to write fan state changes
LOGFILE="/var/log/user.log"
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

# get disk1 temperature
disk1_temp() {
	if hdparm -C /dev/sda | grep -q standby ; then
		Ta=-1
	else
		Ta=`smartctl -d marvell --all /dev/sda |grep -e ^194 | awk '{print $10}'`
	fi
}

# get disk2 temperature
disk2_temp() {
	 if hdparm -C /dev/sdb | grep -q standby ; then
		Tb=-1
	else
		Tb=`smartctl -d marvell --all /dev/sdb |grep -e ^194 | awk '{print $10}'`
	fi
}

# get disk temperatures
disk_temps() {
	disk1_temp
	if [ $SECOND_HDD -eq "1" ]; then
        disk2_temp
    else
        Tb="-1"
    fi
}

# get system temperature
system_temp() {
	ST=`fan_control -g 0 | tail -c 3 | head -c 2`
}

# set fan status
set_fan_state() {
	fan_control -f $1
}

# get fan status
fan_state() {
	FAN=`fan_control -g 3 | tail -c 2`
}

# check if second disk is mounted
check_second_disk() {
	SD=`mount | grep /dev/sdb | head -n 1`
	if [[ ! -z "$SD" ]]; then
		SECOND_HDD="1"
	else 
		SECOND_HDD="0"
	fi
}

# if we want just get system status, echo it and exit
if [[ "$1" = "status" ]]; then
	check_second_disk
	disk_temps
	system_temp
	fan_state
	echo "Current temperatures: Sys: "$ST"C, HDD1: "$Ta"C, HDD2: "$Tb"C fan state: "$FAN
	exit 0
fi

# and here we go...
logcommand "Starting DNS-320L Fan control script"
check_second_disk
disk_temps
system_temp
fan_state
logcommand "Current temperatures: Sys: "$ST"C, HDD1: "$Ta"C, HDD2: "$Tb"C fan state: "$FAN

while /bin/true; do
	disk_temps
	system_temp
	if [ $ST -ge $SysHigh -o $Ta -ge $HddHigh -o $Tb -ge $HddHigh ]; then
		if [ $FAN -ne "2" ]; then
			logcommand "Setting fan speed high, temperature too high: Sys: "$ST"C, HDD1: "$Ta"C, HDD2: "$Tb"C "
			set_fan_state 2
			fan_state
		fi
	else
		if [ $ST -ge $SysLow -o $Ta -ge $HddLow -o $Tb -ge $HddLow ]; then
			if [ $FAN -ne "1" ]; then
				logcommand "Setting fan speed low, temperature high: Sys: "$ST"C, HDD1: "$Ta"C, HDD2: "$Tb"C "
				set_fan_state 1
				fan_state
			fi
		else
			if [ $ST -le $SL -a $Ta -le $DL -a $Tb -le $DL ]; then
				if [ $FAN -ne "0" ]; then
					logcommand "Stopping fan, temperature low: Sys: "$ST"C, HDD1: "$Ta"C, HDD2: "$Tb"C "
					set_fan_state 0
					fan_state
				fi
			fi
		fi
	fi
	/bin/sleep $PERIOD
done
exit 0;
