#!/bin/bash
#-----------------------------------------------------------------------#
# System security initiate hardening tool for Ubuntu 22.04 Server.
# WeiyiGeek <master@weiyigeek.top>
# Blog : https://blog.weiyigeek.top
#
# The latest version of my giuthub can be found at:
# https://github.com/WeiyiGeek/SecOpsDev/
# 
# Copyright (C) 2020-2022 WeiyiGeek
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

# 函数名称: problem_usercrond
# 函数用途: 解决普通用户定时任务无法定时执行问题
# 函数参数: 无
function problem_usercrond () {
  log::info "[${COUNT}] Solve the problem that regular user scheduled tasks cannot be executed regularly."

  log::info "[-] 解决普通用户定时任务无法定时执行"
  cp -a /etc/pam.d/common-session-noninteractive ${BACKUPDIR}
  if ! grep -qi "session [success=1 default=ignore] pam_succeed_if.so" /etc/pam.d/common-session-noninteractive;then
    linenumber=`expr $(egrep -n "pam_unix.so\s$" /etc/pam.d/common-session-noninteractive | cut -f 1 -d ":") - 2`
    sudo sed -ri "${linenumber}a session [success=1 default=ignore] pam_succeed_if.so service in cron quiet use_uid" /etc/pam.d/common-session-noninteractive
  fi

  log::success "[${COUNT}] This operation is completed!"
  sleep 1
  ((COUNT++))
}


# 函数名称: problem_multipath
# 函数用途: 解决 ubuntu multipath add missing path 错误
# 函数参数: 无
function problem_multipath () {
  log::info "[${COUNT}] Solve the problem that ubuntu multipath add missing path error."

  # 1.配置多路径后端磁盘
  log::info "[-] 解决普通用户定时任务无法后台定时执行问题"
  cp -a /etc/multipath.conf ${BACKUPDIR}
  if ! grep -qi "blacklist" /etc/multipath.conf;then
  tee -a /etc/multipath.conf <<'EOF'
blacklist {
  devnode "^sda"
}
EOF
  fi
  # 2.重启multipath-tools服务
  systemctl restart multipath-tools.service

  log::success "[${COUNT}] This operation is completed!"
  sleep 1
  ((COUNT++))
}

