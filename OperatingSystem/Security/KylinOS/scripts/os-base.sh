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
    sed -i "s/127.0.0.1   /127.0.0.1 ${VAR_HOSTNAME}/g" /etc/hosts
    sed -i "s/::1       /::1 ${VAR_HOSTNAME}/g" /etc/hosts
    grep -q "^\$(hostname -I)\s.\w.*$" /etc/hosts && sed -i "s/\$(hostname -I)\s.\w.*$/${IP} ${VAR_HOSTNAME}" /etc/hosts || echo "${IP} ${VAR_HOSTNAME}" >> /etc/hosts
  fi

    if [ $? == 0 ];then log::info "[${COUNT}] ${IP} ${VAR_HOSTNAME} write /etc/hosts" ;fi

  log::success "[${COUNT}] This operation is completed!"
  sleep 1
  ((COUNT++))
}


# 函数名称: base_mirror
# 函数用途: kylinOS 系统主机软件仓库镜像源
# 函数参数: 无
function base_mirror() {
  log::info "[${COUNT}] Configure os software mirror"
  log::info "[-] 设置主机软件仓库镜像源."

  local release
  cp /etc/yum.repos.d/kylin_x86_64.repo ${BACKUPDIR}
  # 1.根据主机发行版设置
  # (Tercel) 版本是 麒麟 V10 SP1 版本，
  # (Sword)  版本是 麒麟 V10 SP2 版本，
  # (Lance)  版本是 麒麟 V10 SP3 版本，
  release=$(grep -e "^VERSION=" /etc/os-release | cut -f 2 -d "=" | tr -d '[:punct:][:space:]')
  if [ ${release} == "V10Lance" ];then
sudo tee /etc/yum.repos.d/kylin_x86_64.repo <<'EOF'
### Kylin Linux Advanced Server 10 (SP3) - os repo ###
[ks10-adv-os]
name = Kylin Linux Advanced Server 10 - Os
baseurl = https://update.cs2c.com.cn/NS/V10/V10SP3/os/adv/lic/base/$basearch/
gpgcheck = 1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-kylin
enabled = 1

[ks10-adv-updates]
name = Kylin Linux Advanced Server 10 - Updates
baseurl = https://update.cs2c.com.cn/NS/V10/V10SP3/os/adv/lic/updates/$basearch/
gpgcheck = 1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-kylin
enabled = 1

[ks10-adv-addons]
name = Kylin Linux Advanced Server 10 - Addons
baseurl = https://update.cs2c.com.cn/NS/V10/V10SP3/os/adv/lic/addons/$basearch/
gpgcheck = 1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-kylin
enabled = 0
EOF
echo "8" > /etc/yum/vars/centos_version
curl -o /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-8.repo
sed -i 's/$releasever/$centos_version/g' /etc/yum.repos.d/CentOS-Base.repo
  elif [[ ${release} == "V10Sword" ]];then
    echo "暂未使用麒麟 V10 Sword SP2 版本，请自行百度搜索,镜像源!"
  fi
  elif [[ ${release} == "V10Tercel" ]];then
    echo "暂未使用麒麟 V10 Tercel SP1 版本，请自行百度搜索,镜像源!"
  fi
  else
    echo "暂未使用麒麟除 V10 以外的系统版本，请自行百度搜索,镜像源!"
  fi
  sudo yum clean all -y && sudo yum makecache

  read -t ${VAR_VERIFY_TIMEOUT} -p "Please input, Perform system software update and upgrade. (Y/N) : " VERIFY
  if [[ ${VERIFY:="N"} == "Y" || ${VERIFY:="N"} == "y" ]]; then
    sudo yum update -y && sudo yum upgrade -y
  fi

  log::success "[${COUNT}] This operation is completed!"
  sleep 1
  ((COUNT++))
}


# 函数名称: base_software
# 函数用途: kylinOS 系统主机内核版本升级以常规软件安装
# 函数参数: 无
function base_software() {
  log::info "[${COUNT}] Installation and compilation environment and common software tools."
  
  # 1.系统更新
  log::info "[-] 系统软件源更新."
  sudo yum update && sudo yum upgrade -y && dnf repolist

  # 2.安装系统所需的常规软件
  log::info "[-] 安装系统所需的常规软件."
  sudo dnf install -y gcc make
  sudo dnf install -y nano vim git unzip wget ntpdate dos2unix net-tools tree htop  sysstat psmisc bash-completion jq rpcbind  dialog nfs-utils

  # 补充：代理方式进行更新
  # echo "proxy=http://127.0.0.1:8080/" >> /etc/yum.conf
  # sudo yum clean all -y && sudo yum update -y && sudo yum upgrade -y
  # sudo yum install -y 软件包

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
  sudo cp -a /usr/share/zoneinfo/${VAR_TIMEZONE} /etc/localtime

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
  egrep -q "^\s*(banner|Banner)\s+\W+.*$" /etc/ssh/sshd_config && sed -ri "s/^\s*(banner|Banner)\s+\W+.*$/Banner \/etc\/issue.net/" /etc/ssh/sshd_config || \
  echo "Banner /etc/issue.net" >> /etc/ssh/sshd_config
sudo tee /etc/issue <<'EOF'
************************* [ 安全登陆 (Security Login) ] ************************
Authorized users only. All activity will be monitored and reported.By Security Center.
Author: WeiyiGeek

EOF
sudo tee /etc/issue.net <<'EOF'
************************* [ 安全登陆 (Security Login) ] *************************
Authorized users only. All activity will be monitored and reported.By Security Center.
Author: WeiyiGeek, Blog: https://www.weiyigeek.top

EOF

  # 2.本地控制台与SSH登录后提示自定义提示信息
tee /etc/motd <<'EOF'

Welcome to IT Cloud Computer Service!
If the server is abnormal, please contact WeiyiGeek  (IT-Security-Center)

                   _ooOoo_
                  o8888888o
                  88" . "88
                  (| -_- |)
                  O\  =  /O
               ____/`---'\____
             .'  \\|     |//  `.
            /  \\|||  :  |||//  \
           /  _||||| -:- |||||-  \
           |   | \\\  -  /// |   |
           | \_|  ''\---/''  |   |
           \  .-\__  `-`  ___/-. /
         ___`. .'  /--.--\  `. . __
      ."" '<  `.___\_<|>_/___.'  >'"".
     | | :  `- \`.;`\ _ /`;.`/ - ` : | |
     \  \ `-.   \_ __\ /__ _/   .-` /  /
======`-.____`-.___\_____/___.-`____.-'======
                   `=---='
 
 
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
           佛祖保佑       永不死机
           心外无法       法外无心

EOF

tee /usr/local/bin/00-custom-header <<'EOF'
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
echo -e "\e[01;38;44;5m########################## 安全运维 (Security Operation) ############################\e[0m"
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
EOF
  # Add motd Execute permissions
  chmod +x /usr/local/bin/00-custom-header 

  # Add motd to /etc/profile files.
  if [ $(grep -c "00-custom-header" /etc/profile) -eq 0 ];then 
    echo "/usr/local/bin/00-custom-header" >> /etc/profile
  else
    log::info "Custom-header already exists in the /etc/profile file "
  fi

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

