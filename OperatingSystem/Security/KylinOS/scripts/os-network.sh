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


# 函数名称: net_config
# 函数用途: 主机IP地址与网关设置
# 函数参数: 无
function net_config () 
{
  log::info "[${COUNT}] Configure IP address and IP Gateway!"
  cp -a /etc/sysconfig/network-scripts/* ${BACKUPDIR}
  if [ ! -f /opt/init/ ];then mkdir -vp /opt/init/;fi
sudo tee /opt/init/network.sh <<'EOF'
#!/bin/bash
# @Author: WeiyiGeek
# @Description: Configure KylinOS / CentOS Server Network
# @E-mail: master@weiyigeek.top
# @Blog: https://www.weiyigeek.top
if [[ $# -lt 2 ]];then
  echo "Usage: $0 IP/NETMASK GATEWAY "
  echo "Usage: $0 192.168.12.12/24 192.168.12.1 "
  exit
fi
CURRENT_IP=$(hostname -I | cut -f 1 -d " ")
CURRENT_GATEWAY=$(hostname -I | cut -f 1,2,3 -d ".")
echo "Setting IP: ${1} GATEWAY: ${2}"
sudo sed -i -e "s#${CURRENT_IP}.*#${1}#" -e "s#gateway4:.*#gateway4: ${2}#" /etc/netplan/00-installer-config.yaml


read -t 5 -p "Heavy load network card, It is recommended to enter N during initialization (Y/N): " VERTIFY
if [[ ${VERIFY:="N"} == "Y" || ${VERIFY:="N"} == "y" ]]; then
  sudo nmcli c reload
  sudo nmcli d reapply ens3
else
  echo "Please reload the network card manually, run `sudo netplan apply`."
fi
EOF
  sudo chmod +x /opt/init/network.sh
  /opt/init/network.sh ${VAR_IP} ${VAR_GATEWAY}
  log::info "VAR_IP = ${VAR_IP} , VAR_GATEWAY = ${VAR_GATEWAY}"
  else
    log::error "Not configure networking!"
  fi

  log::success "[${COUNT}] This operation is completed!"
  sleep 1
  ((COUNT++))
}

# 函数名称: net_dns
# 函数用途: 设置主机DNS解析服务器
# 函数参数: 无

function net_dns () {
  log::info "[${COUNT}] Configure Domain Server."
  log::info "[${COUNT}] 配置主机上游DNS服务器."

  local flag
  cp /etc/systemd/resolved.conf ${BACKUPDIR}
  cp /run/systemd/resolve/resolv.conf ${BACKUPDIR}

  sed -i -e "s/^#FallbackDNS=.*/FallbackDNS=114.114.114.114/" -e "s/^#DNSSEC=.*/DNSSEC=allow-downgrade/" -e "s/^#DNSOverTLS=.*/DNSOverTLS=opportunistic/" /etc/systemd/resolved.conf

  for dns in ${VAR_DNS_SERVER[@]};do 
    grep -q "${dns}" /etc/systemd/resolved.conf 
    if [ $? != 0 ];then  
      log::info "nameserver ${dns}"
      sed -i "/#DNS=/i DNS=${dns}" /etc/systemd/resolved.conf;
    fi
  done
  
  systemctl restart systemd-resolved && systemctl enable systemd-resolved

  find /etc/resolv.conf -delete
  ln -s /run/systemd/resolve/resolv.conf /etc/resolv.conf

  if [[ ${VERIFY:="N"} == "Y" || ${VERIFY:="N"} == "y" ]]; then
    grep -Ev '^#|^$' /etc/resolv.conf | uniq
    echo
    grep -Ev '^#|^$' /etc/systemd/resolved.conf | uniq
  fi

  log::success "[${COUNT}] This operation is completed!"
  sleep 1
  ((COUNT++))
}