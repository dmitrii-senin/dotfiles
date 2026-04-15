#!/bin/bash
case "$(uname)" in
  Darwin)
    pmset -g batt | awk '/InternalBattery/{gsub(/;/,""); if($4=="charging") s="↑"; else if($4=="discharging") s="↓"; else s=""; printf "%s%s", $3, s}'
    ;;
  Linux)
    bat=/sys/class/power_supply/BAT0
    if [ -d "$bat" ]; then
      cap=$(cat "$bat/capacity")
      status=$(cat "$bat/status")
      case "$status" in Charging) s="↑";; Discharging) s="↓";; *) s="";; esac
      printf "%s%%%s" "$cap" "$s"
    else
      printf "AC"
    fi
    ;;
esac
