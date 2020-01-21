#!/bin/bash
#
# This script is used to control test_daemon. This will serve as an example for creating Linux services
#


function usage {
	echo "usage: $0 [start | stop | restart | status]"
	echo ""
}

function d_start {
	
}

function d_stop {
	
}

function d_status {
	
}



case "$1" in
	start)
		d_start
		sleep 1
		d_status
		;;

	stop)
		d_stop
		sleep 1
		d_status
		;;

	restart)
		d_stop
		sleep 1
		d_start
		sleep 1
		d_status
		;;

	status)
		d_status
		;;

	*)
		usage
		exit 1
		;;
esac
exit 0
