#!/bin/bash
# @Author: WeiyiGeek
# @Description: KylinOS 10 Security Reinforce and System initialization
# @Create Time:  2023年3月4日 09:39:06
# @Last Modified time: 
# @E-mail: master@weiyigeek.top
# @Blog: https://www.weiyigeek.top
# @wechat: WeiyiGeeker
# @公众号: 极客全栈修炼
# @Github: https://github.com/WeiyiGeek/SecOpsDev/
# @Version: 1.0
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

# script execute language family
export LC_ALL=C.UTF-8

# tool version.
VAR_VERSION='1.0'
set -u -o pipefail

## 名称: msg_format
## 用途：传入多个字符串进行格式化为一行
## 参数: $@
function msg_format()
{
  local _VAR
  _VAR="$1"
  shift
  if (( $# > 1 )); then
    # 此处 ${_VAR} 解析为 MSG 变量的拼接
    printf -v "${_VAR}" "$@"
  else
    printf -v "${_VAR}" "%s" "$1"
  fi
}

## 名称: err 、info 、warning
## 用途：全局Log信息打印函数
## 参数: $@
## 补充: 文字颜色也可使用 $(tput setaf 1)
log::error() { 
  local MSG 
  msg_format MSG "$@"
  printf "\n[$(date +'%Y-%m-%dT%H:%M:%S')]-\033[31mERROR: ${MSG} \033[0m \n"
  printf "\n[$(date +'%Y-%m-%dT%H:%M:%S')]-ERROR: %s \n" "${MSG}" >> ${LOGFILE}
}
log::success() { 
  local MSG
  msg_format MSG "$@"
  printf "\n\033[32mSUCCESS: ${MSG} \033[0m \n"
  printf "\nSUCCESS: %s \n" "${MSG}" >> ${LOGFILE}
}
log::info() { 
  local MSG
  msg_format MSG "$@"
  printf "\n\033[34mINFO: ${MSG} \033[0m \n"
  printf "\nINFO: %s \n" "${MSG}" >> ${LOGFILE}
}
log::warning() { 
  local MSG
  msg_format MSG "$@"
  printf "\n\033[33mWARNING: ${MSG} \033[0m \n"
  printf "\nWARNING: %s \n" "${MSG}" >> ${LOGFILE}
}


## 名称: start::check
## 用途：全局Log信息打印函数
## 参数: 
start::check () {
  # Verify that you are an administrator
  if (( $EUID != 0 )); then
    printf '%s\n' "$(tput setaf 1)Error: script requires an account with root privileges. Try using 'sudo bash ${0}'.$(tput sgr0)" >&2
    exit 1
  fi

  # Verify if it is an Ubuntu distribution
  lsb_release -i | grep -Eqi "Ubuntu"
  if [ $? != 0 ]; then
    printf '%s\n' "$(tput setaf 1)Error: script is only available for Kylin systems.$(tput sgr0)" >&2
    exit 1
  fi

  # Verify bash.
  if [ "$SHELL" != "/bin/bash" ]; then
    printf '%s\n' "$(tput setaf 1)Error: script needs to be run with bash.$(tput sgr0)" >&2
    exit 1
  fi

  # Verify BACKUP DIR.
  if [ ! -e $BACKUPDIR ];then mkdir -vp ${BACKUPDIR} > /dev/null 2>&1; chattr +a ${BACKUPDIR};fi

  # Verify HISTORY DIR.
  if [ ! -e $HISTORYDIR ];then mkdir -vp ${HISTORYDIR} > /dev/null 2>&1; chmod -R 1777 ${HISTORYDIR}; chattr -R +a ${HISTORYDIR};fi
} 


## 名称: start::banner 
## 用途：程序执行时显示Banner
## 参数: 无
# 艺术字B格: http://www.network-science.de/ascii/
start::banner (){
  tput clear
  printf "\033[32m     __          __  _       _  _____           _       \033[0m\n"   
  printf "\033[32m     \ \        / / (_)     (_)/ ____|         | |      \033[0m\n"
  printf "\033[32m     \ \  /\  / /__ _ _   _ _| |  __  ___  ___| | __    \033[0m\n"
  printf "\033[32m       \ \/  \/ / _ \ | | | | | | |_ |/ _ \/ _ \ |/ /   \033[0m\n"
  printf "\033[32m       \  /\  /  __/ | |_| | | |__| |  __/  __/   <     \033[0m\n"
  printf "\033[32m         \/  \/ \___|_|\__, |_|\_____|\___|\___|_|\_\   \033[0m\n"
  printf "\033[32m                      __/ |                             \033[0m\n"
  printf "\033[32m                      |___/                             \033[0m\n"
  printf "\033[32m====================================================================== \033[0m\n"
  printf "\033[32m@ Desc: KylinOS Security Reinforce and System initialization  \033[0m\n"
  printf "\033[32m@ Mail bug reports: master@weiyigeek.top or pull request (pr) \033[0m\n"
  printf "\033[32m@ Author : WeiyiGeek                                          \033[0m\n"
  printf "\033[32m@ Follow me on Blog   : https://blog.weiyigeek.top/           \033[0m\n"
  printf "\033[32m@ Follow me on Wechat : https://weiyigeek.top/wechat.html?key=欢迎关注 \033[0m\n"
  printf "\033[32m@ Communication group : https://weiyigeek.top/visit.html \033[0m\n"
  printf "\033[32m====================================================================== \033[0m\n"
  sleep 1
  COUNT=1
}


## 名称: start::help 
## 用途：程序执行帮助
## 参数: 无
start::help ()
{
  echo -e "\nUsage: $0 [--start ] [--network] [--function] [--clear] [--version] [--help]"
  echo -e "Option: "
  echo -e "  --start            Start System initialization and security reinforcement."
  echo -e "  --network          Configure the system network and DNS resolution server."
  echo -e "  --function         PCall the specified shell function."
  echo -e "  --clear            Clear all system logs, cache and backup files."
  echo -e "  --version          Print version and exit."
  echo -e "  --help             Print help and exit."
  echo -e "\nMail bug reports or suggestions to <master@weiyigeek.top> or pull request (pr)."
  echo -e "current version : ${VAR_VERSION}"
  log::warning "温馨提示：使用前先请配置机器上网环境,若没有配置请在config文件夹中进行网络配置."
  exit 0
}


## 名称: start::script
## 用途：调用脚本中进行初始化函数
## 参数: 无
start::script () {
  base_hostname
  net_config
  net_dns
  
  base_mirror
  base_software

  svc_apport
  svc_snapd
  svc_cloud-init
  svc_debugshell

  base_banner

  install_chrony
  base_timezone

  sec_usercheck
  sec_userconfig
  sec_passpolicy
  sec_sshdpolicy
  sec_loginpolicy
  sec_historypolicy
  sec_supolicy
  sec_grubpolicy
  sec_firewallpolicy
  sec_ctrlaltdel
  sec_recyclebin
  sec_privilegepolicy

  optimize_kernel
  resources_limits
  swap_partition

  problem_usercrond
  problem_multipath

  system_clean
  base_reboot
}

## 名称: main 
## 用途：程序入口函数
## 参数: 无
main () {
  # Initialization Start
  start::banner

  # Load Configure File.
  source config/KylinOS.conf

  # Initialization Check.
  start::check

  # Create Log File.
  truncate -s0 "${LOGFILE}"

  # Load Scripts Function.
  for SCRIPTS in scripts/*.sh; do
    [[ -f ${SCRIPTS} ]] || break
    source "${SCRIPTS}"
  done

  if [ $# -eq 0 ];then
    start::help
  fi

while :; do
    [ -z "$1" ] && exit 0;
    case $1 in
        --start)
          start::script
          exit 0
        ;;
        --network)
          base_hostname
          net_config
          net_dns
          exit 0
        ;;
        --info)
          info_system
          exit 0
        ;;
        --function)
          echo -e "Call function : $2"
          $2
          exit 0
        ;;
        --clear)
          system_clean
          exit 0
        ;;
        --version)
          echo -e "$0 version : ${VAR_VERSION}"
          exit 0
        ;;
        --help)
          start::help
          exit 0
        ;;
        *)
          echo -e "Invalid option: $1"
          echo -e "Usage: $0 [--version] [--help]"
          echo -e "\nUse \"$0 --help\" for complete list of options"
          exit 1
        ;;
    esac
done
}

main $@

