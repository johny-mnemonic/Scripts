#!/ffp/bin/sh

#
#  description: Script to get fan control working with DNS-320
#  Written by Johny Mnemonic
# 
#

# PROVIDE: fancontrol
# REQUIRE: LOGIN

. /ffp/etc/ffp.subr

name="fancontrol"
start_cmd="fancontrol_start"
stop_cmd="fancontrol_stop"
status_cmd="fancontrol_status"

PERIOD=30
LOGFILE=/var/log/fan.log
SysHigh=55
SysLow=50
HddHigh=50
HddLow=45
Hyst=2
SL=$((SysLow-Hyst))
DL=$((HddLow-Hyst))

logcommand()
   { 
   echo "`/bin/date '+%b %e %H:%M:%S'`:" $1 >> $LOGFILE
   }

disk1_temp()
    {
    smartctl -d marvell --all /dev/sda |grep 194 | tail -c 14| head -c 2
    }

disk2_temp()
    {
    smartctl -d marvell --all /dev/sdb |grep 194 | tail -c 14| head -c 2
    }
    
system_temp()
    {
    FT_testing -T | tail -c 3 | head -c 2
    }

Fancontrol() {
#!/bin/sh
    
logcommand "  Starting DNS-320 Fancontrol script"
logcommand "  Current temperatures: Sys: `system_temp`°C, HDD1: `disk1_temp`°C "

FAN=`fanspeed g`

while /ffp/bin/true; do
        /bin/sleep $PERIOD
        if [ `system_temp` -ge $SysHigh -o `disk1_temp` -ge $HddHigh ]; then
            logcommand "Fan speed $FAN"
            if [ $FAN != high ]; then
                logcommand "Running fan on high, temperature too high: Sys: `system_temp`°C, HDD1: `disk1_temp`°C "
                fanspeed h
                FAN=high
            fi
        else
            if [ `system_temp` -ge $SysLow -o `disk1_temp` -ge $HddLow ]; then
                logcommand "Fan speed $FAN"
                if [ $FAN != low ]; then
                    logcommand "Running fan on low, temperature high: Sys: `system_temp`°C, HDD1: `disk1_temp`°C "
                    fanspeed l
                    FAN=low
                fi
            else
                if [ `system_temp` -le $SL -a `disk1_temp` -le $DL ]; then
                    logcommand "Fan speed $FAN"
                    if [ $FAN != 'stop' ]; then
                        logcommand "Stopping fan, temperature low: Sys: `system_temp`°C, HDD1: `disk1_temp`°C "
                        fanspeed s
                        FAN=stop
                    fi
                fi
            fi
        fi
    done
}
   
fancontrol_start() {
    if [ ! -e /var/run/fancontrol.pid ] ; then
        logcommand "Starting DNS-320 Fancontrol daemon"
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
    rm /var/run/fancontrol.pid
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