#!/bin/bash

: '
	This script is designed to iterate through the first level of subdirectories in a given
	directory, running "git status" in each. In setups where there is a single folder that
	contains multiple Github repos, this script will make checking the status of each repo
	easier.

	Usage: check_git_status.sh [Top-Level Directory]

	Improvements:
		- Color
		- Check for trailing slash in TLD
			- If trailing slash exists, no need to add one
		- Error handling
'

#colors
ESC="\e["
RESET=$ESC"01;39m"
RED=$ESC"01;31m"
BLUE=$ESC"01;34m"

function usage {
	echo "	Usage: $0 [Top-Level Directory]"
	exit 0
}

#if no directory provided, print usage and exit
if [[ -z "$1" ]]; then
	echo -e "${RED}Please specify top-level directory to check${RESET}"
	usage
fi

TLD="$1"
for directory in $(ls $TLD); do
	echo -e "${BLUE}$TLD/$directory${RESET}"
	cd $TLD/$directory
	status=$(git status)
	echo "$status"
	echo ""
done
