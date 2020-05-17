#!/bin/bash
# @Desc:Centos7安装后初始化脚本
# @Author: WeiyiGeek
# @Time: 2020年5月6日 11:04:42
# @Version: 1.0

echo -e "\e[32m#########\n#网卡配置\n##########\e[0m"
sed -i 's/ONBOOT=no/ONBOOT=yes/g' /etc/sysconfig/network-scripts/ifcfg-ens192
sed -i 's/BOOTPROTO=dhcp/BOOTPROTO=static/g' /etc/sysconfig/network-scripts/ifcfg-ens192
sed -i 's/BOOTPROTO=\"dhcp\"/BOOTPROTO=\"static\"/g' /etc/sysconfig/network-scripts/ifcfg-ens192
cat >> /etc/sysconfig/network-scripts/ifcfg-ens192 <<EOF
IPADDR=10.10.107.192
NETMASK=255.255.255.0
GATEWAY=10.10.107.1
EOF
service network restart
echo nameserver 223.6.6.6 >> /etc/resolv.conf
echo -e"--[网卡配置结束]--"


echo -e "\e[32m#########\n#SSH服务配置\n#########\e[0m"
sed -i 's/#PermitRootLogin/PermitRootLogin/g' /etc/ssh/sshd_config
systemctl restart sshd
echo "--[SSH服务配置结束]--"


echo -e "\e[32m#########\n#Yum源设定\n#########\e[0m"
curl -o /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo
curl -o /etc/yum.repos.d/CentOS-epel.repo http://mirrors.aliyun.com/repo/epel-7.repo
yum clean all
yum makecache
yum update -y && yum upgrade -y &&  yum -y install epel*
echo "--[YUM替换更新应用软件完成]--"


echo -e "\e[32m#########\n#系统内核版本升级\n#########\e[0m"
rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
yum -y install https://www.elrepo.org/elrepo-release-7.el7.elrepo.noarch.rpm
yum --disablerepo="*" --enablerepo=elrepo-kernel repolist
yum --disablerepo="*" --enablerepo=elrepo-kernel list kernel*
yum -y --enablerepo=elrepo-kernel install kernel-ml.x86_64 kernel-ml-devel.x86_64 
awk -F \' '$1=="menuentry " {print i++ " : " $2}' /etc/grub2.cfg
sudo grub2-set-default 0
reboot
#yum -y --enablerepo=elrepo-kernel install kernel-ml-tools.x86_64 
#sudo grub2-set-default 0


echo -e "\n############################\n#安装常用的运维软件\n####################################\n"
#编译依赖
yum install -y gcc gcc-c++ openssl-devel bzip2-devel
#常规软件
yum install -y nano vim net-tools tree wget dos2unix unzip htop ncdu bash-completion
echo "--[安装安装完成]--"
