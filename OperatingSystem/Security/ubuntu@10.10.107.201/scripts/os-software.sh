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

# 函数名称: install_chrony
# 函数用途: 安装配置 chrony 时间同步服务器
# 函数参数: 无
function install_chrony() {
  log::info "[${COUNT}] Installation time sync chrony."

  # 方式1.Chrony 客户端配置
  apt install -y chrony
  cp /etc/chrony/chrony.conf ${BACKUPDIR}
  grep -E -q "^pool" /etc/chrony/chrony.conf | sed -i 's/^pool/# pool/g' /etc/chrony/chrony.conf 
  for ntp in ${VAR_NTP_SERVER[@]};do 
    log::info "ntp server => ${ntp}"
    if [[ ${ntp} =~ "ntp" ]];then
      echo "pool ${ntp} iburst maxsources 4" >> /etc/chrony/chrony.conf;
    else
      echo "pool ${ntp} iburst maxsources 1" >> /etc/chrony/chrony.conf;
    fi
  done
  systemctl enable chrony.service && systemctl restart chrony.service
  # chrony.conf
  # sudo tee /etc/chrony/chrony.conf <<'EOF'
  # confdir /etc/chrony/conf.d
  # pool ntp.aliyun.com iburst maxsources 4
  # pool ntp.tencent.com iburst maxsources 4
  # pool 192.168.10.254 iburst maxsources 1
  # pool 192.168.12.254 iburst maxsources 2
  # pool 192.168.4.254 iburst maxsources 3
  # sourcedir /run/chrony-dhcp
  # sourcedir /etc/chrony/sources.d
  # keyfile /etc/chrony/chrony.keys
  # driftfile /var/lib/chrony/chrony.drift
  # ntsdumpdir /var/lib/chrony
  # logdir /var/log/chrony
  # maxupdateskew 100.0
  # rtcsync
  # makestep 1 3
  # leapsectz right/UTC
  # EOF

  # 方式2
  # sudo ntpdate 192.168.10.254 || sudo ntpdate 192.168.12.254 || sudo ntpdate ntp1.aliyun.com
  # 方式3
  # echo 'NTP=192.168.10.254 192.168.4.254' >> /etc/systemd/timesyncd.conf
  # echo 'FallbackNTP=ntp.aliyun.com' >> /etc/systemd/timesyncd.conf
  # systemctl restart systemd-timesyncd.service
  if [[ ${VAR_VERIFY_RESULT} == "Y" ]];then systemctl status chrony.service -l --no-pager;fi

  log::success "[${COUNT}] This operation is completed!"
  sleep 1
  ((COUNT++))
}


# 函数名称: install_java
# 函数用途: 安装配置java环境
# 函数参数: 无
function install_java() {
  printf "\n\033[34mINFO: Install Java dependent environment \033[0m \n"

  # 1.定义JDK元件名称
  JDK_FILE="${1}"
  JDK_SRC="/usr/local/"
  JDK_DIR="/usr/local/jdk"

  # 2.解压与环境配置
  sudo tar -zxvf ${JDK_FILE} -C ${JDK_SRC}
  sudo rm -rf /usr/local/jdk 
  JDK_SRC=$(ls /usr/local/ | grep "jdk")
  sudo ln -s ${JDK_SRC} ${JDK_DIR}
  export PATH=${JDK_DIR}/bin:${PATH}
  sudo tee -a /etc/profile <<'EOF'
export JAVA_HOME=/usr/local/jdk
export JRE_HOME=/usr/local/jdk/jre
export CLASSPATH=.:$JAVA_HOME/lib/dt.jar:$JAVA_HOME/lib/tools.jar
export PATH=$JAVA_HOME/bin:$PATH
EOF

  # 3.安装版本验证
  java -version

}



## 函数名称: install_docker
## 函数用途: 在 Ubuntu 主机上安装最新版本的Docker
## 函数参数: 无
# 帮助: https://docs.docker.com/engine/install/ubuntu/
# Ubuntu Jammy 22.04 (LTS)
# Ubuntu Focal 20.04 (LTS)
# Ubuntu Bionic 18.04 (LTS)
# Ubuntu Xenial 16.04 (LTS)
function install_docker(){
  printf "\n\033[34mINFO: [*] Install docker environment \033[0m \n"

  # 1.卸载旧版本 
  sudo apt-get remove docker docker-engine docker.io containerd runc
  
  # 2.更新apt包索引并安装包以允许apt在HTTPS上使用存储库
  sudo apt-get install -y apt-transport-https  ca-certificates curl gnupg-agent lsb-release software-properties-common

  # 3.云主机环境判断
  if [ -n "$(wget -qO- -t1 -T2 169.254.0.23)" ]; then
      # Tencent Cloud
      DOCKER_COMPOSE_MIRRORS='https://get.daocloud.io'
      DOCKER_CE_MIRRORS='http://mirrors.tencentyun.com/docker-ce'
      DOCKER_MIRRORS='https://mirror.ccs.tencentyun.com'
  elif [ -n "$(wget -qO- -t1 -T2 100.100.100.200)" ]; then
      # Alibaba Cloud
      DOCKER_COMPOSE_MIRRORS='https://get.daocloud.io'
      DOCKER_CE_MIRRORS='http://mirrors.cloud.aliyuncs.com/docker-ce'
      DOCKER_MIRRORS='https://registry.cn-hangzhou.aliyuncs.com'
  else
      # Local
      DOCKER_COMPOSE_MIRRORS='https://github.com'
      DOCKER_CE_MIRRORS='https://download.docker.com'
      DOCKER_MIRRORS='https://docker.io'
  fi

  # 3.添加Docker官方GPG密钥 
  sudo curl -fsSL ${DOCKER_CE_MIRRORS}/linux/ubuntu/gpg | sudo apt-key add -

  # 5.设置稳定存储库(两种方式)
  sudo add-apt-repository \
   "deb [arch=$(dpkg --print-architecture)] ${DOCKER_CE_MIRRORS}/linux/ubuntu \
   $(lsb_release -cs) \
   stable"
  # echo "deb [arch=$(dpkg --print-architecture)] ${DOCKER_CE_MIRRORS}/linux/ubuntu $(lsb_release -cs) stable" >> /etc/apt/sources.list.d/docker.list

  # 6.Install Docker Engine 默认最新版本
  sudo apt-get update && sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose
  # 强制IPv4
  # sudo apt-get -o Acquire::ForceIPv4=true  install -y docker-ce=5:19.03.15~3-0~ubuntu-focal docker-ce-cli=5:19.03.15~3-0~ubuntu-focal containerd.io docker-compose

  # 7.安装特定版本的Docker引擎，请在repo中列出可用的版本
  apt-cache madison docker-ce
  # docker-ce | 5:20.10.6~3-0~ubuntu-focal| https://download.docker.com/linux/ubuntu focal/stable amd64 Packages
  # docker-ce | 5:19.03.15~3-0~ubuntu-focal | https://download.docker.com/linux/ubuntu  xenial/stable amd64 Packages
  # 使用第二列中的版本字符串安装特定的版本，例如:5:18.09.1~3-0~ubuntu-xenial。
  # $sudo apt-get install docker-ce=<VERSION_STRING> docker-ce-cli=<VERSION_STRING> containerd.io

  # 8.将当前用户加入docker用户组然后重新登陆当前用户使得低权限用户
  sudo gpasswd -a ${USER} docker

  # 9.进行 docker 后台守护进程配置
  mkdir -vp /etc/docker/
sudo tee /etc/docker/daemon.json <<-'EOF'
{
  "data-root":"/var/lib/docker",
  "registry-mirrors": ["https://xlx9erfu.mirror.aliyuncs.com"],
  "exec-opts": ["native.cgroupdriver=systemd"],
  "storage-driver": "overlay2",
  "log-driver": "json-file",
  "log-level": "warn",
  "log-opts": {
    "max-size": "100m",
    "max-file": "10"
  },
  "live-restore": true,
  "dns": ["223.6.6.6","114.114.114.114"],
  "insecure-registries": [ "harbor.weiyigeek.top"]
}
EOF

  # 9.自启与启动
  sudo systemctl daemon-reload
  sudo systemctl enable docker.service
  sudo systemctl restart docker.service

  # 10.验证安装的 docker 服务
  systemctl status docker.service -no-pager
  docker info
}


## 函数名称: install_cockercompose
## 函数用途: 在 Ubuntu 主机上安装最新版本的Dockercompose
## 函数参数: 无
function install_dockercompose(){
  printf "\n\033[34mINFO: [*] Install docker-compose environment \033[0m \n"
  # Install Docker Compose
  DOCKER_COMPOSE_MIRRORS='https://get.daocloud.io'
  # Default Version v2.10.0 (2022年8月20日 16:03:37)
  DOCKER_COMPOSE_VERSION=${1}
  curl -L ${DOCKER_COMPOSE_MIRRORS}/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION:="v2.10.0"}/docker-compose-"$(uname -s)"-"$(uname -m)" -o /usr/local/bin/docker-compose
  chmod +x /usr/local/bin/docker-compose
  ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
  # Verify Install
  docker-compose version
}

