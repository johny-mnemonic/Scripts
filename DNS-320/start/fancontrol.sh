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

LOGFILE=/var/log/fan.log

logcommand() {
	logger "$1"
	echo "`/bin/date +"%b %e %H:%M:%S"`:" $1 >> $LOGFILE
}

fancontrol_start() {
	if [ ! -e /var/run/fancontrol.pid ] ; then
        logcommand "Starting DNS-320 Fancontrol daemon"
		killall fan_control >/dev/null 2>/dev/null &
		mv /usr/sbin/fan_control /usr/sbin/ffff
		cp /ffp/bin/fancontrol.sh /tmp/fancontrol.sh
		/tmp/fancontrol.sh >/dev/null 2>/dev/null & 
		echo $! >> /var/run/fancontrol.pid
	else
        logcommand "Fancontrol daemon already running"
    fi
}

fancontrol_stop() {
	logcommand "Stopping DNS-320 Fancontrol daemon"
	kill -9 `cat /var/run/fancontrol.pid`
	rm /var/run/fancontrol.pid
	rm /tmp/fancontrol.sh
	mv /usr/sbin/ffff /usr/sbin/fan_control
	#logcommand "Starting built-in fan_control"
	fan_control 0 d >/dev/null 2>/dev/null &
}
	
fancontrol_restart() {
	fancontrol_stop
	sleep 2
	fancontrol_start
}

fancontrol_status() {
	if [ -e /var/run/fancontrol.pid ]; then
		echo "Fancontrol daemon is running"
	else
		echo "Fancontrol daemon is not running"
	fi
}

run_rc_command "$1"
