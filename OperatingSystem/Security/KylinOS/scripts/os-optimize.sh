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


# 函数名称: optimize_kernel
# 函数用途: 系统内核参数的优化配置
# 函数参数: 无
function optimize_kernel() {
  log::info "[${COUNT}] Optimal configuration of system kernel parameters."
  cp -a /etc/sysctl.conf ${BACKUPDIR}
  # 1.系统内核参数的配置文件/etc/sysctl.conf
  log::info "[-] 系统内核参数的优化配置 /etc/sysctl.conf"
  egrep -q "^(#)?net.ipv4.ip_forward.*" /etc/sysctl.conf && sed -ri "s|^(#)?net.ipv4.ip_forward.*|net.ipv4.ip_forward = 1|g"  /etc/sysctl.conf || echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
  # egrep -q "^(#)?net.bridge.bridge-nf-call-ip6tables.*" /etc/sysctl.conf && sed -ri "s|^(#)?net.bridge.bridge-nf-call-ip6tables.*|net.bridge.bridge-nf-call-ip6tables = 1|g" /etc/sysctl.conf || echo "net.bridge.bridge-nf-call-ip6tables = 1" >> /etc/sysctl.conf 
  # egrep -q "^(#)?net.bridge.bridge-nf-call-iptables.*" /etc/sysctl.conf && sed -ri "s|^(#)?net.bridge.bridge-nf-call-iptables.*|net.bridge.bridge-nf-call-iptables = 1|g" /etc/sysctl.conf || echo "net.bridge.bridge-nf-call-iptables = 1" >> /etc/sysctl.conf
  egrep -q "^(#)?net.ipv6.conf.all.disable_ipv6.*" /etc/sysctl.conf && sed -ri "s|^(#)?net.ipv6.conf.all.disable_ipv6.*|net.ipv6.conf.all.disable_ipv6 = 1|g" /etc/sysctl.conf || echo "net.ipv6.conf.all.disable_ipv6 = 1" >> /etc/sysctl.conf
  egrep -q "^(#)?net.ipv6.conf.default.disable_ipv6.*" /etc/sysctl.conf && sed -ri "s|^(#)?net.ipv6.conf.default.disable_ipv6.*|net.ipv6.conf.default.disable_ipv6 = 1|g" /etc/sysctl.conf || echo "net.ipv6.conf.default.disable_ipv6 = 1" >> /etc/sysctl.conf
  egrep -q "^(#)?net.ipv6.conf.lo.disable_ipv6.*" /etc/sysctl.conf && sed -ri "s|^(#)?net.ipv6.conf.lo.disable_ipv6.*|net.ipv6.conf.lo.disable_ipv6 = 1|g" /etc/sysctl.conf || echo "net.ipv6.conf.lo.disable_ipv6 = 1" >> /etc/sysctl.conf
  egrep -q "^(#)?net.ipv6.conf.all.forwarding.*" /etc/sysctl.conf && sed -ri "s|^(#)?net.ipv6.conf.all.forwarding.*|net.ipv6.conf.all.forwarding = 1|g" /etc/sysctl.conf || echo "net.ipv6.conf.all.forwarding = 1"  >> /etc/sysctl.conf
  egrep -q "^(#)?vm.max_map_count.*" /etc/sysctl.conf && sed -ri "s|^(#)?vm.max_map_count.*|vm.max_map_count = 262144|g" /etc/sysctl.conf || echo "vm.max_map_count = 262144"  >> /etc/sysctl.conf

  # 2.系统内核参数扩展优化配置
if ! grep -qi "# OS Resources Limits Config" /etc/sysctl.conf; then
tee -a /etc/sysctl.conf <<'EOF'
# Configuration of system kernel parameters
# 调整提升服务器负载能力之外,还能够防御小流量的Dos、CC和SYN攻击
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_tw_reuse = 1
# net.ipv4.tcp_tw_recycle = 1
net.ipv4.tcp_fin_timeout = 60
net.ipv4.tcp_synack_retries = 1
net.ipv4.tcp_syn_retries = 1
net.ipv4.tcp_fastopen = 3

# 优化TCP的可使用端口范围及提升服务器并发能力(注意一般流量小的服务器上没必要设置如下参数)
net.ipv4.tcp_keepalive_time = 7200
net.ipv4.tcp_max_syn_backlog = 8192
net.ipv4.tcp_max_tw_buckets = 16384
net.ipv4.ip_local_port_range = 1024 65535

# 优化核套接字TCP的缓存区
net.core.netdev_max_backlog = 8192
net.core.somaxconn = 8192
net.core.rmem_max = 12582912
net.core.rmem_default = 6291456
net.core.wmem_max = 12582912
net.core.wmem_default = 6291456

# 内存缓存IO优化
vm.dirty_background_ratio = 5
vm.dirty_ratio = 10
EOF
fi

  if [[ ${VAR_VERIFY_RESULT} == "Y" ]];then sysctl -p;fi

  log::success "[${COUNT}] This operation is completed!"
  sleep 1
  ((COUNT++))
} 

# 函数名称: resources_limits
# 函数用途: 系统资源文件打开句柄数优化配置
# 函数参数: 无
function resources_limits() {
  log::info "[${COUNT}] Optimize ulimit for high concurrency situations."
  log::info "[-] Linux 系统的最大进程数和最大文件打开数限制."
  cp -a /etc/security/limits.conf ${BACKUPDIR}
  egrep -q "^\s*ulimit -HSn\s+\w+.*$" /etc/profile && sed -ri "s/^\s*ulimit -HSn\s+\w+.*$/ulimit -HSn 655350/" /etc/profile || echo "ulimit -HSn 655350" >> /etc/profile
  egrep -q "^\s*ulimit -HSu\s+\w+.*$" /etc/profile && sed -ri "s/^\s*ulimit -HSu\s+\w+.*$/ulimit -HSu 655350/" /etc/profile || echo "ulimit -HSu 655350" >> /etc/profile
  if ! grep -qi "# OS Resources Limits Config" /etc/security/limits.conf; then
    sed -i 's/^# End of file*//' /etc/security/limits.conf
    {
      echo '# OS Resources Limits Config'
      echo '* soft nofile 655350'
      echo '* hard nofile 655350'
      echo '* soft nproc  unlimited'
      echo '* hard nproc  unlimited'
      echo '* soft core   unlimited'
      echo '* hard core   unlimited'
      echo '# End of file'
    } >> /etc/security/limits.conf
  fi

  if [[ $VAR_VERIFY_RESULT == "Y" ]]; then grep -Ev '^#|^$' /etc/security/limits.conf | uniq;fi

  log::success "[${COUNT}], this operation is completed!"
  sleep 1
  ((COUNT++))
}


# 函数名称: swap_partition
# 函数用途: 创建系统swap分区
# 函数参数: 无
function swap_partition() {
  log::info "[${COUNT}] Create system swap partition."
  read -t ${VAR_VERIFY_TIMEOUT} -p "Please input, Create swap partition. (Y/N) : " VERIFY
  if [[ ${VERIFY:="N"} == "Y" || ${VERIFY:="N"} == "y" ]]; then
     # 1.验证当前内存大小
    MEM=$(free -m | awk '/Mem:/{print $2}')
    if [ "$MEM" -le 1280 ]; then
      MEM_LEVEL=1G
    elif [ "$MEM" -gt 1280 ] && [ "$MEM" -le 2500 ]; then
      MEM_LEVEL=2G
    elif [ "$MEM" -gt 2500 ] && [ "$MEM" -le 3500 ]; then
      MEM_LEVEL=3G
    elif [ "$MEM" -gt 3500 ] && [ "$MEM" -le 4500 ]; then
      MEM_LEVEL=4G
    elif [ "$MEM" -gt 4500 ] && [ "$MEM" -le  8000 ]; then
      MEM_LEVEL=6G
    elif [ "$MEM" -gt 8000 ]; then
      MEM_LEVEL=8G
    fi

    # 2.根据内存大小划分对应的swap分区并自动挂载
    if [ "$(free -m | awk '/Swap:/{print $2}')" == '0' ]; then
      fallocate -l "${MEM_LEVEL}" /swapfile
      chmod 600 /swapfile
      mkswap /swapfile >/dev/null 2>&1
      swapon /swapfile
      sed -i "/swap/d" /etc/fstab
      echo "/swapfile swap swap defaults 0 0" >> /etc/fstab
    fi

    # 3.swap分区内核参数调整
    egrep -q "^\s*vm.swappiness.*$" /etc/sysctl.conf && sed -ri "s/^\s*vm.swappiness.*$/vm.swappiness = 10/" /etc/sysctl.conf || echo "vm.swappiness = 10" >> /etc/sysctl.conf
    egrep -q "^\s*vm.vfs_cache_pressure.*$" /etc/sysctl.conf && sed -ri "s/^\s*vm.vfs_cache_pressure.*$/vm.vfs_cache_pressure = 501/" /etc/sysctl.conf || echo "vm.vfs_cache_pressure = 50" >> /etc/sysctl.conf

    sysctl -p >/dev/null 2>&1

    if [[ $VAR_VERIFY_RESULT == "Y" ]]; then
      swapon --show 
      echo .
      free -h
      echo .
      grep -Ev '^#|^$' /etc/fstab | uniq
    fi
  fi


  log::success "[${COUNT}], this operation is completed!"
  sleep 1
  ((COUNT++))
}