#!/bin/bash
# @Author: WeiyiGeek
# @Description: Ubuntu TLS Security Initiate
# @Create Time:  2019年9月1日 16:43:33
# @Last Modified time: 2021-11-15 11:06:31
# @E-mail: master@weiyigeek.top
# @Blog: https://www.weiyigeek.top
# @wechat: WeiyiGeeker
# @Github: https://github.com/WeiyiGeek/SecOpsDev/tree/master/OS-操作系统/Linux/
# @Version: 3.3
#-------------------------------------------------#
# 脚本主要功能说明:
# (1) Ubuntu 系统初始化操作包括IP地址设置、基础软件包更新以及安装加固。
# (2) Ubuntu 系统容器以及JDK相关环境安装。
# (3) Ubuntu 系统中异常错误日志解决。
# (4) Ubuntu 系统常规服务安装配置，加入数据备份目录。
# (5) Ubuntu 脚本错误优化、添加禁用cloud-init
#-------------------------------------------------#

## 系统全局变量定义
HOSTNAME=Ubuntu-Security-Template
IP=192.168.1.2
GATEWAY=192.168.1.1
DNSIP=("223.5.5.5" "223.6.6.6")
SSHPORT=20211
DefaultUser="geek"  # 系统创建的用户名称非root用户
ROOTPASS=geek@SecOpsDev.2022       # 密码建议12位以上且包含数字、大小写字母以及特殊字符。
APPPASS=geek@SecOpsDev.2022

# [配置备份目录]
BACKUPDIR=/var/log/.backups
if [ ! -d ${BACKUPDIR} ];then  mkdir -vp ${BACKUPDIR}; fi

# [配置记录目录]
HISDIR=/var/log/.history
if [ ! -d ${HISDIR} ];then  mkdir -vp ${HISDIR}; fi

## 名称: err 、info 、warning
## 用途：全局Log信息打印函数
## 参数: $@
log::err() {
  printf "[$(date +'%Y-%m-%dT%H:%M:%S')]: \033[31mERROR: $@ \033[0m\n"
}
log::info() {
  printf "[$(date +'%Y-%m-%dT%H:%M:%S')]: \033[32mINFO: $@ \033[0m\n"
}
log::warning() {
  printf "[$(date +'%Y-%m-%dT%H:%M:%S')]: \033[33mWARNING: $@ \033[0m\n"
}


## 名称: os::Network
## 用途: 网络配置相关操作脚本包括(IP地址修改)
## 参数: 无
os::Network () {
  log::info "[-] 操作系统网络配置相关脚本,开始执行....."

# (1) IP地址与主机名称设置
sudo cp /etc/netplan/00-installer-config.yaml{,.bak}
mkdir /opt/init/
sudo tee /opt/init/network.sh <<'EOF'
#!/bin/bash
CURRENT_IP=$(hostname -I | cut -f 1 -d " ")
GATEWAY=$(hostname -I | cut -f 1,2,3 -d ".")
if [[ $# -lt 3 ]];then
  echo "Usage: $0 IP Gateway Hostname"
  exit
fi
echo "IP:${1} # GATEWAY:${2} # HOSTNAME:${3}"
sudo sed -i "s#${CURRENT_IP}#${1}#g" /etc/netplan/00-installer-config.yaml
sudo sed -i "s#${GATEWAY}.1#${2}#g" /etc/netplan/00-installer-config.yaml
sudo hostnamectl set-hostname ${3} 
sudo netplan apply
EOF
sudo chmod +x /opt/init/network.sh

# (2) 本地主机名解析设置
sed -i "s/127.0.1.1\s.\w.*$/127.0.1.1 ${HOSTNAME}/g" /etc/hosts
grep -q "^\$(hostname -I)\s.\w.*$" /etc/hosts && sed -i "s/\$(hostname -I)\s.\w.*$/${IPADDR} ${HOSTNAME}" /etc/hosts || echo "${IPADDR} ${HOSTNAME}" >> /etc/hosts

# (3) 系统DNS域名解析服务设置
cp -a /etc/resolv.conf{,.bak}
for dns in ${DNSIP[@]};do echo "nameserver ${dns}" >> /etc/resolv.conf;done

sudo /opt/init/network.sh ${IP} ${GATEWAY} ${HOSTNAME}
log::info "[*] network configure modifiy successful! restarting Network........."
}


## 名称: os::Software
## 用途: 操作系统软件包管理及更新源配置
## 参数: 无
os::Software () {
  log::info "[-] 操作系统软件包管理及更新源配置相关脚本,开始执行....."

# (1) 卸载多余软件，例如 snap 软件及其服务
sudo systemctl stop snapd snapd.socket #停止snapd相关的进程服务
sudo apt autoremove --purge -y snapd
sudo systemctl daemon-reload
sudo rm -rf ~/snap /snap /var/snap /var/lib/snapd /var/cache/snapd /run/snapd

# (2) 软件源设置与系统更新
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

# (3) 内核版本升级以及常规软件安装
sudo apt autoclean && sudo apt update && sudo apt upgrade -y
sudo apt install -y nano vim git unzip wget ntpdate dos2unix net-tools tree htop ncdu nload sysstat psmisc bash-completion fail2ban  gcc g++ make jq nfs-common rpcbind libpam-cracklib

# (4) 代理方式进行更新
# sudo apt autoclean && sudo apt -o Acquire::http::proxy="http://proxy.weiyigeek.top/" update && sudo apt -o Acquire::http::proxy="http://proxy.weiyigeek.top" upgrade -y
# sudo apt install -o Acquire::http::proxy="http://proxy.weiyigeek.top/" -y nano vim git unzip wget ntpdate dos2unix net-tools tree htop ncdu nload sysstat psmisc bash-completion fail2ban
}


## 名称: os::TimedataZone
## 用途: 操作系统时间与时区同步配置
## 参数: 无
os::TimedataZone () {
  log::info "[*] 操作系统系统时间时区配置相关脚本,开始执行....."

# (1) 时间同步服务端容器(可选也可以用外部ntp服务器) : docker run -d --rm --cap-add SYS_TIME -e ALLOW_CIDR=0.0.0.0/0 -p 123:123/udp geoffh1977/chrony
echo "同步前的时间: $(date -R)"

# 方式1.Chrony 客户端配置
apt install -y chrony
grep -q "192.168.12.254" /etc/chrony/chrony.conf || sudo tee -a /etc/chrony/chrony.conf <<'EOF'
pool 192.168.10.254 iburst maxsources 1
pool 192.168.12.254 iburst maxsources 1
pool 192.168.4.254 iburst maxsources 1
pool ntp.aliyun.com iburst maxsources 4
keyfile /etc/chrony/chrony.keys
driftfile /var/lib/chrony/chrony.drift
logdir /var/log/chrony
maxupdateskew 100.0
rtcsync
# 允许跳跃式校时 如果在前 3 次校时中时间差大于 1.0s
makestep 1 3
EOF
systemctl enable chrony && systemctl restart chrony && systemctl status chrony -l

# 方式2
# sudo ntpdate 192.168.10.254 || sudo ntpdate 192.168.12.215 || sudo ntpdate ntp1.aliyun.com

# 方式3
# echo 'NTP=192.168.10.254 192.168.4.254' >> /etc/systemd/timesyncd.conf
# echo 'FallbackNTP=ntp.aliyun.com' >> /etc/systemd/timesyncd.conf
# systemctl restart systemd-timesyncd.service

# (2) 时区与地区设置: 
sudo cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
sudo timedatectl set-timezone Asia/Shanghai
# sudo dpkg-reconfigure tzdata  # 修改确认
# sudo bash -c "echo 'Asia/Shanghai' > /etc/timezone" # 与上一条命令一样
# 将当前的 UTC 时间写入硬件时钟 (硬件时间默认为UTC)
sudo timedatectl set-local-rtc 0
# 启用NTP时间同步：
sudo timedatectl set-ntp yes
# 校准时间服务器-时间同步(推荐使用chronyc进行平滑同步)
sudo chronyc tracking
# 手动校准-强制更新时间
# chronyc -a makestep
# 系统时钟同步硬件时钟
# sudo hwclock --systohc
sudo hwclock -w

# (3) 重启依赖于系统时间的服务
sudo systemctl restart rsyslog.service cron.service
log::info "[*] Tie confmigure modifiy successful! restarting chronyd rsyslog.service crond.service........."
timedatectl
}


## 名称: os::Security
## 用途: 操作系统安全加固配置脚本(符合等保要求-三级要求)
## 参数: 无
os::Security () {
  log::info "正在进行->操作系统安全加固(符合等保要求-三级要求)配置"

# (0) 系统用户核查配置
  log::info "[-] 锁定或者删除多余的系统账户以及创建低权限用户"
userdel -r lxd
groupdel lxd
defaultuser=(root daemon bin sys games man lp mail news uucp proxy www-data backup list irc gnats nobody systemd-network systemd-resolve systemd-timesync messagebus syslog _apt tss uuidd tcpdump landscape pollinate usbmux sshd systemd-coredump _chrony)
for i in $(cat /etc/passwd | cut -d ":" -f 1,7);do
  flag=0; name=${i%%:*}; terminal=${i##*:}
  if [[ "${terminal}" == "/bin/bash" || "${terminal}" == "/bin/sh" ]];then
    log::warning "${i} 用户，shell终端为 /bin/bash 或者 /bin/sh"
  fi
  for j in ${defaultuser[@]};do
    if [[ "${name}" == "${j}" ]];then
      flag=1
      break;
    fi
  done
  if [[ $flag -eq 0 ]];then
    log::warning "${i} 非默认用户"
  fi
done
cp /etc/shadow /etc/shadow-`date +%Y%m%d`.bak
passwd -l adm&>/dev/null 2&>/dev/null; passwd -l daemon&>/dev/null 2&>/dev/null; passwd -l bin&>/dev/null 2&>/dev/null; passwd -l sys&>/dev/null 2&>/dev/null; passwd -l lp&>/dev/null 2&>/dev/null; passwd -l uucp&>/dev/null 2&>/dev/null; passwd -l nuucp&>/dev/null 2&>/dev/null; passwd -l smmsplp&>/dev/null 2&>/dev/null; passwd -l mail&>/dev/null 2&>/dev/null; passwd -l operator&>/dev/null 2&>/dev/null; passwd -l games&>/dev/null 2&>/dev/null; passwd -l gopher&>/dev/null 2&>/dev/null; passwd -l ftp&>/dev/null 2&>/dev/null; passwd -l nobody&>/dev/null 2&>/dev/null; passwd -l nobody4&>/dev/null 2&>/dev/null; passwd -l noaccess&>/dev/null 2&>/dev/null; passwd -l listen&>/dev/null 2&>/dev/null; passwd -l webservd&>/dev/null 2&>/dev/null; passwd -l rpm&>/dev/null 2&>/dev/null; passwd -l dbus&>/dev/null 2&>/dev/null; passwd -l avahi&>/dev/null 2&>/dev/null; passwd -l mailnull&>/dev/null 2&>/dev/null; passwd -l nscd&>/dev/null 2&>/dev/null; passwd -l vcsa&>/dev/null 2&>/dev/null; passwd -l rpc&>/dev/null 2&>/dev/null; passwd -l rpcuser&>/dev/null 2&>/dev/null; passwd -l nfs&>/dev/null 2&>/dev/null; passwd -l sshd&>/dev/null 2&>/dev/null; passwd -l pcap&>/dev/null 2&>/dev/null; passwd -l ntp&>/dev/null 2&>/dev/null; passwd -l haldaemon&>/dev/null 2&>/dev/null; passwd -l distcache&>/dev/null 2&>/dev/null; passwd -l webalizer&>/dev/null 2&>/dev/null; passwd -l squid&>/dev/null 2&>/dev/null; passwd -l xfs&>/dev/null 2&>/dev/null; passwd -l gdm&>/dev/null 2&>/dev/null; passwd -l sabayon&>/dev/null 2&>/dev/null; passwd -l named&>/dev/null 2&>/dev/null

# (2) 用户密码设置和口令策略设置
  log::info "[-]  配置满足策略的root管理员密码 "
echo  ${ROOTPASS} | passwd --stdin root

log::info "[-] 配置满足策略的app普通用户密码(根据需求配置)"
groupadd application
useradd -m -s /bin/bash -c "application primary user" -g application app 
echo ${APPPASS} | passwd --stdin app

  log::info "[-] 强制用户在下次登录时更改密码 "
chage -d 0 -m 0 -M 90 -W 15 root && passwd --expire root 
chage -d 0 -m 0 -M 90 -W 15 ${DefaultUser} && passwd --expire ${DefaultUser} 
chage -d 0 -m 0 -M 90 -W 15 app && passwd --expire app

  log::info "[-] 用户口令复杂性策略设置 (密码过期周期0~90、到期前15天提示、密码长度至少15、复杂度设置至少有一个大小写、数字、特殊字符、密码三次不能一样、尝试次数为三次)"
egrep -q "^\s*PASS_MIN_DAYS\s+\S*(\s*#.*)?\s*$" /etc/login.defs && sed -ri "s/^(\s*)PASS_MIN_DAYS\s+\S*(\s*#.*)?\s*$/\PASS_MIN_DAYS  0/" /etc/login.defs || echo "PASS_MIN_DAYS  0" >> /etc/login.defs
egrep -q "^\s*PASS_MAX_DAYS\s+\S*(\s*#.*)?\s*$" /etc/login.defs && sed -ri "s/^(\s*)PASS_MAX_DAYS\s+\S*(\s*#.*)?\s*$/\PASS_MAX_DAYS  90/" /etc/login.defs || echo "PASS_MAX_DAYS  90" >> /etc/login.defs
egrep -q "^\s*PASS_WARN_AGE\s+\S*(\s*#.*)?\s*$" /etc/login.defs && sed -ri "s/^(\s*)PASS_WARN_AGE\s+\S*(\s*#.*)?\s*$/\PASS_WARN_AGE  15/" /etc/login.defs || echo "PASS_WARN_AGE  15" >> /etc/login.defs
egrep -q "^\s*PASS_MIN_LEN\s+\S*(\s*#.*)?\s*$" /etc/login.defs && sed -ri "s/^(\s*)PASS_MIN_LEN\s+\S*(\s*#.*)?\s*$/\PASS_MIN_LEN  15/" /etc/login.defs || echo "PASS_MIN_LEN  15" >> /etc/login.defs

egrep -q "^password\s.+pam_cracklib.so\s+\w+.*$" /etc/pam.d/common-password && sed -ri '/^password\s.+pam_cracklib.so/{s/pam_cracklib.so\s+\w+.*$/pam_cracklib.so retry=3 minlen=15 ucredit=-1 lcredit=-1 dcredit=-1 ocredit=-1 difok=1/g;}' /etc/pam.d/common-password
egrep -q "^password\s.+pam_unix.so\s+\w+.*$" /etc/pam.d/common-password && sed -ri '/^password\s.+pam_unix.so/{s/pam_unix.so\s+\w+.*$/pam_unix.so obscure use_authtok try_first_pass sha512 remember=3/g;}' /etc/pam.d/common-password

  log::info "[-] 存储用户密码的文件，其内容经过sha512加密，所以非常注意其权限"
touch /etc/security/opasswd && chown root:root /etc/security/opasswd && chmod 600 /etc/security/opasswd 


# (3) 用户sudo权限以及重要目录和文件的权限设置
  log::info "[-] 用户sudo权限以及重要目录和文件的新建默认权限设置"
# 如uBuntu安装时您创建的用户 WeiyiGeek 防止直接通过 sudo passwd 修改root密码(此时必须要求输入WeiyiGeek密码后才可修改root密码)
# Tips: Sudo允许授权用户权限以另一个用户（通常是root用户）的身份运行程序, 
# DefaultUser="weiyigeek"
sed -i "/# Members of the admin/i ${DefaultUser} ALL=(ALL) PASSWD:ALL" /etc/sudoers


  log::info "[-] 配置用户 umask 为022 "
egrep -q "^\s*umask\s+\w+.*$" /etc/profile && sed -ri "s/^\s*umask\s+\w+.*$/umask 022/" /etc/profile || echo "umask 022" >> /etc/profile
egrep -q "^\s*umask\s+\w+.*$" /etc/bash.bashrc && sed -ri "s/^\s*umask\s+\w+.*$/umask 022/" /etc/bashrc || echo "umask 022" >> /etc/bash.bashrc
# log::info "[-] 设置用户目录创建默认权限, (初始为077比较严格)，在设置 umask 为022 及 777 - 022 "
# egrep -q "^\s*(umask|UMASK)\s+\w+.*$" /etc/login.defs && sed -ri "s/^\s*(umask|UMASK)\s+\w+.*$/UMASK 022/" /etc/login.defs || echo "UMASK 022" >> /etc/login.defs

  log::info "[-] 设置或恢复重要目录和文件的权限"
chmod 755 /etc; 
chmod 777 /tmp; 
chmod 700 /etc/inetd.conf&>/dev/null 2&>/dev/null; 
chmod 755 /etc/passwd; 
chmod 755 /etc/shadow; 
chmod 644 /etc/group; 
chmod 755 /etc/security; 
chmod 644 /etc/services; 
chmod 750 /etc/rc*.d
chmod 600 ~/.ssh/authorized_keys

  log::info "[-] 删除潜在威胁文件 "
find / -maxdepth 3 -name hosts.equiv | xargs rm -rf
find / -maxdepth 3 -name .netrc | xargs rm -rf
find / -maxdepth 3 -name .rhosts | xargs rm -rf


# (4) SSHD 服务安全加固设置
log::info "[-] sshd 服务安全加固设置"
# 严格模式
sudo egrep -q "^\s*StrictModes\s+.+$" /etc/ssh/sshd_config && sed -ri "s/^(#)?\s*StrictModes\s+.+$/StrictModes yes/" /etc/ssh/sshd_config || echo "StrictModes yes" >> /etc/ssh/sshd_config
# 监听端口更改
if [ -e ${SSHPORT} ];then export SSHPORT=20211;fi
sudo egrep -q "^\s*Port\s+.+$" /etc/ssh/sshd_config && sed -ri "s/^(#)?\s*Port\s+.+$/Port ${SSHPORT}/" /etc/ssh/sshd_config || echo "Port ${SSHPORT}" >> /etc/ssh/sshd_config
# 禁用X11转发以及端口转发
sudo egrep -q "^\s*X11Forwarding\s+.+$" /etc/ssh/sshd_config && sed -ri "s/^(#)?\s*X11Forwarding\s+.+$/X11Forwarding no/" /etc/ssh/sshd_config || echo "X11Forwarding no" >> /etc/ssh/sshd_config
sudo egrep -q "^\s*X11UseLocalhost\s+.+$" /etc/ssh/sshd_config && sed -ri "s/^(#)?\s*X11UseLocalhost\s+.+$/X11UseLocalhost yes/" /etc/ssh/sshd_config || echo "X11UseLocalhost yes" >> /etc/ssh/sshd_config
sudo egrep -q "^\s*AllowTcpForwarding\s+.+$" /etc/ssh/sshd_config && sed -ri "s/^(#)?\s*AllowTcpForwarding\s+.+$/AllowTcpForwarding no/" /etc/ssh/sshd_config || echo "AllowTcpForwarding no" >> /etc/ssh/sshd_config
sudo egrep -q "^\s*AllowAgentForwarding\s+.+$" /etc/ssh/sshd_config && sed -ri "s/^(#)?\s*AllowAgentForwarding\s+.+$/AllowAgentForwarding no/" /etc/ssh/sshd_config || echo "AllowAgentForwarding no" >> /etc/ssh/sshd_config
# 关闭禁用用户的 .rhosts 文件  ~/.ssh/.rhosts 来做为认证: 缺省IgnoreRhosts yes 
egrep -q "^(#)?\s*IgnoreRhosts\s+.+$" /etc/ssh/sshd_config && sed -ri "s/^(#)?\s*IgnoreRhosts\s+.+$/IgnoreRhosts yes/" /etc/ssh/sshd_config || echo "IgnoreRhosts yes" >> /etc/ssh/sshd_config
# 禁止root远程登录（推荐配置-根据需求配置）
egrep -q "^\s*PermitRootLogin\s+.+$" /etc/ssh/sshd_config && sed -ri "s/^\s*PermitRootLogin\s+.+$/PermitRootLogin no/" /etc/ssh/sshd_config || echo "PermitRootLogin no" >> /etc/ssh/sshd_config
# 登陆前后欢迎提示设置
egrep -q "^\s*(banner|Banner)\s+\W+.*$" /etc/ssh/sshd_config && sed -ri "s/^\s*(banner|Banner)\s+\W+.*$/Banner \/etc\/issue/" /etc/ssh/sshd_config || \
echo "Banner /etc/issue" >> /etc/ssh/sshd_config
log::info "[-] 远程SSH登录前后提示警告Banner设置"
# SSH登录前警告Banner
sudo tee /etc/issue <<'EOF'
****************** [ 安全登陆 (Security Login) ] *****************
Authorized only. All activity will be monitored and reported.By Security Center.

EOF
# SSH登录后提示Banner
sed -i '/^fi/a\\n\necho "\\e[1;37;41;5m################## 安全运维 (Security Operation) ####################\\e[0m"\necho "\\e[32mLogin success. Please execute the commands and operation data carefully.By WeiyiGeek.\\e[0m"' /etc/update-motd.d/00-header


# (5) 用户远程登录失败次数与终端超时设置 
  log::info "[-] 用户远程连续登录失败10次锁定帐号5分钟包括root账号"
sed -ri "/^\s*auth\s+required\s+pam_tally2.so\s+.+(\s*#.*)?\s*$/d" /etc/pam.d/sshd 
sed -ri '2a auth required pam_tally2.so deny=10 unlock_time=300 even_deny_root root_unlock_time=300' /etc/pam.d/sshd 
# 宿主机控制台登陆(可选)
# sed -ri "/^\s*auth\s+required\s+pam_tally2.so\s+.+(\s*#.*)?\s*$/d" /etc/pam.d/login
# sed -ri '2a auth required pam_tally2.so deny=5 unlock_time=300 even_deny_root root_unlock_time=300' /etc/pam.d/login

  log::info "[-] 设置登录超时时间为10分钟 "
egrep -q "^\s*(export|)\s*TMOUT\S\w+.*$" /etc/profile && sed -ri "s/^\s*(export|)\s*TMOUT.\S\w+.*$/export TMOUT=600\nreadonly TMOUT/" /etc/profile || echo -e "export TMOUT=600\nreadonly TMOUT" >> /etc/profile
egrep -q "^\s*.*ClientAliveInterval\s\w+.*$" /etc/ssh/sshd_config && sed -ri "s/^\s*.*ClientAliveInterval\s\w+.*$/ClientAliveInterval 600/" /etc/ssh/sshd_config || echo "ClientAliveInterval 600" >> /etc/ssh/sshd_config


# (5) 切换用户日志记录或者切换命令更改(可选)
  log::info "[-] 切换用户日志记录和切换命令更改名称为SU "
egrep -q "^(\s*)SULOG_FILE\s+\S*(\s*#.*)?\s*$" /etc/login.defs && sed -ri "s/^(\s*)SULOG_FILE\s+\S*(\s*#.*)?\s*$/\SULOG_FILE  \/var\/log\/.history\/sulog/" /etc/login.defs || echo "SULOG_FILE  /var/log/.history/sulog" >> /etc/login.defs
egrep -q "^\s*SU_NAME\s+\S*(\s*#.*)?\s*$" /etc/login.defs && sed -ri "s/^(\s*)SU_NAME\s+\S*(\s*#.*)?\s*$/\SU_NAME  SU/" /etc/login.defs || echo "SU_NAME  SU" >> /etc/login.defs
mkdir -vp /usr/local/bin /var/log/.backups /var/log/.history /var/log/.history/sulog
cp /usr/bin/su /var/log/.backups/su.bak
mv /usr/bin/su /usr/bin/SU
# 只能写入不能删除其目标目录中的文件
# chmod -R 1777 /var/log/.history
chattr -R +a /var/log/.history 
chattr +a /var/log/.backups

# (6) 用户终端执行的历史命令记录
log::info "[-] 用户终端执行的历史命令记录 "
egrep -q "^HISTSIZE\W\w+.*$" /etc/profile && sed -ri "s/^HISTSIZE\W\w+.*$/HISTSIZE=101/" /etc/profile || echo "HISTSIZE=101" >> /etc/profile
# 方式1
sudo tee /etc/profile.d/history-record.sh <<'EOF'
# 历史命令执行记录文件路径
LOGTIME=$(date +%Y%m%d-%H-%M-%S)
export HISTFILE="/var/log/.history/${USER}.${LOGTIME}.history"
if [ ! -f ${HISTFILE} ];then
  touch ${HISTFILE}
fi
chmod 600 /var/log/.history/${USER}.${LOGTIME}.history
# 历史命令执行文件大小记录设置
HISTFILESIZE=128
HISTTIMEFORMAT="%F_%T $(whoami)#$(who -u am i 2>/dev/null| awk '{print $NF}'|sed -e 's/[()]//g'):"
EOF
# 方式2.未能成功(如后续有小伙伴成功了欢迎留言分享)
# sudo tee /usr/local/bin/history.sh <<'EOF'
# #!/bin/bash
# logfiletime=$(date +%Y%m%d-%H-%M-%S)
# # unalias "history"
# if [ $# -eq 0 ];then history;fi
# for i in $*;do
#   if [ "$i" = "-c" ];then 
#     mv ~/.bash_history > /var/log/.history/${logfiletime}.history
#     history -c
#     continue;
#   fi
# done
# alias history="source /usr/local/bin/history.sh"
# EOF


# (7) GRUB 安全设置 （需要手动设置请按照需求设置）
  log::info "[-] 系统 GRUB 安全设置(防止物理接触从grub菜单中修改密码) "
# Grub 关键文件备份
cp -a /etc/grub.d/00_header /var/log/.backups 
cp -a /etc/grub.d/10_linux /var/log/.backups 
# 设置Grub菜单界面显示时间
sed -i -e 's|GRUB_TIMEOUT_STYLE=hidden|#GRUB_TIMEOUT_STYLE=hidden|g' -e 's|GRUB_TIMEOUT=0|GRUB_TIMEOUT=3|g' /etc/default/grub
sed -i -e 's|set timeout_style=${style}|#set timeout_style=${style}|g' -e 's|set timeout=${timeout}|set timeout=3|g' /etc/grub.d/00_header
# 创建认证密码 (此处密码: WeiyiGeek)
sudo grub-mkpasswd-pbkdf2
# Enter password:
# Reenter password:
# PBKDF2 hash of your password is grub.pbkdf2.sha512.10000.21AC9CEF61B96972BF6F918D2037EFBEB8280001045ED32DFDDCC260591CC6BC8957CF25A6755904A7053E97940A9E4CD5C1EF833C1651C1BCF09D899BED4C7C.9691521F5BB34CD8AEFCED85F4B830A86EC93B61A31885BCBE3FEE927D54EFDEE69FA8B51DBC00FCBDB618D4082BC22B2B6BA4161C7E6B990C4E5CFC9E9748D7
# 设置认证用户以及password_pbkdf2认证
tee -a /etc/grub.d/00_header <<'END'
cat <<'EOF'
# GRUB Authentication
set superusers="grub"
password_pbkdf2 grub grub.pbkdf2.sha512.10000.21AC9CEF61B96972BF6F918D2037EFBEB8280001045ED32DFDDCC260591CC6BC8957CF25A6755904A7053E97940A9E4CD5C1EF833C1651C1BCF09D899BED4C7C.9691521F5BB34CD8AEFCED85F4B830A86EC93B61A31885BCBE3FEE927D54EFDEE69FA8B51DBC00FCBDB618D4082BC22B2B6BA4161C7E6B990C4E5CFC9E9748D7
EOF
END
# 设置进入正式系统不需要认证如进入单用户模式进行重置账号密码时需要进行认证。 （高敏感数据库系统不建议下述操作）
# 在191和193 分别加入--user=grub 和 --unrestricted
# 191       echo "menuentry --user=grub '$(echo "$title" | grub_quote)' ${CLASS} \$menuentry_id_option 'gnulinux-$version-$type-$boot_device_id' {" | sed "s/^/$submenu_indentation/"  # 如果按e进行menu菜单则需要用grub进行认证
# 192   else
# 193       echo "menuentry --unrestricted '$(echo "$os" | grub_quote)' ${CLASS} \$menuentry_id_option 'gnulinux-simple-$boot_device_id' {" | sed "s/^/$submenu_indentation/"          # 正常进入系统则不认证

sed -i '/echo "$title" | grub_quote/ { s/menuentry /menuentry --user=grub /;}' /etc/grub.d/10_linux
sed -i '/echo "$os" | grub_quote/ { s/menuentry /menuentry --unrestricted /;}' /etc/grub.d/10_linux

# Ubuntu 方式更新GRUB从而生成boot启动文件。
update-grub


# (8) 操作系统防火墙启用以及策略设置
  log::info "[-] 系统防火墙启用以及规则设置 "
systemctl enable ufw.service && systemctl start ufw.service && ufw enable
sudo ufw allow proto tcp to any port 20211
# 重启修改配置相关服务
systemctl restart sshd
}



## 名称: os::Operation 
## 用途: 操作系统安全运维设置
## 参数: 无
os::Operation () {
  log::info "[-] 操作系统安全运维设置相关脚本"

# (0) 禁用ctrl+alt+del组合键对系统重启 (必须要配置,我曾入过坑)
  log::info "[-] 禁用控制台ctrl+alt+del组合键重启"
mv /usr/lib/systemd/system/ctrl-alt-del.target /var/log/.backups/ctrl-alt-del.target-$(date +%Y%m%d).bak

# (1) 设置文件删除回收站别名
  log::info "[-] 设置文件删除回收站别名(防止误删文件) "
sudo tee /etc/profile.d/alias.sh <<'EOF'
# User specific aliases and functions
# 删除回收站
# find ~/.trash -delete
# 删除空目录
# find ~/.trash -type d -delete
alias rm="sh /usr/local/bin/remove.sh"
EOF
sudo tee /usr/local/bin/remove.sh <<'EOF'
#!/bin/sh
# 定义回收站文件夹目录.trash
trash="/.trash"
deltime=$(date +%Y%m%d-%H-%M-%S)
TRASH_DIR="${HOME}${trash}/${deltime}"
# 建立回收站目录当不存在的时候
if [ ! -e ${TRASH_DIR} ];then
   mkdir -p ${TRASH_DIR}
fi
for i in $*;do
  if [ "$i" = "-rf" ];then continue;fi
  # 防止误操作
  if [ "$i" = "/" ];then echo '# Danger delete command, Not delete / directory!';exit -1;fi
  #定义秒时间戳
  STAMP=$(date +%s)
  #得到文件名称(非文件夹)，参考man basename
  fileName=$(basename $i)
  #将输入的参数，对应文件mv至.trash目录，文件后缀，为当前的时间戳
  mv $i ${TRASH_DIR}/${fileName}.${STAMP}
done
EOF
sudo chmod +775 /usr/local/bin/remove.sh /etc/profile.d/alias.sh
sudo chmod a+x /usr/local/bin/remove.sh /etc/profile.d/alias.sh
source /etc/profile.d/alias.sh

# (2) 解决普通定时任务无法后台定时执行
log::info "[-] 解决普通定时任务无法后台定时执行 "
linenumber=`expr $(egrep -n "pam_unix.so\s$" /etc/pam.d/common-session-noninteractive | cut -f 1 -d ":") - 2`
sudo sed -ri "${linenumber}a session [success=1 default=ignore] pam_succeed_if.so service in cron quiet use_uid" /etc/pam.d/common-session-noninteractive


# (3) 解决 ubuntu20.04 multipath add missing path 错误
# 添加以下内容,sda视本地环境做调整
tee -a /etc/multipath.conf <<'EOF'
blacklist {
  devnode "^sda"
}
EOF
# 重启multipath-tools服务
sudo service multipath-tools restart

# (4) 禁用 Ubuntu 中的 cloud-init
# 在 /etc/cloud 目录下创建 cloud-init.disabled 文件,注意重启后生效
sudo touch /etc/cloud/cloud-init.disabled
}



## 名称: os::optimizationn
## 用途: 操作系统优化设置(内核参数)
## 参数: 无
os::optimizationn () {
log::info "[-] 正在进行操作系统内核参数优化设置......."

# (1) 系统内核参数的配置(/etc/sysctl.conf)
log::info "[-] 系统内核参数的配置/etc/sysctl.conf"

# /etc/sysctl.d/99-kubernetes-cri.conf
egrep -q "^(#)?net.ipv4.ip_forward.*" /etc/sysctl.conf && sed -ri "s|^(#)?net.ipv4.ip_forward.*|net.ipv4.ip_forward = 1|g"  /etc/sysctl.conf || echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
# egrep -q "^(#)?net.bridge.bridge-nf-call-ip6tables.*" /etc/sysctl.conf && sed -ri "s|^(#)?net.bridge.bridge-nf-call-ip6tables.*|net.bridge.bridge-nf-call-ip6tables = 1|g" /etc/sysctl.conf || echo "net.bridge.bridge-nf-call-ip6tables = 1" >> /etc/sysctl.conf 
# egrep -q "^(#)?net.bridge.bridge-nf-call-iptables.*" /etc/sysctl.conf && sed -ri "s|^(#)?net.bridge.bridge-nf-call-iptables.*|net.bridge.bridge-nf-call-iptables = 1|g" /etc/sysctl.conf || echo "net.bridge.bridge-nf-call-iptables = 1" >> /etc/sysctl.conf
egrep -q "^(#)?net.ipv6.conf.all.disable_ipv6.*" /etc/sysctl.conf && sed -ri "s|^(#)?net.ipv6.conf.all.disable_ipv6.*|net.ipv6.conf.all.disable_ipv6 = 1|g" /etc/sysctl.conf || echo "net.ipv6.conf.all.disable_ipv6 = 1" >> /etc/sysctl.conf
egrep -q "^(#)?net.ipv6.conf.default.disable_ipv6.*" /etc/sysctl.conf && sed -ri "s|^(#)?net.ipv6.conf.default.disable_ipv6.*|net.ipv6.conf.default.disable_ipv6 = 1|g" /etc/sysctl.conf || echo "net.ipv6.conf.default.disable_ipv6 = 1" >> /etc/sysctl.conf
egrep -q "^(#)?net.ipv6.conf.lo.disable_ipv6.*" /etc/sysctl.conf && sed -ri "s|^(#)?net.ipv6.conf.lo.disable_ipv6.*|net.ipv6.conf.lo.disable_ipv6 = 1|g" /etc/sysctl.conf || echo "net.ipv6.conf.lo.disable_ipv6 = 1" >> /etc/sysctl.conf
egrep -q "^(#)?net.ipv6.conf.all.forwarding.*" /etc/sysctl.conf && sed -ri "s|^(#)?net.ipv6.conf.all.forwarding.*|net.ipv6.conf.all.forwarding = 1|g" /etc/sysctl.conf || echo "net.ipv6.conf.all.forwarding = 1"  >> /etc/sysctl.conf
egrep -q "^(#)?vm.max_map_count.*" /etc/sysctl.conf && sed -ri "s|^(#)?vm.max_map_count.*|vm.max_map_count = 262144|g" /etc/sysctl.conf || echo "vm.max_map_count = 262144"  >> /etc/sysctl.conf

tee -a /etc/sysctl.conf <<'EOF'
# 调整提升服务器负载能力之外,还能够防御小流量的Dos、CC和SYN攻击
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_tw_reuse = 1
# net.ipv4.tcp_tw_recycle = 1
net.ipv4.tcp_fin_timeout = 60
net.ipv4.tcp_synack_retries = 1
net.ipv4.tcp_syn_retries = 1
net.ipv4.tcp_fastopen = 3

# 优化TCP的可使用端口范围及提升服务器并发能力(注意一般流量小的服务器上没必要设置如下参数)
net.ipv4.tcp_keepalive_time = 1200
net.ipv4.tcp_max_syn_backlog = 8192
net.ipv4.tcp_max_tw_buckets = 5000
net.ipv4.ip_local_port_range = 1024 65535

# 优化核套接字TCP的缓存区
net.core.netdev_max_backlog = 8192
net.core.somaxconn = 8192
net.core.rmem_max = 12582912
net.core.rmem_default = 6291456
net.core.wmem_max = 12582912
net.core.wmem_default = 6291456
EOF


# (2) Linux 系统的最大进程数和最大文件打开数限制
log::info "[-] Linux 系统的最大进程数和最大文件打开数限制"
egrep -q "^\s*ulimit -HSn\s+\w+.*$" /etc/profile && sed -ri "s/^\s*ulimit -HSn\s+\w+.*$/ulimit -HSn 65535/" /etc/profile || echo "ulimit -HSn 65535" >> /etc/profile
egrep -q "^\s*ulimit -HSu\s+\w+.*$" /etc/profile && sed -ri "s/^\s*ulimit -HSu\s+\w+.*$/ulimit -HSu 65535/" /etc/profile || echo "ulimit -HSu 65535" >> /etc/profile

tee -a /etc/security/limits.conf <<'EOF'
# ulimit -HSn 65535
# ulimit -HSu 65535
*  soft  nofile  65535
*  hard  nofile  65535
*  soft  nproc   65535
*  hard  nproc   65535

# End of file
EOF
# sed -i "/# End/i *  soft  nproc   65535" /etc/security/limits.conf
# sed -i "/# End/i *  hard  nproc   65535" /etc/security/limits.conf
sysctl -p

# 需重启生效
reboot
}

## 名称: system::swap
## 用途: Liunx 系统创建SWAP交换分区(默认2G)
## 参数: $1(几G)
system::swap () {
  if [ -e $1 ];then
    sudo dd if=/dev/zero of=/swapfile bs=1024 count=2097152   # 2G Swap 分区 1024 * 1024 , centos 以 1000 为标准
  else
    number=$(echo "${1}*1024*1024"|bc)
    sudo dd if=/dev/zero of=/swapfile bs=1024 count=${number}   # 2G Swap 分区 1024 * 1024 , centos 以 1000 为标准
  fi

  sudo mkswap /swapfile && sudo swapon /swapfile
  if [ $(grep -c "/swapfile" /etc/fstab) -eq 0 ];then
sudo tee -a /etc/fstab <<'EOF'
/swapfile swap swap default 0 0
EOF
fi
sudo swapon --show && sudo free -h
}




## 名称: software::Java
## 用途: java 环境安装配置
## 参数: 无
software::Java () {
  # 基础变量
  JAVA_FILE="/root/Downloads/jdk-8u211-linux-x64.tar.gz"
  JAVA_SRC="/usr/local/"
  JAVA_DIR="/usr/local/jdk"
  # 环境配置
  sudo tar -zxvf ${JAVA_FILE} -C ${JAVA_SRC}
  sudo rm -rf /usr/local/jdk 
  JAVA_SRC=$(ls /usr/local/ | grep "jdk")
  sudo ln -s ${JAVA_SRC} ${JAVA_DIR}
  export PATH=${JAVA_DIR}/bin:${PATH}
  sudo cp /etc/profile /etc/profile.$(date +%Y%m%d-%H%M%S).bak
  sudo tee -a /etc/profile <<'EOF'
export JAVA_HOME=/usr/local/jdk
export JRE_HOME=/usr/local/jdk/jre
export CLASSPATH=.:$JAVA_HOME/lib/dt.jar:$JAVA_HOME/lib/tools.jar
export PATH=$JAVA_HOME/bin:$PATH
EOF
  java -version
}


## 名称: software::docker
## 用途: 软件安装之Docker安装
## 参数: 无
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

  # 3.添加Docker官方GPG密钥 # -fsSL
  sudo curl  https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

  # 4.通过搜索指纹的最后8个字符进行密钥验证
  sudo apt-key fingerprint 0EBFCD88

  # 5.设置稳定存储库
  sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"

  # 6.Install Docker Engine 默认最新版本
  sudo apt-get update && sudo apt-get install -y docker-ce=5:20.10.7~3-0~ubuntu-focal docker-ce-cli=5:20.10.7~3-0~ubuntu-focal containerd.io docker-compose
  # - 强制IPv4
  # sudo apt-get -o Acquire::ForceIPv4=true  install -y docker-ce=5:19.03.15~3-0~ubuntu-focal docker-ce-cli=5:19.03.15~3-0~ubuntu-focal containerd.io docker-compose

  # 7.安装特定版本的Docker引擎，请在repo中列出可用的版本
  apt-cache madison docker-ce
  # docker-ce | 5:20.10.6~3-0~ubuntu-focal| https://download.docker.com/linux/ubuntu focal/stable amd64 Packages
  # docker-ce | 5:19.03.15~3-0~ubuntu-focal | https://download.docker.com/linux/ubuntu  xenial/stable amd64 Packages
  # 使用第二列中的版本字符串安装特定的版本，例如:5:18.09.1~3-0~ubuntu-xenial。
  # $sudo apt-get install docker-ce=<VERSION_STRING> docker-ce-cli=<VERSION_STRING> containerd.io

  #8.将当前用户加入docker用户组然后重新登陆当前用户使得低权限用户
  sudo gpasswd -a ${USER} docker
  # sudo gpasswd -a weiyigeek docker

  #9.加速器建立
  mkdir -vp /etc/docker/
sudo tee /etc/docker/daemon.json <<-'EOF'
{
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
  "dns": ["192.168.10.254","223.6.6.6"]
}
EOF
  # "data-root":"/monitor/container",
  # "insecure-registries": ["harbor.weiyigeek.top"]
  # 9.自启与启动
  sudo systemctl daemon-reload
  sudo systemctl enable docker 
  sudo systemctl restart docker

  # 10.退出登陆生效
  exit
}


## 名称: disk::Lvsmanager
## 用途: uBuntu操作系统磁盘 LVS 逻辑卷添加与配置(扩容流程)
## 参数: 无
disk::Lvsmanager () {
  echo "\n分区信息:"
  sudo df -Th
  sudo lsblk
  echo -e "\n 磁盘信息："
  sudo fdisk -l
  echo -e "\n PV物理卷查看："
  sudo pvscan
  echo -e "\n vgs虚拟卷查看："
  sudo vgs
  echo -e "\n lvscan逻辑卷扫描:"
  sudo lvscan
  echo -e "\n 分区扩展"
  echo "Ubuntu \n lvextend -L +74G /dev/ubuntu-vg/ubuntu-lv"
  echo "lsblk"
  echo -e "ubuntu general \n # resize2fs -p -F /dev/mapper/ubuntu--vg-ubuntu--lv"
}

# 安全加固过程临时文件清理为基线镜像做准备
unalias rm
find ~/.trash/* -delete
find /home/ -type d -name .trash -exec find {} -delete \;
find /var/log -name "*.gz" -delete
find /var/log -name "*log.*" -delete
find /var/log -name "vmware-*.*.log" -delete
find /var/log -name "*.log-*" -delete
find /var/log -name "*.log" -exec truncate -s 0 {} \;
find /tmp/* -delete