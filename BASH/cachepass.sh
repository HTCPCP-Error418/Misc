#!/bin/bash

#if updating this path, also update path in ssh_deauth.sh
pid_file="/tmp/ssh_cache.pid"
tmp_pid="/tmp/temp_ssh_cache.pid"

usage() { echo "Usage: $0 [-a <start|stop>]" 1>&2; exit 1; }

while getopts a: flag
do
    case "${flag}" in
        a) action=${OPTARG};;
    esac
done

# echo "action: ${action,,}"
action="${action,,}"

case ${action} in

    "start")
#       echo "matched start"
        eval $(ssh-agent -s) > "${tmp_pid}"
        ssh-add
        < "${tmp_pid}" cut -f 3 -d ' ' > "${pid_file}"
        rm "${tmp_pid}"
        echo "PID: $(cat ${pid_file})"
        ;;

    "stop")
#       echo "matched stop"
        echo "PID file found. PID: $(cat ${pid_file})"
        kill $(cat ${pid_file})
        echo "Sessions deauthed."
        rm ${pid_file}
        ;;

    *)
#       echo "matched no options"
        usage
        ;;
esac
