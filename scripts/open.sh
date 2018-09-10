#!/bin/bash

# background and silence anything opened by xdg-open

xdg-open "$1" &> /dev/null & disown
