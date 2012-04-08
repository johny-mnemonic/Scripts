#!/bin/sh

# how often to read and store temperatures in seconds
PERIOD=300

LOGFILE="/var/log/tplot.log"
PNG_FOLDER="/tmp/graphs"
AJAX_FOLDER="/hd1/Ajaxpf"

# reading temperature from this file :
DATAFILE="/var/log/fan_temp"
DATAFILE_EXT=".log"


# do not edit bellow this line
# ----------------------------
logcommand() {
	logger "$1"
	echo "`/bin/date +"%b %e %H:%M:%S"`: $1" >> $LOGFILE
}

# writing graphs to png_folder:
mkdir -p $PNG_FOLDER

# create symlink to graphs folder in Ajax
if [ ! -e $AJAX_FOLDER/graphs ]; then
	ln -s $PNG_FOLDER "$AJAX_FOLDER"/graphs
fi

logcommand "Starting DNS-320 tplot script"

while /bin/true; do
	CUR_DATAFILE=$DATAFILE$(/bin/date +"%y%m%d")$DATAFILE_EXT

	if [ -e $CUR_DATAFILE ]; then
		logcommand "Reading from file $CUR_DATAFILE"

		GFX_FILE="${PNG_FOLDER}/temperatures_$(/bin/date +"%y%m%d").png"
		GNU_FILE="/tmp/gnufile"

		echo "set terminal png nocrop large size 1400,900" > $GNU_FILE
		echo "set output '$GFX_FILE'" >> $GNU_FILE
		echo "set timefmt '%Y-%m-%d %H:%M:%S:'" >> $GNU_FILE
		echo "set xdata time" >> $GNU_FILE
		echo "set yrange [0:60]" >> $GNU_FILE
		echo "plot '$CUR_DATAFILE' u 1:4 w st title 'System','' u 1:5 w st title 'Disk 1(R)','' u 1:6 w st title 'Disk 2(L)','' u 1:7 w labels title 'FAN'" >> $GNU_FILE
		logcommand "Drawing to file $GFX_FILE"
		gnuplot $GNU_FILE
	else
		logcommand "File $CUR_DATAFILE does not exist!"
	fi
	/bin/sleep $PERIOD
done
