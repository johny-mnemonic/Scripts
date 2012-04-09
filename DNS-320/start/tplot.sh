#!/ffp/bin/sh

#
#  description: Script to plot temperature chart
#  Written by Gyngy
#  Modified by Johny Mnemonic
#  fancontrol.sh is needed to provide temperature data
#

# PROVIDE: tplot
# REQUIRE: LOGIN

. /ffp/etc/ffp.subr

name="tplot"
start_cmd="tplot_start"
stop_cmd="tplot_stop"
status_cmd="tplot_status"

PNG_FOLDER="/tmp/graphs"
AJAX_FOLDER="/hd1/Ajaxpf"
LOGFILE="/var/log/tplot.log"

logcommand() {
	logger "$1"
	echo "`/bin/date +"%b %e %H:%M:%S"`:" $1 >> $LOGFILE
}

tplot_start() {
    if [ ! -e /var/run/tplot.pid ] ; then
        logcommand "Starting DNS-320 tplot daemon"
		# create graphs folder
		mkdir -p $PNG_FOLDER
		# create symlink to graphs folder in Ajax
		if [ ! -e $AJAX_FOLDER/graphs ]; then
			ln -s $PNG_FOLDER "$AJAX_FOLDER"/graphs
		fi
		# force refresh of graph even if there is no update from fancontrol
		echo "49 11,23 * * * rm -f ${PNG_FOLDER}/temperatures_"\`/bin/date +"%y%m%d"\`".png" >> /var/spool/cron/crontabs/root
		cp /ffp/bin/tplot.sh /tmp/tplot.sh
		/tmp/tplot.sh $PNG_FOLDER >/dev/null 2>/dev/null &
        echo $! >> /var/run/tplot.pid
    else
        logcommand "tplot daemon already running"
    fi
}

tplot_stop() {
	logcommand "Stopping DNS-320 tplot daemon"
	kill -9 `cat /var/run/tplot.pid`
	rm /var/run/tplot.pid > /dev/null 2> /dev/null
	# copy old graphs to Ajax
	mv -f $PNG_FOLDER/* "$AJAX_FOLDER"/old_graphs/
	# remove from cron
	crontab -l | grep -vw "$PNG_FOLDER" | crontab -
}

tplot_restart() {
	tplot_stop
	tplot_start
}

tplot_status() {
	if [ -e /var/run/tplot.pid ]; then
		echo " tplot daemon is running"
	else
		echo " tplot daemon is not running"
	fi
}

run_rc_command "$1"
