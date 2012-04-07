#!/ffp/bin/sh
#
#  description: Script to get fan control working with DNS-320
#  Written by Johny Mnemonic
#  Edited by Gyngy
#

# PROVIDE: fancontrol
# REQUIRE: LOGIN

. /ffp/etc/ffp.subr

name="fancontrol"
start_cmd="fancontrol_start"
stop_cmd="fancontrol_stop"
status_cmd="fancontrol_status"

# how often to read and store temperatures in seconds
PERIOD="5"
# if you have just one HDD set to "0"
SECOND_HDD=0
LOGFILE="/var/log/fan.log"
# writing temperature to this file :
LOGTEMPFILE="/var/log/fan_temp"
LOGTEMPEXT=".log"

# temperatures hysteresis
SysHigh="59"
SysLow="54"
HddHigh="48"
HddLow="45"
Hyst="2"


# do not edit bellow this line
# ----------------------------
SL=$((SysLow-Hyst))
DL=$((HddLow-Hyst))

logcommand()
   { 
   echo "`/ffp/bin/date +"%b %e %H:%M:%S"`:" $1 >> $LOGFILE
   }

logtemperature()
   { 
   if [ "$5" = "$1" ]
   then 
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
   echo "`/ffp/bin/date +"%Y-%m-%d %H:%M:%S"`:" "\"$TEXT\" $2 $3 $4 $POSITION" >> $LOGTEMPFILE$(/ffp/bin/date +"%y%m%d")$LOGTEMPEXT
   }

disk1_temp()
    {
    if [ -s /tmp/hdd ]; then
		D1_TEMP=-1
	else
		D1_TEMP=`smartctl -d marvell --all /dev/sda |grep 194 | head -c 40 | tail -c 2`
	fi
    }

disk2_temp()
    {
    if [ -s /tmp/hdd ]; then
		D2_TEMP=-1
	else
		D2_TEMP=`smartctl -d marvell --all /dev/sdb |grep 194 | head -c 40 | tail -c 2`
	fi
    }
    
system_temp()
    {
    FT_testing -T | tail -c 3 | head -c 2
    }

Fancontrol() {
#!/ffp/bin/sh
    
disk1_temp
disk2_temp
logcommand "  Starting DNS-320 Fancontrol script"
logcommand "  Current temperatures: Sys: `system_temp`°C, HDD1: "$D1_TEMP"°C, HDD2: "$D2_TEMP"°C "

FAN=`fanspeed g`

while /ffp/bin/true; do
        /ffp/bin/sleep $PERIOD
    SYS_TEMP=`system_temp`
    disk1_temp
    if [ $SECOND_HDD -eq "1" ]; then
        disk2_temp
    else 
        D2_TEMP="0"
    fi
    OLD_FAN=$FAN
        if [ $SYS_TEMP -ge $SysHigh -o $D1_TEMP -ge $HddHigh -o $D2_TEMP -ge $HddHigh ]; then
            #logcommand "Fan speed $FAN"
            if [ $FAN != "high" ]; then
                logcommand "Running fan on high, temperature too high: Sys: $SYS_TEMP°C, HDD1: $D1_TEMP°C, HDD2: $D2_TEMP°C"
                fanspeed h
                FAN=high
            fi
        else
            if [ $SYS_TEMP -ge $SysLow -o $D1_TEMP -ge $HddLow -o $D2_TEMP -ge $HddLow ]; then
                #logcommand "Fan speed $FAN"
                if [ $FAN != "low" ]; then
                    logcommand "Running fan on low, temperature high: Sys: $SYS_TEMP°C, HDD1: $D1_TEMP°C, HDD2: $D2_TEMP°C"
                    fanspeed l
                    FAN=low
                fi
            else
                if [ $SYS_TEMP -le $SL -a $D1_TEMP -le $DL -a $D2_TEMP -le $DL ]; then
                    #logcommand "Fan speed $FAN"
                    if [ $FAN != "stop" ]; then
                        logcommand "Stopping fan, temperature low: Sys: $SYS_TEMP°C, HDD1: $D1_TEMP°C, HDD2: $D2_TEMP°C"
                        fanspeed s
                        FAN=stop
                    fi
                fi
            fi
        fi
    logtemperature $FAN $SYS_TEMP $D1_TEMP $D2_TEMP $OLD_FAN
    done
}
   
fancontrol_start() {
    if [ ! -e /var/run/fancontrol.pid ] ; then
        logcommand "Starting DNS-320 Fancontrol daemon"
        logcommand "Killing fan_control ..."
        killall fan_control >/dev/null 2>/dev/null &
        Fancontrol & 
        echo $! >> /var/run/fancontrol.pid
    else
        logcommand "Fancontrol daemon already running"
    fi
}

fancontrol_stop() {
    logcommand "Stopping DNS-320 Fancontrol daemon"
    kill -9 `cat /var/run/fancontrol.pid`
    rm /var/run/fancontrol.pid > /dev/null 2> /dev/null
}
    
fancontrol_restart() {
    fancontrol_stop
    fancontrol_start
}

fancontrol_status() {
    if [ -e /var/run/fancontrol.pid ]; then
        echo " Fancontrol daemon is running"
    else
        echo " Fancontrol daemon is not running"
    fi
}

run_rc_command "$1"
