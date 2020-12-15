#!/bin/bash
# @FileName: CentOS7.x_initialize_Tools.sh
# @Desc: CentOS7.X安装后初始化脚本
# @Author: WeiyiGeek
# @Time: 2020年5月6日 11:04:42
# @Version: 1.2

## ----------------------------------------- ##
## 1.添加常用工具软件(服务器与VPS)与服务器IP地址一键修改函数
##
##
## ----------------------------------------- ##

## 需要调用函数名称
FUN_NAME=$1

## 网络配置 ##
NET_DIR=/etc/sysconfig/network-scripts/
NET_FILENAME=ifcfg-ens192
IPADDR=$2
GATEWAY=$3
function IPset(){
  echo -e "\e[32m#########\n#网络配置\n##########\e[0m"
  if [[ $# -lt 3 ]];then
    echo -e "\e[32m[*]Usage: $0 IP-Address Gateway \e[0m"
    echo -e "\e[32m[*]Usage: $0 192.168.1.99 192.168.1.1 \e[0m"
    exit 1
  fi
  cp /etc/sysconfig/network-scripts/${NET_FILENAME}{,.bak}
  sed -i 's/ONBOOT=no/ONBOOT=yes/g' /etc/sysconfig/network-scripts/${NET_FILENAME}
  sed -i 's/BOOTPROTO=dhcp/BOOTPROTO=static/g' /etc/sysconfig/network-scripts/${NET_FILENAME}
  sed -i 's/BOOTPROTO=\"dhcp\"/BOOTPROTO=\"static\"/g' /etc/sysconfig/network-scripts/${NET_FILENAME}
cat >> /etc/sysconfig/network-scripts/${NET_FILENAME} <<EOF
IPADDR=\$IPADDR
NETMASK=255.255.255.0
GATEWAY=\$GATEWAY
EOF

  if [[ ! -f ${NET_DIR}${NET_FILENAME} ]];then
    echo -e "\e[33m[*] Not Found ${NET_DIR}${NET_FILENAME}\e[0m"
    exit 2
  fi
  sed -i 's/^ONBOOT=.*$/ONBOOT="yes"/' ${NET_DIR}${NET_FILENAME}
  sed -i 's/^BOOTPROTO=.*$/BOOTPROTO="static"/' ${NET_DIR}${NET_FILENAME}
  sed -i "s/^IPADDR=.*$/IPADDR=${IPADDR}/" ${NET_DIR}${NET_FILENAME}
  sed -i "s/^GATEWAY=.*$/GATEWAY=${GATEWAY}/" ${NET_DIR}${NET_FILENAME}

  echo nameserver 223.6.6.6 >> /etc/resolv.conf
  echo -e "\e[32m[*] network configure file modifiy successful! restarting Network.........\e[0m"
  service network restart && ip addr
}



# 时区时间
# 系统时钟
cp /etc/localtime{,.bak}
ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
date
# 硬件时钟(系统时钟同步硬件时钟 )
hwclock --systohc
# 时间同步
ntpdate 192.168.10.254


## 网络配置
service network restart


## 远程配置
# echo -e "\e[32m#########\n#SSH服务配置\n#########\e[0m"
# echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config
# echo 'PasswordAuthentication yes' >> /etc/ssh/sshd_config
# systemctl restart sshd
# echo "--[SSH服务配置结束]--"


## 软件镜像源
echo -e "\e[32m#########\n#Yum源设定\n#########\e[0m"
curl -o /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo
curl -o /etc/yum.repos.d/CentOS-epel.repo http://mirrors.aliyun.com/repo/epel-7.repo
sed -i "s#mirrors.cloud.aliyuncs.com#mirrors.aliyun.com#g" /etc/yum.repos.d/CentOS-Base.repo
yum clean all && yum makecache
rpm --import http://mirrors.aliyun.com/centos/RPM-GPG-KEY-CentOS-7
yum --exclude=kernel*  update -y && yum upgrade -y &&  yum -y install epel*
echo "--[YUM替换更新应用软件完成]--"


## 系统内核
echo -e "\e[32m#########\n#系统内核版本升级\n#########\e[0m"
rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
yum -y install https://www.elrepo.org/elrepo-release-7.el7.elrepo.noarch.rpm
yum --disablerepo="*" --enablerepo=elrepo-kernel repolist
yum --disablerepo="*" --enablerepo=elrepo-kernel list kernel*
yum -y --enablerepo=elrepo-kernel install kernel-ml.x86_64 kernel-ml-devel.x86_64 
awk -F \' '$1=="menuentry " {print i++ " : " $2}' /etc/grub2.cfg
sudo grub2-set-default 0
#传统引导
grub2-mkconfig -o /boot/grub2/grub.cfg
grubby --default-kernel
reboot
#yum -y --enablerepo=elrepo-kernel install kernel-ml-tools.x86_64 
#sudo grub2-set-default 0


## 常用工具
echo -e "\n############################\n#安装常用的运维软件\n####################################\n"
#编译依赖
yum install -y gcc gcc-c++ openssl-devel bzip2-devel
#常规软件
yum install -y nano vim git unzip wget ntpdate dos2unix
yum install -y net-tools tree htop ncdu nload sysstat psmisc bash-completion fail2ban
echo "--[安装安装完成]--"
