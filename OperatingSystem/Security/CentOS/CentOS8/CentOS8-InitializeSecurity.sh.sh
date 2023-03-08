#!/bin/bash
# @Desc:Centos8安装后初始化脚本
# @Author: WeiyiGeek
# @Time: 2020年5月6日 11:04:42
# @Version: 1.0

echo -e "\e[32m#########\n#网卡配置\n##########\e[0m"
nmcli device
nmcli conn show
nmcli conn add type ethernet con-name eth0 ifname ens192 ipv4.addr 100.20.172.242/24 ipv4.gateway 100.20.172.1 ipv4.dns '223.6.6.6,223.5.5.5' ipv4.method manual
nmcli conn up eth0
echo 'nameserver 223.5.5.5' > /etc/resolv.conf
echo "127.0.0.1 $(hostname)" > /etc/hosts
echo -e"--[网卡配置结束]--"


echo -e "\e[32m#########\n#SSH服务配置\n#########\e[0m"
echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config
echo 'PasswordAuthentication yes' >> /etc/ssh/sshd_config
systemctl restart sshd
echo "--[SSH服务配置结束]--"


echo -e "\e[32m#########\n#Yum源设定\n#########\e[0m"
curl -o /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-8.repo
dnf clean all
dnf makecache
#dnf -y install epel-release
dnf update -y && dnf upgrade -y && dnf repolist
echo "--[YUM替换更新应用软件完成]--"


echo -e "\e[32m#########\n#系统内核版本升级\n#########\e[0m"
rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
yum -y install https://www.elrepo.org/elrepo-release-8.el8.elrepo.noarch.rpm
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
dnf install -y gcc gcc-c++ openssl-devel bzip2-devel
#常规软件
dnf install -y nano vim net-tools tree wget dos2unix unzip htop ncdu bash-completion ntpdate
echo "--[安装安装完成]--".


