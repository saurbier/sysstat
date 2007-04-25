#!/bin/sh

SYSSTAT_RB=INSTALLDIR/bin/sysstat.rb
PID_FILE=/var/run/sysstat.pid

case "$1" in
'start')
	echo "Starting system statistics: sysstat";
	$SYSSTAT_RB --pidfile $PID_FILE &
	;;

'stop')
	echo "Stopping system statistics: sysstat";
	if [ -f $PID_FILE ]; then
		kill `cat $PID_FILE`
		rm $PID_FILE
	else
		echo "sysstat not running(?)";
	fi
	;;

'reload')
	echo "Reloading system statistics: sysstat";
	if [ -f $PID_FILE ]; then
		kill -USR1 `cat $PID_FILE`
	else
		echo "sysstat not running(?)";
	fi
	;;

'restart')
	echo "Restarting system statistics: sysstat";
	if [ -f $PID_FILE ]; then
		kill `cat $PID_FILE`
		$SYSSTAT_RB --pidfile $PID_FILE &		
	else
		echo "sysstat not running(?)";
	fi
	;;

'*')
	echo 'Usage: $0 { start | stop | reload | restart }'
	exit 1
	;;

esac
exit 0
