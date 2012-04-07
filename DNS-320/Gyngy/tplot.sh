#!/ffp/bin/sh

#
#  description: Script to plot temperature chart 
#  Written by Gyngy
#  fancontrol_dns320.sh is needed to provide temperature data
#

# PROVIDE: 
# REQUIRE: LOGIN

. /ffp/etc/ffp.subr

name="tplot"
start_cmd="tplot_start"
stop_cmd="tplot_stop"
status_cmd="tplot_status"

# how often to read and store temperatures in seconds
PERIOD=300

LOGFILE="/var/log/tplot.log"
# reading temperature from this file :
DATAFILE="/var/log/fan_temp"
DATAFILE_EXT=".log"

# writing graphs to folder:
mkdir /tmp/graphs
PNG_FOLDER="/tmp/graphs"

# create symlink to graphs folder in Ajax
ln -s /tmp/graphs /hd1/Ajaxpf/graphs


# do not edit bellow this line
# ----------------------------
logcommand()
   { 
   echo "`/ffp/bin/date +"%b %e %H:%M:%S"`:" $1 >> $LOGFILE
   echo "`/ffp/bin/date +"%b %e %H:%M:%S"`:" $1
   }

tplot() {
#!/ffp/bin/sh
    
logcommand "  Starting DNS-320 tplot script"

while /ffp/bin/true; do

    CUR_DATAFILE=$DATAFILE$(/ffp/bin/date +"%y%m%d")$DATAFILE_EXT

    if [ -e $CUR_DATAFILE ]; then
            logcommand "Reading from file $CUR_DATAFILE"
        
        GFX_FILE="${PNG_FOLDER}/temperatures_$(/ffp/bin/date +"%y%m%d").png"
        GNU_FILE="/tmp/gnufile"

        echo "set terminal png nocrop large size 1400,900" > $GNU_FILE
        echo "set output '$GFX_FILE'" >> $GNU_FILE
        echo "set timefmt '%Y-%m-%d %H:%M:%S:'" >> $GNU_FILE
        echo "set xdata time" >> $GNU_FILE
        echo "set yrange [0:60]" >> $GNU_FILE
        echo "plot '$CUR_DATAFILE' u 1:4 w st title 'System','' u 1:5 w st title 'Disk R (Seagate)','' u 1:6 w st title 'Disk L (WD)','' u 1:7:3 w labels title 'FAN'" >> $GNU_FILE
      logcommand "Drawing to file $GFX_FILE"
        gnuplot $GNU_FILE
    
    else
        logcommand "File $CUR_DATAFILE does not exist!"
        fi
        /ffp/bin/sleep $PERIOD

    done
}
   
tplot_start() {
    if [ ! -e /var/run/tplot.pid ] ; then
        logcommand "Starting DNS-320 tplot daemon"
        tplot & 
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
	mv -f /tmp/graphs /hd1/Ajaxpf/old_graphs
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