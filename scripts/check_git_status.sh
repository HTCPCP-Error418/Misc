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
RESET=$ESC"39m"
BLUE=$ESC"34m"

TLD="$1"
for directory in $(ls $TLD); do
	echo -e "${BLUE}$TLD/$directory${RESET}"
	cd $TLD/$directory
	status=$(git status)
	echo "$status"
	echo ""
done
