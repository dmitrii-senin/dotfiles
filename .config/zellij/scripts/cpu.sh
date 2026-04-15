#!/bin/bash
case "$(uname)" in
  Darwin)
    ps -A -o %cpu | awk -v n="$(sysctl -n hw.ncpu)" '{s+=$1} END {printf "%.0f%%", s/n}'
    ;;
  Linux)
    awk '{u=$2+$4; t=$2+$4+$5} NR==1{u1=u;t1=t} NR==2{printf "%.0f%%", (u-u1)/(t-t1)*100}' <(grep '^cpu ' /proc/stat; sleep 1; grep '^cpu ' /proc/stat)
    ;;
esac
