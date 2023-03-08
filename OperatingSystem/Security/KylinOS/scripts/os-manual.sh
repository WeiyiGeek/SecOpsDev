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


# 名称: disk_lvm_manager
# 用途: KylinOS 操作系统磁盘LVM逻辑卷添加与配置(手动扩容流程)
# 参数: 无
function disk_lvm_manager() {
  printf "\n\033[34mINFO: [*] Manual System LVM Manager \033[0m \n"
  echo -e "\n[系统分区信息]: df -Th && lsblk"
  sudo df -Th
  sudo lsblk
  echo -e "\n[磁盘信息]: fdisk -l"
  sudo fdisk -l
  echo -e "\n[查看PV物理卷]: pvscan"
  sudo pvscan
  echo -e "\n[查看VGS虚拟卷]: vgs"
  sudo vgs
  echo -e "\n[扫描LVS逻辑卷]: lvscan"
  sudo lvscan
  echo -e "\n[手动扩展分区]: KylinOS"
  echo -e "\n lvextend -L +100G /dev/klas/root"
  echo -e "\n[刷新扩展分区]: KylinOS"
  echo -e "\n xfs_growfs  /dev/mapper/klas-root"
  echo -e "\n[查看扩展分区]: lsblk"
  sudo lsblk
}