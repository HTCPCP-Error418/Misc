#!/bin/bash

#if updating this path, update path in cachepass.sh
pid_file="/tmp/ssh_cache.pid"

usage() { echo "Running this script checks for cached ssh creds and deauths them" 1>&2; exit 1; }


if [[ -f "$pid_file" ]]; then
    echo "PID file found. Stored PID: $(cat ${pid_file})"
    kill $(cat ${pid_file})
    echo "Sessions deauthed."
    rm ${pid_file}
else
    echo "No PID file found."
fi
