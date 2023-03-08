#!/bin/bash
#-----------------------------------------------------------------------#
# System security initiate hardening tool for Ubuntu 22.04 Server.
# WeiyiGeek <master@weiyigeek.top>
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


# 函数名称: svc_apport
# 函数用途: 禁用烦人的apport错误报告
# 函数参数: 无
function svc_apport()
{
  log::info "[${COUNT}] Disable Apport service"
  if [ -f /etc/default/apport ]; then
    cp /etc/default/apport ${BACKUPDIR}
    sed -i 's/enabled=.*/enabled=0/' /etc/default/apport
    systemctl stop apport.service
    systemctl disable apport.service
    systemctl mask apport.service >/dev/null 2>&1
  fi

  read -t ${VAR_VERIFY_TIMEOUT} -p "Please input, is service verificating (Y/N) : " VERIFY
  if [[ ${VERIFY:="N"} == "Y" || ${VERIFY:="N"} == "y" ]]; then
    systemctl status apport.service --no-pager
  else
    log::success "[${COUNT}] This operation is completed!"
  fi

  sleep 1
  ((COUNT++))
}


# 函数名称: svc_snapd
# 函数用途: 不使用snapd容器的环境下禁用或者卸载多余的snap软件及其服务
# 函数参数: 无
function svc_snapd()
{
  log::info "[${COUNT}] Disable Snapd service"
  sudo systemctl stop snapd snapd.socket
  sudo systemctl disable snapd snapd.socket

  read -t ${VAR_VERIFY_TIMEOUT} -p "Please input, is Remove snapd related files and their directories (Y/N) : " VERIFY
  if [[ ${VERIFY:="N"} == "Y" || ${VERIFY:="N"} == "y" ]]; then
    sudo apt autoremove --purge -y snapd
    sudo rm -rf ~/snap /snap /var/snap /var/lib/snapd /var/cache/snapd /run/snapd
  fi

  sudo systemctl daemon-reload
  log::success "[${COUNT}] This operation is completed!"
  sleep 1
  ((COUNT++))
}


# 函数名称: svc_cloud-init
# 函数用途: 非云的环境下禁用或者卸载多余的cloud-init软件及其服务
# 函数参数: 无

function svc_cloud-init()
{
  log::info "[${COUNT}] Disable Cloud-init service"
  sudo systemctl stop cloud-init.target cloud-init.service cloud-config.service cloud-init-local.service cloud-final.service
  sudo systemctl disable cloud-init.target cloud-init.service cloud-config.service cloud-init-local.service cloud-final.service
  sudo systemctl mask cloud-init.service cloud-config.service cloud-init-local.service cloud-final.service >/dev/null 2>&1
  
  # 禁用 Ubuntu 中的 cloud-init, 在 /etc/cloud 目录下创建 cloud-init.disable 文件(重启后生效)
  if [ ! -f /etc/cloud/cloud-init.disable ];then sudo touch /etc/cloud/cloud-init.disable;fi

  read -t ${VAR_VERIFY_TIMEOUT} -p "Please input, is Remove cloud-init related files and their directories (Y/N) : " VERIFY
  if [[ ${VERIFY:="N"} == "Y" || ${VERIFY:="N"} == "y" ]]; then
    sudo apt purge cloud-init -y
    sudo rm -rf /etc/cloud && sudo rm -rf /var/lib/cloud/   
  fi

  sudo systemctl daemon-reload
  log::success "[${COUNT}] This operation is completed!"
  sleep 1
  ((COUNT++))
}



# 函数名称: svc_debugshell
# 函数用途: 在系统启动时禁用debug-shell服务
# 函数参数: 无

function svc_debugshell()
{   
  log::info "[${COUNT}] Disable debug-shell service"

  systemctl stop debug-shell.service
  systemctl mask debug-shell.service >/dev/null 2>&1

  if [[ $VAR_VERIFY_RESULT == "Y" ]]; then
    systemctl status debug-shell.service --no-pager
  fi
  log::success "[${COUNT}] This operation is completed!"
  sleep 1
  ((COUNT++))
}
