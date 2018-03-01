#!/ffp/bin/sh
#
#  description: A better fan control tool for DNS-320L NAS
#  author: Jarno Kurlin
# 

# PROVIDE: fancontrol
# REQUIRE: LOGIN

. /ffp/etc/ffp.subr

name="fancontrol"
start_cmd="fancontrol_start"
stop_cmd="fancontrol_stop"
status_cmd="fancontrol_status"

LOGFILE=/var/log/user.log

logcommand() {
	logger "$1"
	echo "`/bin/date +"%b %e %H:%M:%S"`:" $1 >> $LOGFILE
}

fancontrol_start() {
	if [ ! -e /var/run/fancontrol.pid ] ; then
        logcommand "Starting DNS-320L fan control daemon"
		killall fan_control >/dev/null 2>/dev/null &
		cp /ffp/bin/fancontrol.sh /tmp/fancontrol.sh
		/tmp/fancontrol.sh >/dev/null 2>/dev/null & 
		echo $! >> /var/run/fancontrol.pid
	else
        logcommand "Fan control daemon already running"
    fi
}

fancontrol_stop() {
	logcommand "Stopping DNS-320L fan control daemon"
	kill -9 `cat /var/run/fancontrol.pid`
	rm /var/run/fancontrol.pid
	rm /tmp/fancontrol.sh
	logcommand "Starting built-in fan_control"
	fan_control 0 c &
}
	
fancontrol_restart() {
	fancontrol_stop
	sleep 2
	fancontrol_start
}

fancontrol_status() {
	if [ -e /var/run/fancontrol.pid ]; then
		echo "Fan control daemon is running"
		/tmp/fancontrol.sh status	
	else
		echo "Fan control daemon is not running"
	fi
}

run_rc_command "$1"
