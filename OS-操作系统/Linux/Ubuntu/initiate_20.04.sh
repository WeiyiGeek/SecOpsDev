#!/bin/bash
# Description: Ubuntu 20.04 TLS Initiate
# Author: WeiyiGeek
# CreateTime: 2020年9月1日 16:43:33
# Version: 2.1
#-------------------------------------------------#
# 脚本主要功能说明:
# (1) 
#




# Shell脚本错误处理
set -o errexit
set -o pipefail
# set -o xtrace

# 全局Log函数
log::err() {
  printf "[$(date +'%Y-%m-%dT%H:%M:%S.%N%z')]: \033[31mERROR: \033[0m$@\n"
}
log::info() {
  printf "[$(date +'%Y-%m-%dT%H:%M:%S.%N%z')]: \033[32mINFO: \033[0m$@\n"
}
log::warning() {
  printf "[$(date +'%Y-%m-%dT%H:%M:%S.%N%z')]: \033[33mWARNING: \033[0m$@\n"
}



# IP=192.168.1.2
# GATEWAY=192.168.1.1
# SSHPORT=20211


# IP地址脚本设置 # 
sudo cp /etc/netplan/00-installer-config.yaml{,.bak}
# sudo sed -i "s#10.10.107.202##g" /etc/netplan/00-installer-config.yaml
# sudo sed -i "s#10.10.107.1##g" /etc/netplan/00-installer-config.yaml
# sudo tee ~/network.sh <<'EOF'
# if [[ $# -gt 2 ]];then
#   echo "Usage: $0 IP Gateway"
#   exit
# fi
# echo "IP:${1} # GATEWAY:${2}"
# sudo sed -i "s#10.10.107.202#${1}#g" /etc/netplan/00-installer-config.yaml
# sudo sed -i "s#10.10.107.1#${2}#g" /etc/netplan/00-installer-config.yaml
# EOF
# sudo netplan apply
mkdir ~/init/
sudo tee ~/init/network.sh <<'EOF'
#!/bin/bash
CURRENT_IP=$(hostname -I | cut -f 1 -d " ")
GATEWAY=$(hostname -I | cut -f 1,2,3 -d ".")
if [[ $# -lt 2 ]];then
  echo "Usage: $0 IP Gateway"
  exit
fi
echo "IP:${1} # GATEWAY:${2}"
sudo sed -i "s#${CURRENT_IP}#${1}#g" /etc/netplan/00-installer-config.yaml
sudo sed -i "s#${GATEWAY}.1#${2}#g" /etc/netplan/00-installer-config.yaml
netplan apply
EOF
sudo chmod +x ~/init/network.sh
sudo ~/init/network.sh ${IP} ${GATEWAY}


# 软件源设置与系统更新 #
sudo cp /etc/apt/sources.list{,.bak}
sudo tee /etc/apt/sources.list <<'EOF'
#阿里云Mirrors - Ubuntu
deb http://mirrors.aliyun.com/ubuntu/ focal main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ focal main restricted universe multiverse

deb http://mirrors.aliyun.com/ubuntu/ focal-security main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ focal-security main restricted universe multiverse

deb http://mirrors.aliyun.com/ubuntu/ focal-updates main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ focal-updates main restricted universe multiverse

deb http://mirrors.aliyun.com/ubuntu/ focal-proposed main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ focal-proposed main restricted universe multiverse

deb http://mirrors.aliyun.com/ubuntu/ focal-backports main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ focal-backports main restricted universe multiverse
EOF

# 卸载多余软件
sudo systemctl stop snapd snapd.socket #停止snapd相关的进程服务
sudo apt autoremove --purge -y snapd
sudo systemctl daemon-reload


# sudo apt autoclean && sudo apt -o Acquire::http::proxy="http://192.168.12.215:3128/" update && sudo apt -o Acquire::http::proxy="http://192.168.12.215:3128" upgrade -y
sudo apt autoclean && sudo apt update && sudo apt upgrade -y


# 常规软件安装
sudo apt install -o Acquire::http::proxy="http://192.168.12.215:3128/" -y nano vim git unzip wget ntpdate dos2unix net-tools tree htop ncdu nload sysstat psmisc bash-completion fail2ban
sudo apt install -y nano vim git unzip wget ntpdate dos2unix net-tools tree htop ncdu nload sysstat psmisc bash-completion fail2ban


# 时间时区同步
# docker run -d --rm --cap-add SYS_TIME -e ALLOW_CIDR=0.0.0.0/0 -p 123:123/udp geoffh1977/chrony
date -R 
sudo cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
ntpdate 192.168.10.254 || ntpdate 192.168.12.215
sudo hwclock --systohc     # 系统时钟同步硬件时钟
# tzselect
# TZ='Asia/Shanghai';export TZ



############################
#######   安全运维   ########
############################
sudo tee /opt/remove.sh <<'EOF'
#!/bin/sh
#定义文件夹目录.trash
home=$(env | grep ^HOME= | cut -c 6-)
trash="/.trash"
deltime=$(date +%Y%m%d-%H%M%S)
TRASH_DIR="${home}${trash}/${deltime}"
# 建立回收站目录当不存在的时候
if [ ! -e ${TRASH_DIR} ];then
   mkdir -p ${TRASH_DIR}
fi
for i in $*;do
	#定义秒时间戳
	STAMP=`date +%s`
	#得到文件名称(非文件夹)，参考man basename
	fileName=`basename $i`
	#将输入的参数，对应文件mv至.trash目录，文件后缀，为当前的时间戳
	mv $i ${TRASH_DIR}/${fileName}.${STAMP}
done
EOF
sudo chmod +775 /opt/remove.sh
sudo chmod +x /opt/remove.sh

sudo tee -a /etc/bashrc <<'EOF'
umask 022
# User specific aliases and functions
alias rm="sh /opt/remove.sh"
EOF

source /etc/bashrc 


############################
####### 安全加固配置 ########
############################
# ssh 安全设置
sudo sed -i "s#X11Forwarding yes#X11Forwarding no#g" /etc/ssh/sshd_config
# 严格模式
sudo egrep -q "^\s*StrictModes\s+.+$" /etc/ssh/sshd_config && sed -ri "s/^(#)?\s*StrictModes\s+.+$/StrictModes yes/" /etc/ssh/sshd_config || echo "StrictModes yes" >> /etc/ssh/sshd_config
# 缺省端口改变成为制定端口，重启服务需要 setenforce 0 临时关闭Selinux
sudo egrep -q "^\s*Port\s+.+$" /etc/ssh/sshd_config && sed -ri "s/^(#)?\s*Port\s+.+$/Port ${SSHPORT}/" /etc/ssh/sshd_config || echo "Port ${SSHPORT}" >> /etc/ssh/sshd_config

# 禁用端口转发
sudo egrep -q "^\s*AllowTcpForwarding\s+.+$" /etc/ssh/sshd_config && sed -ri "s/^(#)?\s*AllowTcpForwarding\s+.+$/AllowTcpForwarding no/" /etc/ssh/sshd_config || \
echo "AllowTcpForwarding no" >> /etc/ssh/sshd_config
sudo egrep -q "^\s*AllowAgentForwarding\s+.+$" /etc/ssh/sshd_config && sed -ri "s/^(#)?\s*AllowAgentForwarding\s+.+$/AllowAgentForwarding no/" /etc/ssh/sshd_config || echo "AllowAgentForwarding no" >> /etc/ssh/sshd_config

# CentOS7 (缺省IgnoreRhosts yes) 关闭禁用用户的 .rhosts 文件  ~/.ssh/.rhosts 来做为认证
egrep -q "^(#)?\s*IgnoreRhosts\s+.+$" /etc/ssh/sshd_config && sed -ri "s/^(#)?\s*IgnoreRhosts\s+.+$/IgnoreRhosts yes/" /etc/ssh/sshd_config || echo "IgnoreRhosts yes" >> /etc/ssh/sshd_config

# 重置SSH启动端口后，防止因为Selinux无法进行重启ssh应用;
# 禁止root远程登录（暂不配置）
egrep -q "^\s*PermitRootLogin\s+.+$" /etc/ssh/sshd_config && sed -ri "s/^\s*PermitRootLogin\s+.+$/PermitRootLogin no/" /etc/ssh/sshd_config || echo "PermitRootLogin no" >> /etc/ssh/sshd_config


# SSH登录前警告Banner
echo "**************WARNING**************" > /etc/issue;echo "Authorized only. All activity will be monitored and reported." >> /etc/issue
egrep -q "^\s*(banner|Banner)\s+\W+.*$" /etc/ssh/sshd_config && sed -ri "s/^\s*(banner|Banner)\s+\W+.*$/Banner \/etc\/issue/" /etc/ssh/sshd_config || \
echo "Banner /etc/issue" >> /etc/ssh/sshd_config
# SSH登录后Banner
sed -i '/^fi/a\\n\necho "\\e[1;37;42;5m################# WeiyiGeek - IT ###################\\e[0m"\necho "\\e[33m********************WARNING******************\\e[0m"\necho "\\e[32mLogin success. All activity will be monitored and reported.\\e[0m"' /etc/update-motd.d/00-header

systemctl restart sshd



# 用户的umask安全配置
echo \*\*\*\* 修改umask为022  \*\*\*\* 
egrep -q "^\s*umask\s+\w+.*$" /etc/profile && sed -ri "s/^\s*umask\s+\w+.*$/umask 022/" /etc/profile || echo "umask 022" >> /etc/profile
# egrep -q "^\s*umask\s+\w+.*$" /etc/csh.login && sed -ri "s/^\s*umask\s+\w+.*$/umask 022/" /etc/csh.login || echo "umask 022" >>/etc/csh.login
# egrep -q "^\s*umask\s+\w+.*$" /etc/csh.cshrc && sed -ri "s/^\s*umask\s+\w+.*$/umask 022/" /etc/csh.cshrc || echo "umask 022" >> /etc/csh.cshrc
egrep -q "^\s*umask\s+\w+.*$" /etc/bashrc && sed -ri "s/^\s*umask\s+\w+.*$/umask 022/" /etc/bashrc || echo "umask 022" >> /etc/bashrc

# 用户目录缺省访问权限设置
echo \*\*\*\* 设置用户目录默认权限为022
egrep -q "^\s*(umask|UMASK)\s+\w+.*$" /etc/login.defs && sed -ri "s/^\s*(umask|UMASK)\s+\w+.*$/UMASK 022/" /etc/login.defs || echo "UMASK 022" >> /etc/login.defs

# 重要目录和文件的权限设置
echo \*\*\*\* 设置重要目录和文件的权限
chmod 755 /etc; 
chmod 777 /tmp; 
chmod 700 /etc/inetd.conf&>/dev/null 2&>/dev/null; 
chmod 755 /etc/passwd; 
chmod 755 /etc/shadow; 
chmod 644 /etc/group; 
chmod 755 /etc/security; 
chmod 644 /etc/services; 
chmod 750 /etc/rc*.d



echo \*\*\*\* 口令生成周期最小14天最大180天预警14前天 \*\*\*\*
egrep -q "^\s*PASS_MAX_DAYS\s+\S*(\s*#.*)?\s*$" /etc/login.defs && sed -ri "s/^(\s*)PASS_MAX_DAYS\s+\S*(\s*#.*)?\s*$/\PASS_MAX_DAYS  180/" /etc/login.defs || echo "PASS_MAX_DAYS  180" >> /etc/login.defs
egrep -q "^\s*PASS_MIN_DAYS\s+\S*(\s*#.*)?\s*$" /etc/login.defs && sed -ri "s/^(\s*)PASS_MIN_DAYS\s+\S*(\s*#.*)?\s*$/\PASS_MIN_DAYS  14/" /etc/login.defs || echo "PASS_MIN_DAYS  14" >> /etc/login.defs
egrep -q "^\s*PASS_WARN_AGE\s+\S*(\s*#.*)?\s*$" /etc/login.defs && sed -ri "s/^(\s*)PASS_WARN_AGE\s+\S*(\s*#.*)?\s*$/\PASS_WARN_AGE  14/" /etc/login.defs || echo "PASS_WARN_AGE  14" >> /etc/login.defs



# 配置满足策略的root密码"
echo
echo \*\*\*\*  配置满足策略的root密码 \*\*\*\* 
echo  ${ROOTPASS} | passwd --stdin root

echo \*\*\*\* 锁定与设备运行、维护等工作无关的账号 \*\*\*\* 
passwd -l adm&>/dev/null 2&>/dev/null; passwd -l daemon&>/dev/null 2&>/dev/null; passwd -l bin&>/dev/null 2&>/dev/null; passwd -l sys&>/dev/null 2&>/dev/null; passwd -l lp&>/dev/null 2&>/dev/null; passwd -l uucp&>/dev/null 2&>/dev/null; passwd -l nuucp&>/dev/null 2&>/dev/null; passwd -l smmsplp&>/dev/null 2&>/dev/null; passwd -l mail&>/dev/null 2&>/dev/null; passwd -l operator&>/dev/null 2&>/dev/null; passwd -l games&>/dev/null 2&>/dev/null; passwd -l gopher&>/dev/null 2&>/dev/null; passwd -l ftp&>/dev/null 2&>/dev/null; passwd -l nobody&>/dev/null 2&>/dev/null; passwd -l nobody4&>/dev/null 2&>/dev/null; passwd -l noaccess&>/dev/null 2&>/dev/null; passwd -l listen&>/dev/null 2&>/dev/null; passwd -l webservd&>/dev/null 2&>/dev/null; passwd -l rpm&>/dev/null 2&>/dev/null; passwd -l dbus&>/dev/null 2&>/dev/null; passwd -l avahi&>/dev/null 2&>/dev/null; passwd -l mailnull&>/dev/null 2&>/dev/null; passwd -l nscd&>/dev/null 2&>/dev/null; passwd -l vcsa&>/dev/null 2&>/dev/null; passwd -l rpc&>/dev/null 2&>/dev/null; passwd -l rpcuser&>/dev/null 2&>/dev/null; passwd -l nfs&>/dev/null 2&>/dev/null; passwd -l sshd&>/dev/null 2&>/dev/null; passwd -l pcap&>/dev/null 2&>/dev/null; passwd -l ntp&>/dev/null 2&>/dev/null; passwd -l haldaemon&>/dev/null 2&>/dev/null; passwd -l distcache&>/dev/null 2&>/dev/null; passwd -l webalizer&>/dev/null 2&>/dev/null; passwd -l squid&>/dev/null 2&>/dev/null; passwd -l xfs&>/dev/null 2&>/dev/null; passwd -l gdm&>/dev/null 2&>/dev/null; passwd -l sabayon&>/dev/null 2&>/dev/null; passwd -l named&>/dev/null 2&>/dev/null
echo \*\*\*\* 锁定帐号完成  \*\*\*\* 




# 远程登录超时设置
function Account(){ 
  echo \*\*\*\* 设置登录超时时间为10分钟
  egrep -q "^\s*(export|)\s*TMOUT\S\w+.*$" /etc/profile && sed -ri "s/^\s*(export|)\s*TMOUT.\S\w+.*$/export TMOUT=600/" /etc/profile || echo "export TMOUT=600" >> /etc/profile
  egrep -q "^\s*.*ClientAliveInterval\s\w+.*$" /etc/ssh/sshd_config && sed -ri "s/^\s*.*ClientAliveInterval\s\w+.*$/ClientAliveInterval 600/" /etc/ssh/sshd_config || echo "ClientAliveInterval 600" >> /etc/ssh/sshd_config

  echo \*\*\*\*连续登录失败5次锁定帐号5分钟包括root账号\*\*\*\*
  sed -ri "/^\s*auth\s+required\s+pam_tally2.so\s+.+(\s*#.*)?\s*$/d" /etc/pam.d/sshd 
  sed -ri '2a auth required pam_tally2.so deny=5 unlock_time=300 even_deny_root root_unlock_time=300' /etc/pam.d/sshd 
  # 可选-宿主机控制台登陆
  # sed -ri "/^\s*auth\s+required\s+pam_tally2.so\s+.+(\s*#.*)?\s*$/d" /etc/pam.d/login
  # sed -ri '2a auth required pam_tally2.so deny=5 unlock_time=300 even_deny_root root_unlock_time=300' /etc/pam.d/login
}



# 删除潜在威胁文件
echo
echo \*\*\*\* 删除潜在威胁文件
find / -maxdepth 3 -name hosts.equiv | xargs rm -rf
find / -maxdepth 3 -name .netrc | xargs rm -rf
find / -maxdepth 3 -name .rhosts | xargs rm -rf



# /etc/sysctl.conf 进行内核参数的配置
# /etc/sysctl.d/99-kubernetes-cri.conf
egrep -q "^(#)?net.ipv4.ip_forward.*" /etc/sysctl.conf && sed -ri "s|^(#)?net.ipv4.ip_forward.*|net.ipv4.ip_forward = 1|g"  /etc/sysctl.conf || echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
# egrep -q "^(#)?net.bridge.bridge-nf-call-ip6tables.*" /etc/sysctl.conf && sed -ri "s|^(#)?net.bridge.bridge-nf-call-ip6tables.*|net.bridge.bridge-nf-call-ip6tables = 1|g" /etc/sysctl.conf || echo "net.bridge.bridge-nf-call-ip6tables = 1" >> /etc/sysctl.conf 
# egrep -q "^(#)?net.bridge.bridge-nf-call-iptables.*" /etc/sysctl.conf && sed -ri "s|^(#)?net.bridge.bridge-nf-call-iptables.*|net.bridge.bridge-nf-call-iptables = 1|g" /etc/sysctl.conf || echo "net.bridge.bridge-nf-call-iptables = 1" >> /etc/sysctl.conf
egrep -q "^(#)?net.ipv6.conf.all.disable_ipv6.*" /etc/sysctl.conf && sed -ri "s|^(#)?net.ipv6.conf.all.disable_ipv6.*|net.ipv6.conf.all.disable_ipv6 = 1|g" /etc/sysctl.conf || echo "net.ipv6.conf.all.disable_ipv6 = 1" >> /etc/sysctl.conf
egrep -q "^(#)?net.ipv6.conf.default.disable_ipv6.*" /etc/sysctl.conf && sed -ri "s|^(#)?net.ipv6.conf.default.disable_ipv6.*|net.ipv6.conf.default.disable_ipv6 = 1|g" /etc/sysctl.conf || echo "net.ipv6.conf.default.disable_ipv6 = 1" >> /etc/sysctl.conf
egrep -q "^(#)?net.ipv6.conf.lo.disable_ipv6.*" /etc/sysctl.conf && sed -ri "s|^(#)?net.ipv6.conf.lo.disable_ipv6.*|net.ipv6.conf.lo.disable_ipv6 = 1|g" /etc/sysctl.conf || echo "net.ipv6.conf.lo.disable_ipv6 = 1" >> /etc/sysctl.conf
egrep -q "^(#)?net.ipv6.conf.all.forwarding.*" /etc/sysctl.conf && sed -ri "s|^(#)?net.ipv6.conf.all.forwarding.*|net.ipv6.conf.all.forwarding = 1|g"  /etc/sysctl.conf || echo "net.ipv6.conf.all.forwarding = 1"  >> /etc/sysctl.conf




# Dcker 安装
# 帮助: https://docs.docker.com/engine/install/ubuntu/
# Ubuntu Focal 20.04 (LTS)
# Ubuntu Bionic 18.04 (LTS)
# Ubuntu Xenial 16.04 (LTS)
function InstallDocker(){
  # 1.卸载旧版本 
  sudo apt-get remove docker docker-engine docker.io containerd runc
  
  # 2.更新apt包索引并安装包以允许apt在HTTPS上使用存储库
  sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common

  # 3.添加Docker官方GPG密钥
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

  # 4.通过搜索指纹的最后8个字符进行密钥验证
  sudo apt-key fingerprint 0EBFCD88

  # 5.设置稳定存储库
  sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"

  # 6.Install Docker Engine 默认最新版本
  sudo apt-get update && sudo apt-get install -y docker-ce docker-ce-cli containerd.io

  # 7.安装特定版本的Docker引擎，请在repo中列出可用的版本
  # $apt-cache madison docker-ce
  # docker-ce | 5:18.09.1~3-0~ubuntu-xenial | https://download.docker.com/linux/ubuntu  xenial/stable amd64 Packages
  # 使用第二列中的版本字符串安装特定的版本，例如:5:18.09.1~3-0~ubuntu-xenial。
  # $sudo apt-get install docker-ce=<VERSION_STRING> docker-ce-cli=<VERSION_STRING> containerd.io

  #8.将当前用户加入docker用户组然后重新登陆当前用户使得低权限用户
  sudo gpasswd -a ${USER} docker

  #9.加速器建立
  mkdir -vp /etc/docker/
sudo tee /etc/docker/daemon.json <<-'EOF'
{
  #"registry-mirrors": ["https://xlx9erfu.mirror.aliyuncs.com"],
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "live-restore": true
}
EOF

  # 9.自启与启动
  sudo systemctl enable docker 
  sudo systemctl restart docker

  # 10.退出登陆生效
  exit
}
