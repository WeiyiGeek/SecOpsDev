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

# 函数名称: base_hostname
# 函数用途: 主机名称设置
# 函数参数: 无
function base_hostname () {
  log::info "[${COUNT}] Configure OS Hostname."
  log::info "[-] 系统主机名称配置."
  cp /etc/hosts ${BACKUPDIR}

    # 1.IP地址获取
    local IP
    IP=${VAR_IP%%/*}

  if [ "${HOSTNAME}" != "${VAR_HOSTNAME}" ] || [ "$(hostname -I)" != ${IP} ];then
    # 2.设置系统主机名称
    sudo hostnamectl set-hostname --static ${VAR_HOSTNAME} 

    # 3.替换主机hosts文件
    sed -i "s/127.0.1.1\s.\w.*$/127.0.1.1 ${VAR_HOSTNAME}/g" /etc/hosts
    grep -q "^\$(hostname -I)\s.\w.*$" /etc/hosts && sed -i "s/\$(hostname -I)\s.\w.*$/${IP} ${VAR_HOSTNAME}" /etc/hosts || echo "${IP} ${VAR_HOSTNAME}" >> /etc/hosts
  fi

    if [ $? == 0 ];then log::info "[${COUNT}] ${IP} ${VAR_HOSTNAME} write /etc/hosts" ;fi

  log::success "[${COUNT}] This operation is completed!"
  sleep 1
  ((COUNT++))
}


# 函数名称: ubuntu_mirror
# 函数用途: ubuntu 系统主机软件仓库镜像源
# 函数参数: 无
function ubuntu_mirror() {
  log::info "[${COUNT}] Configure os software mirror"
  log::info "[-] 设置主机软件仓库镜像源."

  local release
  cp /etc/apt/sources.list ${BACKUPDIR}
  # 1.根据主机发行版设置
  release=$(lsb_release -c -s)
  if [ ${release} == "jammy" ];then
sudo tee /etc/apt/sources.list <<'EOF'
# 清华大学 Mirrors - Ubuntu 22.04 jammy
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu jammy main restricted
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu jammy-updates main restricted
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu jammy universe
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu jammy-updates universe
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu jammy multiverse
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu jammy-updates multiverse
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu jammy-backports main restricted universe multiverse
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu jammy-security main restricted
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu jammy-security universe
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu jammy-security multiverse
EOF
  elif [ ${release} == "focal" ];then
sudo tee /etc/apt/sources.list <<'EOF'
# 阿里云 Mirrors - Ubuntu 20.04 focal
deb https://mirrors.aliyun.com/ubuntu/ focal main restricted universe multiverse
deb-src https://mirrors.aliyun.com/ubuntu/ focal main restricted universe multiverse
deb https://mirrors.aliyun.com/ubuntu/ focal-security main restricted universe multiverse
deb-src https://mirrors.aliyun.com/ubuntu/ focal-security main restricted universe multiverse
deb https://mirrors.aliyun.com/ubuntu/ focal-updates main restricted universe multiverse
deb-src https://mirrors.aliyun.com/ubuntu/ focal-updates main restricted universe multiverse
deb https://mirrors.aliyun.com/ubuntu/ focal-proposed main restricted universe multiverse
deb-src https://mirrors.aliyun.com/ubuntu/ focal-proposed main restricted universe multiverse
deb https://mirrors.aliyun.com/ubuntu/ focal-backports main restricted universe multiverse
deb-src https://mirrors.aliyun.com/ubuntu/ focal-backports main restricted universe multiverse
EOF
  elif [ ${release} == "bionic" ];then
sudo tee /etc/apt/sources.list <<'EOF'
# 阿里云 Mirrors - Ubuntu 18.04 focal
deb https://mirrors.aliyun.com/ubuntu/ bionic main restricted universe multiverse
deb https://mirrors.aliyun.com/ubuntu/ bionic-security main restricted universe multiverse
deb https://mirrors.aliyun.com/ubuntu/ bionic-updates main restricted universe multiverse
deb https://mirrors.aliyun.com/ubuntu/ bionic-proposed main restricted universe multiverse
deb https://mirrors.aliyun.com/ubuntu/ bionic-backports main restricted universe multiverse
deb-src https://mirrors.aliyun.com/ubuntu/ bionic main restricted universe multiverse
deb-src https://mirrors.aliyun.com/ubuntu/ bionic-security main restricted universe multiverse
deb-src https://mirrors.aliyun.com/ubuntu/ bionic-updates main restricted universe multiverse
deb-src https://mirrors.aliyun.com/ubuntu/ bionic-proposed main restricted universe multiverse
deb-src https://mirrors.aliyun.com/ubuntu/ bionic-backports main restricted universe multiverse
EOF
  fi
  sudo apt autoclean -y

  read -t ${VAR_VERIFY_TIMEOUT} -p "Please input, Perform system software update and upgrade. (Y/N) : " VERIFY
  if [[ ${VERIFY:="N"} == "Y" || ${VERIFY:="N"} == "y" ]]; then
    sudo apt update && sudo apt upgrade -y
  fi

# 补充：代理方式进行更新
# sudo apt autoclean && sudo apt -o Acquire::http::proxy="http://proxy.weiyigeek.top/" update && sudo apt -o Acquire::http::proxy="http://proxy.weiyigeek.top" upgrade -y
# sudo apt install -o Acquire::http::proxy="http://proxy.weiyigeek.top/" -y nano vim git unzip wget ntpdate dos2unix net-tools tree htop ncdu nload sysstat psmisc bash-completion fail2ban
  
  log::success "[${COUNT}] This operation is completed!"
  sleep 1
  ((COUNT++))
}


# 函数名称: ubuntu_software
# 函数用途: ubuntu 系统主机内核版本升级以常规软件安装
# 函数参数: 无
function ubuntu_software() {
  log::info "[${COUNT}] Installation and compilation environment and common software tools."
  
  # 1.系统更新
  log::info "[-] 系统软件源更新."
  sudo apt update && sudo apt upgrade -y

  # 2.安装系统所需的常规软件
  log::info "[-] 安装系统所需的常规软件."
  sudo apt install -y gcc g++ make 
  sudo apt install -y nano vim git unzip wget ntpdate dos2unix net-tools tree htop ncdu nload sysstat psmisc bash-completion fail2ban jq nfs-common rpcbind libpam-cracklib dialog man-db cron ufw iputils-ping
  
  # 3.针对 22.04 是否取消最小化软件安装.(不是后续安装部署软件太痛苦了)
  release=$(lsb_release -c -s)
  if [ ${release} == "jammy" ];then
    read -t ${VAR_VERIFY_TIMEOUT} -p "Please input,Do you want to cancel minimizing software installation. (Y/N) : " VERIFY
    if [[ ${VERIFY:="N"} == "Y" || ${VERIFY:="N"} == "y" ]]; then echo -e "y\n" | unminimize;fi
  fi

  log::success "[${COUNT}] This operation is completed!"
  sleep 1
  ((COUNT++))
}

# 函数名称: base_timezone
# 函数用途: 主机时间同步校准与时区设置
# 函数参数: 无
function base_timezone() {
  log::info "[${COUNT}] Configure OS Time and TimeZone."
  log::info "[-] 设置前的当前时间: $(date)"
  sudo cp /usr/share/zoneinfo/${VAR_TIMEZONE} /etc/localtime

  # 1.时区设置
  sudo timedatectl set-timezone ${VAR_TIMEZONE}
  # sudo dpkg-reconfigure tzdata  # 修改确认
  # sudo bash -c "echo 'Asia/Shanghai' > /etc/timezone" # 与上一条命令一样
 
  # 2.将当前的 UTC 时间写入硬件时钟 (硬件时间默认为UTC)

  sudo timedatectl set-local-rtc 0
  # 3.启用NTP时间同步：
  sudo timedatectl set-ntp yes

  # 4.校准时间服务器-时间同步(推荐使用chronyc进行平滑同步)
  sudo chronyc tracking

  # 5.手动校准-强制更新时间
  # chronyc -a makestep

  # 6.系统时钟同步硬件时钟
  # sudo hwclock --systohc
  sudo hwclock -w
  log::info "设置时间同步与时区后: $(date)"

  # 7.重启依赖于系统时间的服务
  sudo systemctl restart rsyslog.service crond.service

  log::success "[${COUNT}] This operation is completed!"
  sleep 1
  ((COUNT++))
}


# 函数名称: base_banner
# 函数用途: 远程本地登陆主机信息展示
# 函数参数: 无
function base_banner() {
  log::info "[${COUNT}] Configure OS Local or Remote Login Banner Tips."
  log::info "[-] 远程SSH登录前后提示警告Banner设置"
  # 1.SSH登录前警告Banner提示
  egrep -q "^\s*(banner|Banner)\s+\W+.*$" /etc/ssh/sshd_config && sed -ri "s/^\s*(banner|Banner)\s+\W+.*$/Banner \/etc\/issue/" /etc/ssh/sshd_config || \
  echo "Banner /etc/issue" >> /etc/ssh/sshd_config
sudo tee /etc/issue <<'EOF'
************************* [ 安全登陆 (Security Login) ] ************************
Authorized only. All activity will be monitored and reported.By Security Center.
Author: WeiyiGeek, Blog: https://www.weiyigeek.top

EOF
sudo tee /etc/issue.net <<'EOF'
************************* [ 安全登陆 (Security Login) ] *************************
Authorized only. All activity will be monitored and reported.By Security Center.
Author: WeiyiGeek, Blog: https://www.weiyigeek.top

EOF

  # 2.SSH登录后提示Banner提示
  # Disable motd-news
  if [ -f /etc/default/motd-news ];then
    cp /etc/default/motd-news ${BACKUPDIR}
    sed -i 's/ENABLED=.*/ENABLED=0/' /etc/default/motd-news
  else
    echo 'ENABLED=0' > /etc/default/motd-news
  fi
  systemctl stop motd-news.timer
  systemctl disable motd-news.timer
  systemctl mask motd-news.timer >/dev/null 2>&1

  # Disable defualt motd
  chmod -x /etc/update-motd.d/*
tee /etc/update-motd.d/00-custom-header <<'EOF'
#!/bin/bash
#-----------------------------------------------------------------------#
# System security initiate hardening tool for Ubuntu Server.
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

echo -e "\e[01;38;44;5m########################## 安全运维 (Security Operation) ############################\e[0m"
echo -e "${G}Login success.${N} Please execute the commands and operation data carefully.By WeiyiGeek."
echo -e "You are logged in to ${G}$(uname -n)${N}, Login time is $(/bin/date "+%Y-%m-%d %H:%M:%S").\n"
echo -e "[System Info]\n"
echo -e "  SYSTEM    : $(awk -F'[="]+' '/DESCRIPTION/{print $2}' /etc/lsb-release)"
echo -e "  KERNEL    : $(uname -sr)"
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
EOF
  # Add new motd
  chmod +x /etc/update-motd.d/00-custom-header 

  log::success "[${COUNT}] This operation is completed!"
  sleep 1
  ((COUNT++))
}




# 函数名称: base_reboot
# 函数用途: 是否进行重启或者关闭服务器
# 函数参数: 无
function base_reboot() {
  log::info "[${COUNT}] Do you want to restart or shut down the server."

  log::info "[-] 选择重启或者关闭服务器, 注意默认需要等待1分钟."
  read -t ${VAR_VERIFY_TIMEOUT} -p "Please input,Do you want to restart (Y) or shut down (N) the server. (Y/N) : " VERIFY
  if [[ ${VERIFY:="Y"} == "N" || ${VERIFY:="y"} == "n" ]];then
    shutdown --poweroff --no-wall
  else
    shutdown --reboot --no-wall
  fi

  log::success "[${COUNT}] This operation is completed!"
  sleep 1
  ((COUNT++))
}

