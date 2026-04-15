#!/bin/bash
ps -A -o %cpu | awk -v n="$(sysctl -n hw.ncpu)" '{s+=$1} END {printf "%.0f%%", s/n}'
