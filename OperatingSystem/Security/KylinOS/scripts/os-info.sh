#!/bin/bash
#-----------------------------------------------------------------------#
# System security initiate hardening tool for KylinOS 10 Server.
# WeiyiGeek <master@weiyigeek.top>
# Blog : https://blog.weiyigeek.top

# The latest version of my giuthub can be found at:
# https://github.com/WeiyiGeek/SecOpsDev/
#
# Copyright (C) 2020-2023 WeiyiGeek
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
#-------------------------------------------------------------------------#


# 函数名称: info_system
# 函数用途: 获取加固系统相关信息，包括但不限于计算机名称、内核、内存、CPU、磁盘以及挂载相关信息
# 函数参数: 无
function info_system () {
  log::info "[${COUNT}] Get information about computer system."
  log::info "[-] 正在获取加固系统相关信息."
  # Get last login time
  LAST_LOGIN=$(last -n 2 --time-format iso | sed -n '2p;')
  LAST_LOGIN_T=$(echo ${LAST_LOGIN} | awk '{print $2}')
  LAST_LOGIN_IP=$(echo ${LAST_LOGIN} | awk '{print $3}')
  LAST_LOGIN_TIME=$(echo ${LAST_LOGIN} | awk '{print $4}')
  LAST_LOGOUT_TIME=$(echo ${LAST_LOGIN} | awk '{print $6}')

  # Get load averages
  LOAD1=$(grep "" /proc/loadavg | awk '{print $1}')
  LOAD5=$(grep "" /proc/loadavg | awk '{print $2}')
  LOAD15=$(grep "" /proc/loadavg | awk '{print $3}')

  # Get free memory
  MEMORY_USED=$(free -t -m | grep "Mem" | awk '{print $3}')
  MEMORY_ALL=$(free -t -m | grep "Mem" | awk '{print $2}')
  MEMORY_PERCENTAGE=$(free | awk '/Mem/{printf("%.2f%"), $3/$2*100}')

  # Get system uptime
  UPTIME=$(grep "" /proc/uptime | cut -f1 -d.)
  UPTIME_DAYS=$(("${UPTIME}"/60/60/24))
  UPTIME_HOURS=$(("${UPTIME}"/60/60%24))
  UPTIME_MINS=$(("${UPTIME}"/60%60))
  UPTIME_SECS=$(("${UPTIME}"%60))

  # Get processes
  PROCESS=$(ps -eo user=|sort|uniq -c | awk '{print $2 " " $1 }')
  PROCESS_ALL=$(echo "${PROCESS}" | awk '{print $2}' | awk '{SUM += $1} END {print SUM}')
  PROCESS_ROOT=$(echo "${PROCESS}" | grep root | awk '{print $2}')
  PROCESS_USER=$(echo "${PROCESS}" | grep -v root | awk '{print $2}' | awk '{SUM += $1} END {print SUM}')

  # Get processors
  PROCESSOR_NAME=$(grep "model name" /proc/cpuinfo | cut -d ' ' -f3- | awk '{print $0}' | head -1)
  PROCESSOR_COUNT=$(grep -ioP 'processor\t:' /proc/cpuinfo | wc -l)

  # Colors
  G="\033[01;32m"
  R="\033[01;31m"
  D="\033[39m\033[2m"
  N="\033[0m"

  echo 
  echo -e "\e[01;38;44;5m########## 获取操作系统信息(Get information about computer system) ###########\e[0m"
  echo -e "[Login Info]\n"
  echo -e "USER: ${G}$(whoami)${N}"
  echo -e "You last logged in to ${G}${LAST_LOGIN_T}${N} of ${G}$(uname -n)${N} system with IP ${G}${LAST_LOGIN_IP}${N}, \nLast Login time is ${G}${LAST_LOGIN_TIME}${N}, Logout time is ${G}${LAST_LOGOUT_TIME}${N}.\n"

  echo -e "[System Info]\n"
  echo -e "  SYSTEM    : $(awk -F'[="]+' '/PRETTY_NAME/{print $2}' /etc/os-release)"
  echo -e "  KERNEL    : $(uname -sr)"
  echo -e "  Architecture : $(uname -m)"
  echo -e "  UPTIME    : ${UPTIME_DAYS} days ${UPTIME_HOURS} hours ${UPTIME_MINS} minutes ${UPTIME_SECS} seconds"
  echo -e "  CPU       : ${PROCESSOR_NAME} (${G}${PROCESSOR_COUNT}${N} vCPU)\n"
  echo -e "  MEMORY    : ${MEMORY_USED} MB / ${MEMORY_ALL} MB (${G}${MEMORY_PERCENTAGE}${N} Used)"
  echo -e "  LOAD AVG  : ${G}${LOAD1}${N} (1m), ${G}${LOAD5}${N} (5m), ${G}${LOAD15}${N} (15m)"
  echo -e "  PROCESSES : ${G}${PROCESS_ROOT}${N} (root), ${G}${PROCESS_USER}${N} (user), ${G}${PROCESS_ALL}${N} (total)"
  echo -e "  USERS     : ${G}$(users | wc -w)${N} users logged in"
  echo -e "  BASH      : ${G}${BASH_VERSION}${N}\n"

  echo -e "[Disk Usage]\n"
  mapfile -t DFH < <(df -h -x zfs -x squashfs -x tmpfs -x devtmpfs -x overlay --output=target,pcent,size,used | tail -n+2)
  for LINE in "${DFH[@]}"; do
      # Get disk usage
      DISK_USAGE=$(echo "${LINE}" | awk '{print $2}' | sed 's/%//')
      USAGE_WIDTH=$((("${DISK_USAGE}"*60)/100))

      # If the usage rate is <90%, the color is green, otherwise it is red
      if [ "${DISK_USAGE}" -gt 90 ]; then
          COLOR="${R}"
      else
          COLOR="${G}"
      fi

      # Print the used width
      BAR="[${COLOR}"
      for ((i=0; i<"${USAGE_WIDTH}"; i++)); do
          BAR+="="
      done

      # Print unused width
      BAR+=${D}
      for ((i="${USAGE_WIDTH}"; i<60; i++)); do
          BAR+="="
      done
      BAR+="${N}]"

      # Output
      echo "${LINE}" | awk '{ printf("Mounted: %-32s %s / %s (%s Used)\n", $1, $4, $3, $2); }' | sed -e 's/^/  /'
      echo -e "${BAR}" | sed -e 's/^/  /'
  done
  echo       

  log::success "[${COUNT}] This operation is completed!"
  sleep 1
  ((COUNT++))

}


# curl --insecure https://ipecho.net/plain

