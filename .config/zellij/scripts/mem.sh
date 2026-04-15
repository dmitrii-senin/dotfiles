#!/bin/bash
case "$(uname)" in
  Darwin)
    page_size=$(sysctl -n hw.pagesize)
    total=$(sysctl -n hw.memsize)
    internal=$(sysctl -n vm.page_pageable_internal_count)
    purgeable=$(sysctl -n vm.page_purgeable_count)
    vm_stat | awk -v ps="$page_size" -v total="$total" -v internal="$internal" -v purgeable="$purgeable" \
      '/Pages wired/{gsub(/\./,"",$4);w=$4}/Pages occupied by compressor/{gsub(/\./,"",$5);c=$5}END{printf "%.0f%%",(internal-purgeable+w+c)*ps/total*100}'
    ;;
  Linux)
    awk '/MemTotal/{t=$2}/MemAvailable/{a=$2}END{printf "%.0f%%",(t-a)/t*100}' /proc/meminfo
    ;;
esac
