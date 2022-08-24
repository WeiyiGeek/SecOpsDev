#!/bin/bash
#
# #------------------------------------------------------------------#
# |   服务器加固工具      WeiyiGeek | System To Reinforce            |
# #------------------------------------------------------------------#
# #------------------------------------------------------------------#
# 20200101 自定义高强度密码设置满足等保相关要求以及修改Selinux应用端口
# #------------------------------------------------------------------#
# 使用方法 (任选其一):
# (1) wget -O- https://WeiyiGeek.top/WeiyiGeekSTR.sh | bash
# (2) curl -fsL https://WeiyiGeek.top/WeiyiGeekSTR.sh  | bash
# #------------------------------------------------------------------#

#set -xeu

# === 全局定义 ===
# 全局参数定义
BuildTime="202006022"
export ROOTPASS="WeiyiGeek"
export SSHPORT=20211

# 字体颜色定义
Font_Black="\033[30m"
Font_Red="\033[31m"
Font_Green="\033[32m"
Font_Yellow="\033[33m"
Font_Blue="\033[34m"
Font_Purple="\033[35m"
Font_SkyBlue="\033[36m"
Font_White="\033[37m"
Font_Suffix="\033[0m"

# === 全局模块 ===
# 消息提示定义
function Msg(){
  case $1 in
    "Info")
      Msg_Info="${Font_Blue}[Info] ${2} ${Font_Suffix}"
      echo -e ${Msg_Info}
    ;;
    "Warning") 
      Msg_Warning="${Font_Yellow}[Warning] ${2} ${Font_Suffix}"
      echo -e ${Msg_Warning}
    ;;
    "Debug")
      Msg_Debug="${Font_Yellow}[Debug] ${2} ${Font_Suffix}"
      echo -e ${Msg_Debug}
    ;;
    "Error")
      Msg_Error="${Font_Red}[Error] ${2} ${Font_Suffix}"
      echo -e ${Msg_Error}
    ;;
    "Success")
      Msg_Success="${Font_Green}[Success] ${2} ${Font_Suffix}"
      echo -e ${Msg_Success}
    ;;
    "Fail")
      Msg_Fail="${Font_Red}[Failed] ${2} ${Font_Suffix}"
      echo -e ${Msg_Fail}
    ;;
    *)
      Msg_Normal="--- $2 ---"
      echo -e ${Msg_Normal}
    ;;
  esac
}

# Trap终止信号捕获
trap "Global_TrapSigExit_Sig1" 1
trap "Global_TrapSigExit_Sig2" 2
trap "Global_TrapSigExit_Sig3" 3
trap "Global_TrapSigExit_Sig15" 15

# Trap终止信号1 - 处理
Global_TrapSigExit_Sig1() {
  Msg Error "\nCaught Signal SIGHUP, Exiting ...\n"
  exit 1
}

# Trap终止信号2 - 处理 (Ctrl+C)
Global_TrapSigExit_Sig2() {
  Msg Error "\nCaught Signal SIGINT (or Ctrl+C), Exiting ...\n"
  exit 1
}

# Trap终止信号3 - 处理
Global_TrapSigExit_Sig3() {
  Msg Error "\nCaught Signal SIGQUIT, Exiting ...\n"
  exit 1
}

# Trap终止信号15 - 处理 (进程被杀)
Global_TrapSigExit_Sig15() {
  Msg Error "\nCaught Signal SIGTERM, Exiting ...\n"
  exit 1
}


# === 加固模块 ===
Msg "Info" "\*\*\*\* 开始自动配置安全基线 \*\*\*\*" 

function AccountAuthority(){
  # 用户的umask安全配置
  Msg "1" "[用户的umask安全配置]"
  echo \*\*\*\* 修改umask为022  \*\*\*\* 
  egrep -q "^\s*umask\s+\w+.*$" /etc/profile && sed -ri "s/^\s*umask\s+\w+.*$/umask 022/" /etc/profile || echo "umask 022" >> /etc/profile
  egrep -q "^\s*umask\s+\w+.*$" /etc/csh.login && sed -ri "s/^\s*umask\s+\w+.*$/umask 022/" /etc/csh.login || echo "umask 022" >>/etc/csh.login
  egrep -q "^\s*umask\s+\w+.*$" /etc/csh.cshrc && sed -ri "s/^\s*umask\s+\w+.*$/umask 022/" /etc/csh.cshrc || echo "umask 022" >> /etc/csh.cshrc
  egrep -q "^\s*umask\s+\w+.*$" /etc/bashrc && sed -ri "s/^\s*umask\s+\w+.*$/umask 022/" /etc/bashrc || echo "umask 022" >> /etc/bashrc

  # 用户目录缺省访问权限设置
  Msg "1" "[用户目录缺省访问权限设置]"
  echo \*\*\*\* 设置用户目录默认权限为022
  egrep -q "^\s*(umask|UMASK)\s+\w+.*$" /etc/login.defs && sed -ri "s/^\s*(umask|UMASK)\s+\w+.*$/UMASK 022/" /etc/login.defs || echo "UMASK 022" >> /etc/login.defs

  # 重要目录和文件的权限设置
  Msg "1" "[重要目录和文件的权限设置]"
  echo \*\*\*\* 设置重要目录和文件的权限
  chmod 755 /etc; chmod 750 /etc/rc.d/init.d; chmod 777 /tmp; chmod 700 /etc/inetd.conf&>/dev/null 2&>/dev/null; chmod 755 /etc/passwd; chmod 755 /etc/shadow; chmod 644 /etc/group; chmod 755 /etc/security; chmod 644 /etc/services; chmod 750 /etc/rc*.d
}


function AccountSecurity(){
  # 锁定与设备运行、维护等工作无关的账号
  Msg "1" "[锁定与设备运行、维护等工作无关的账号]"
  echo \*\*\*\* 锁定与设备运行、维护等工作无关的账号 \*\*\*\* 
  passwd -l adm&>/dev/null 2&>/dev/null; passwd -l daemon&>/dev/null 2&>/dev/null; passwd -l bin&>/dev/null 2&>/dev/null; passwd -l sys&>/dev/null 2&>/dev/null; passwd -l lp&>/dev/null 2&>/dev/null; passwd -l uucp&>/dev/null 2&>/dev/null; passwd -l nuucp&>/dev/null 2&>/dev/null; passwd -l smmsplp&>/dev/null 2&>/dev/null; passwd -l mail&>/dev/null 2&>/dev/null; passwd -l operator&>/dev/null 2&>/dev/null; passwd -l games&>/dev/null 2&>/dev/null; passwd -l gopher&>/dev/null 2&>/dev/null; passwd -l ftp&>/dev/null 2&>/dev/null; passwd -l nobody&>/dev/null 2&>/dev/null; passwd -l nobody4&>/dev/null 2&>/dev/null; passwd -l noaccess&>/dev/null 2&>/dev/null; passwd -l listen&>/dev/null 2&>/dev/null; passwd -l webservd&>/dev/null 2&>/dev/null; passwd -l rpm&>/dev/null 2&>/dev/null; passwd -l dbus&>/dev/null 2&>/dev/null; passwd -l avahi&>/dev/null 2&>/dev/null; passwd -l mailnull&>/dev/null 2&>/dev/null; passwd -l nscd&>/dev/null 2&>/dev/null; passwd -l vcsa&>/dev/null 2&>/dev/null; passwd -l rpc&>/dev/null 2&>/dev/null; passwd -l rpcuser&>/dev/null 2&>/dev/null; passwd -l nfs&>/dev/null 2&>/dev/null; passwd -l sshd&>/dev/null 2&>/dev/null; passwd -l pcap&>/dev/null 2&>/dev/null; passwd -l ntp&>/dev/null 2&>/dev/null; passwd -l haldaemon&>/dev/null 2&>/dev/null; passwd -l distcache&>/dev/null 2&>/dev/null; passwd -l webalizer&>/dev/null 2&>/dev/null; passwd -l squid&>/dev/null 2&>/dev/null; passwd -l xfs&>/dev/null 2&>/dev/null; passwd -l gdm&>/dev/null 2&>/dev/null; passwd -l sabayon&>/dev/null 2&>/dev/null; passwd -l named&>/dev/null 2&>/dev/null
  echo \*\*\*\* 锁定帐号完成  \*\*\*\* 

  # 配置满足策略的root密码"
  echo
  echo \*\*\*\*  配置满足策略的root密码 \*\*\*\* 
  echo  ${ROOTPASS} | passwd --stdin root


  # 配置"root|或者指定用户下次登录时需更改密码"
  echo
  #echo \*\*\*\* 配置root下次登录时修改root密码 \*\*\*\* 
  #chage -d0 root
}


function AccountPolicy(){
  # 设置口令长度最小值和密码复杂度策略
  Msg "1" "[设置口令长度最小值和密码复杂度策略]"
  echo  \*\*\*\* 大写字母、小写字母、数字、特殊字符 4选3，登陆尝试三次，可自行修改 \*\*\*\*
  # 修改system-auth
  egrep -q "^\s*password\s*(requisite|required)\s*pam_cracklib.so.*$" /etc/pam.d/system-auth  && sed -ri "s/^\s*password\s*(requisite|required)\s*pam_cracklib.so.*$/\password    requisite     pam_cracklib.so try_first_pass retry=3 minlen=12 dcredit=-1 ocredit=-1 lcredit=-1/" /etc/pam.d/system-auth || echo "password    requisite     pam_cracklib.so try_first_pass retry=3 minlen=12 dcredit=-1 ocredit=-1 lcredit=-1" >> /etc/pam.d/system-auth
  # 修改password-auth
  egrep -q "^\s*password\s*(requisite|required)\s*pam_cracklib.so.*$" /etc/pam.d/password-auth && sed -ri "s/^\s*password\s*(requisite|required)\s*pam_cracklib.so.*$/\password    requisite     pam_cracklib.so try_first_pass retry=3 minlen=12 dcredit=-1 ocredit=-1 lcredit=-1/" /etc/pam.d/password-auth || echo "password    requisite     pam_cracklib.so try_first_pass retry=3 minlen=12 dcredit=-1 ocredit=-1 lcredit=-1" >> /etc/pam.d/password-auth
  # 修改login.defs
  egrep -q "^\s*PASS_MIN_LEN\s+\S*(\s*#.*)?\s*$" /etc/login.defs && sed -ri "s/^(\s*)PASS_MIN_LEN\s+\S*(\s*#.*)?\s*$/\PASS_MIN_LEN    12/" /etc/login.defs || echo "PASS_MIN_LEN    12" >> /etc/login.defs
  

  # 设置口令生存周期
  Msg "1" "[设置口令生存周期]"
  echo \*\*\*\* 口令生成周期最小14天最大180天预警14前天 \*\*\*\*
  egrep -q "^\s*PASS_MAX_DAYS\s+\S*(\s*#.*)?\s*$" /etc/login.defs && sed -ri "s/^(\s*)PASS_MAX_DAYS\s+\S*(\s*#.*)?\s*$/\PASS_MAX_DAYS   180/" /etc/login.defs || echo "PASS_MAX_DAYS   180" >> /etc/login.defs
  egrep -q "^\s*PASS_MIN_DAYS\s+\S*(\s*#.*)?\s*$" /etc/login.defs && sed -ri "s/^(\s*)PASS_MIN_DAYS\s+\S*(\s*#.*)?\s*$/\PASS_MIN_DAYS   14/" /etc/login.defs || echo "PASS_MIN_DAYS   14" >> /etc/login.defs
  egrep -q "^\s*PASS_WARN_AGE\s+\S*(\s*#.*)?\s*$" /etc/login.defs && sed -ri "s/^(\s*)PASS_WARN_AGE\s+\S*(\s*#.*)?\s*$/\PASS_WARN_AGE   14/" /etc/login.defs || echo "PASS_WARN_AGE   14" >> /etc/login.defs

  # 密码重复使用次数限制
  Msg "1" "[密码重复使用次数限制]"
  echo \*\*\*\* 记住3次已使用的密码 \*\*\*\*
  if [[ ! -f "/etc/security/opasswd" || "$(ls -l /etc/security/opasswd | egrep -c '\-rw\-\-\-\-\-\-\-')" != "1" ]];then
    # 手动创建/etc/security/opasswd，解决首次登录修改密码时提示"passwd: Authentication token manipulation error"
    mv /etc/security/opasswd /etc/security/opasswd.old > /dev/null 2>&1
    touch /etc/security/opasswd
    chown root:root /etc/security/opasswd
    chmod +600 /etc/security/opasswd
  fi
  # 修改system-auth
  egrep -q "^\s*password\s*sufficient\s*pam_unix.so.*$" /etc/pam.d/system-auth && sed -ri "s/^\s*password\s*sufficient\s*pam_unix.so.*$/\password    sufficient    pam_unix.so sha512 shadow nullok try_first_pass use_authtok remember=3/" /etc/pam.d/system-auth || echo "password    sufficient    pam_unix.so sha512 shadow nullok try_first_pass use_authtok remember=3" >> /etc/pam.d/system-auth
  # 修改password-auth
  egrep -q "^\s*password\s*sufficient\s*pam_unix.so.*$" /etc/pam.d/password-auth && sed -ri "s/^\s*password\s*sufficient\s*pam_unix.so.*$/\password    sufficient    pam_unix.so sha512 shadow nullok try_first_pass use_authtok remember=3/" /etc/pam.d/password-auth || echo "password    sufficient    pam_unix.so sha512 shadow nullok try_first_pass use_authtok remember=3" >> /etc/pam.d/password-auth


  # 用户认证失败次数限制
  Msg "1" "[用户认证失败次数限制]"
  echo \*\*\*\* 连续登录失败5次锁定帐号5分钟 \*\*\*\*
  sed -ri "/^\s*auth\s+required\s+pam_tally2.so\s+.+(\s*#.*)?\s*$/d" /etc/pam.d/sshd /etc/pam.d/login /etc/pam.d/system-auth /etc/pam.d/password-auth
  sed -ri '1a auth       required     pam_tally2.so deny=5 unlock_time=300 even_deny_root root_unlock_time=30' /etc/pam.d/sshd /etc/pam.d/login /etc/pam.d/system-auth /etc/pam.d/password-auth
  egrep -q "^\s*account\s+required\s+pam_tally2.so\s*(\s*#.*)?\s*$" /etc/pam.d/sshd || sed -ri '/^password\s+.+(\s*#.*)?\s*$/i\account    required     pam_tally2.so' /etc/pam.d/sshd
  egrep -q "^\s*account\s+required\s+pam_tally2.so\s*(\s*#.*)?\s*$" /etc/pam.d/login || sed -ri '/^password\s+.+(\s*#.*)?\s*$/i\account    required     pam_tally2.so' /etc/pam.d/login
  egrep -q "^\s*account\s+required\s+pam_tally2.so\s*(\s*#.*)?\s*$" /etc/pam.d/system-auth || sed -ri '/^account\s+required\s+pam_permit.so\s*(\s*#.*)?\s*$/a\account     required      pam_tally2.so' /etc/pam.d/system-auth
  egrep -q "^\s*account\s+required\s+pam_tally2.so\s*(\s*#.*)?\s*$" /etc/pam.d/password-auth || sed -ri '/^account\s+required\s+pam_permit.so\s*(\s*#.*)?\s*$/a\account     required      pam_tally2.so' /etc/pam.d/password-auth
}

function AccountSession(){
  # 登录超时设置
  echo \*\*\*\* 设置登录超时时间为10分钟
  egrep -q "^\s*(export|)\s*TMOUT\S\w+.*$" /etc/profile && sed -ri "s/^\s*(export|)\s*TMOUT.\S\w+.*$/export TMOUT=600/" /etc/profile || echo "export TMOUT=600" >> /etc/profile
  egrep -q "^\s*.*ClientAliveInterval\s\w+.*$" /etc/ssh/sshd_config && sed -ri "s/^\s*.*ClientAliveInterval\s\w+.*$/ClientAliveInterval 600/" /etc/ssh/sshd_config || echo "ClientAliveInterval 600 " >> /etc/ssh/sshd_config
}


function OSSecuritySetting(){
  # 禁用ctrl+alt+del组合键，Redhat 6.X：
  echo
  echo \*\*\*\* 禁用ctrl+alt+del组合键
  #egrep -q "^\s*exec\s+/sbin/shutdown\s+.+$" /etc/init/control-alt-delete.conf && sed -ri "s/^\s*exec\s+\/sbin\/shutdown\s+.+$/exec \/usr\/bin\/logger \-p authpriv.notice \-t init 'Ctrl-Alt-Del was pressed and ignored'/" /etc/init/control-alt-delete.conf || echo "exec /usr/bin/logger -p authpriv.notice -t init 'Ctrl-Alt-Del was pressed and ignored' " >> /etc/init/control-alt-delete.conf
  # 禁用ctrl+alt+del组合键，Redhat 7.X：
  mv /usr/lib/systemd/system/ctrl-alt-del.target /usr/lib/systemd/system/ctrl-alt-del.target.bat&>/dev/null 2&>/dev/null


  # 删除潜在威胁文件
  echo
  echo \*\*\*\* 删除潜在威胁文件
  find / -maxdepth 3 -name hosts.equiv | xargs rm -rf
  find / -maxdepth 3 -name .netrc | xargs rm -rf
  find / -maxdepth 3 -name .rhosts | xargs rm -rf


  # 配置自动屏幕锁定（适用于具备图形界面的设备）
  echo
  echo \*\*\*\* 对于有图形界面的系统配置10分钟屏幕锁定
  # gconftool-2 > /dev/null 2>&1
  # if [[ "$?" == 0 ]];then
  #   gconftool-2 --direct \
  #   --config-source xml:readwrite:/etc/gconf/gconf.xml.mandatory \
  #   --type bool \
  #   --set /apps/gnome-screensaver/idle_activation_enabled true \
  #   --set /apps/gnome-screensaver/lock_enabled true \
  #   --type int \
  #   --set /apps/gnome-screensaver/idle_delay 10 \
  #   --type string \
  #   --set /apps/gnome-screensaver/mode blank-only
  # fi
}


function LoggerSecurity(){ 
  # 记录su命令使用情况
  echo
  echo \*\*\*\* 配置并记录su命令使用情况
  egrep -q "^\s*authpriv\.\*\s+.+$" /etc/rsyslog.conf && sed -ri "s/^\s*authpriv\.\*\s+.+$/authpriv.*                                              \/var\/log\/secure/" /etc/rsyslog.conf || echo "authpriv.*                                              /var/log/secure" >> /etc/rsyslog.conf


  # 日志文件非全局可写认证权限
  echo
  echo \*\*\*\* 设置日志文件非全局可写
  chmod 755 /var/log/messages;
  chmod 775 /var/log/spooler;
  chmod 775 /var/log/mail&>/dev/null 2&>/dev/null;
  chmod 775 /var/log/cron;
  chmod 775 /var/log/secure;
  chmod 775 /var/log/maillog;
  chmod 775 /var/log/localmessages&>/dev/null 2&>/dev/null


  # 记录安全事件日志
  echo
  echo \*\*\*\* 配置安全事件日志审计
  touch /var/log/adm&>/dev/null; chmod 755 /var/log/adm
  semanage fcontext -a -t security_t '/var/log/adm'
  restorecon -v '/var/log/adm'&>/dev/null
  egrep -q "^\s*\*\.err;kern.debug;daemon.notice\s+.+$" /etc/rsyslog.conf && sed -ri "s/^\s*\*\.err;kern.debug;daemon.notice\s+.+$/*.err;kern.debug;daemon.notice           \/var\/adm\/messages/" /etc/rsyslog.conf || echo "*.err;kern.debug;daemon.notice           /var/log/adm" >> /etc/rsyslog.conf


  # 历史命令设置
  echo
  echo \*\*\*\* 设置保留历史命令的条数为30，并加上时间戳
  egrep -q "^\s*HISTSIZE\s*\W+[0-9].+$" /etc/profile && sed -ri "s/^\s*HISTSIZE\W+[0-9].+$/HISTSIZE=50/" /etc/profile || echo "HISTSIZE=50" >> /etc/profile
  egrep -q "^\s*HISTTIMEFORMAT\s*\S+.+$" /etc/profile && sed -ri "s/^\s*HISTTIMEFORMAT\s*\S+.+$/HISTTIMEFORMAT='%F %T | '/" /etc/profile || echo "HISTTIMEFORMAT='%F %T | '" >> /etc/profile
  egrep -q "^\s*export\s*HISTTIMEFORMAT.*$" /etc/profile || echo "export HISTTIMEFORMAT" >> /etc/profile
}


function OSServiceSecurity() {
  # 限制不必要的服务
  echo
  echo \*\*\*\* 限制不必要的服务
  systemctl disable rsh&>/dev/null 2&>/dev/null;systemctl disable talk&>/dev/null 2&>/dev/null;systemctl disable telnet&>/dev/null 2&>/dev/null;systemctl disable tftp&>/dev/null 2&>/dev/null;systemctl disable rsync&>/dev/null 2&>/dev/null;systemctl disable xinetd&>/dev/null 2&>/dev/null;systemctl disable nfs&>/dev/null 2&>/dev/null;systemctl disable nfslock&>/dev/null 2&>/dev/null
}


function ServiceFtp(){
  # FTP Banner 设置
  echo
  echo \*\*\*\* FTP Banner 设置
  systemctl list-unit-files|grep vsftpd > /dev/null && sed -ri "/^\s*ftpd_banner\s*\W+.+$/s/^/#/" /etc/vsftpd/vsftpd.conf && echo "ftpd_banner='Authorized only. All activity will be monitored and reported.'" >> /etc/vsftpd/vsftpd.conf


  # 禁止匿名用户登录FTP
  echo
  echo \*\*\*\* 禁止匿名用户登录FTP
  systemctl list-unit-files|grep vsftpd > /dev/null && sed -ri "/^\s*anonymous_enable\s*\W+.+$/s/^/#/" /etc/vsftpd/vsftpd.conf && echo "anonymous_enable=NO" >> /etc/vsftpd/vsftpd.conf

  # 禁止root用户登录FTP
  echo
  echo \*\*\*\* 禁止root用户登录FTP
  systemctl list-unit-files|grep vsftpd > /dev/null && echo "root" >> /etc/vsftpd/ftpusers

  # 限制FTP用户上传的文件所具有的权限
  echo
  echo \*\*\*\* 限制FTP用户上传的文件所具有的权限
  systemctl list-unit-files|grep vsftpd > /dev/null && sed -ri "/^\s*write_enable\s*\W+.+$/s/^/#/" /etc/vsftpd/vsftpd.conf && echo "write_enable=NO" >> /etc/vsftpd/vsftpd.conf
  systemctl list-unit-files|grep vsftpd > /dev/null && sed -ri "/^\s*ls_recurse_enable\s*\W+.+$/s/^/#/" /etc/vsftpd/vsftpd.conf && echo "ls_recurse_enable=NO" >> /etc/vsftpd/vsftpd.conf
  systemctl list-unit-files|grep vsftpd > /dev/null && sed -ri "/^\s*anon_umask\s*\W+.+$/s/^/#/" /etc/vsftpd/vsftpd.conf && echo "anon_umask=077" >> /etc/vsftpd/vsftpd.conf
  systemctl list-unit-files|grep vsftpd > /dev/null && sed -ri "/^\s*local_umask\s*\W+.+$/s/^/#/" /etc/vsftpd/vsftpd.conf && echo "local_umask=022" >> /etc/vsftpd/vsftpd.conf

  # 限制FTP用户登录后能访问的目录
  echo
  echo \*\*\*\* 限制FTP用户登录后能访问的目录
  systemctl list-unit-files|grep vsftpd > /dev/null && sed -ri "/^\s*chroot_local_user\s*\W+.+$/s/^/#/" /etc/vsftpd/vsftpd.conf && echo "chroot_local_user=NO" >> /etc/vsftpd/vsftpd.conf
}



function ServicesTelnet(){
  # 禁用telnet服务
  echo
  echo \*\*\*\* 配置禁用telnet服务
  egrep -q "^\s*telnet\s+\d*.+$" /etc/services && sed -ri "/^\s*telnet\s+\d*.+$/s/^/# /" /etc/services
}


function ServicesSSH(){
  # SSH登录前警告Banner
  echo
  echo \*\*\*\* 设置ssh登录前警告Banner
  echo "**************WARNING**************" >> /etc/issue;echo "Authorized only. All activity will be monitored and reported." >> /etc/issue
  egrep -q "^\s*(banner|Banner)\s+\W+.*$" /etc/ssh/sshd_config && sed -ri "s/^\s*(banner|Banner)\s+\W+.*$/Banner \/etc\/issue/" /etc/ssh/sshd_config || echo "Banner /etc/issue" >> /etc/ssh/sshd_config

  # SSH登录后Banner
  echo
  echo \*\*\*\* 设置ssh登录后Banner
  echo "**************WARNING**************" >> /etc/motd;echo "Login success. All activity will be monitored and reported." >> /etc/motd

  # 禁止root远程登录（暂不配置）
  :<<!
  echo
  echo \*\*\*\* 禁止root远程SSH登录
  egrep -q "^\s*PermitRootLogin\s+.+$" /etc/ssh/sshd_config && sed -ri "s/^\s*PermitRootLogin\s+.+$/PermitRootLogin no/" /etc/ssh/sshd_config || echo "PermitRootLogin no" >> /etc/ssh/sshd_config
!
  # SSH 安全配置
  # 严格模式
  egrep -q "^\s*StrictModes\s+.+$" /etc/ssh/sshd_config && sed -ri "s/^(#)?\s*StrictModes\s+.+$/StrictModes yes/" /etc/ssh/sshd_config || echo "StrictModes yes" >> /etc/ssh/sshd_config
  # 缺省端口改变成为制定端口，重启服务需要 setenforce 0 临时关闭Selinux
  egrep -q "^\s*Port\s+.+$" /etc/ssh/sshd_config && sed -ri "s/^(#)?\s*Port\s+.+$/Port ${SSHPORT}/" /etc/ssh/sshd_config || echo "Port ${SSHPORT}" >> /etc/ssh/sshd_config
  # 禁用端口转发
  egrep -q "^\s*X11Forwarding\s+.+$" /etc/ssh/sshd_config && sed -ri "s/^(#)?\s*X11Forwarding\s+.+$/X11Forwarding no/" /etc/ssh/sshd_config || echo "X11Forwarding no" >> /etc/ssh/sshd_config
  egrep -q "^\s*AllowTcpForwarding\s+.+$" /etc/ssh/sshd_config && sed -ri "s/^(#)?\s*AllowTcpForwarding\s+.+$/AllowTcpForwarding no/" /etc/ssh/sshd_config || echo "AllowTcpForwarding no" >> /etc/ssh/sshd_config
  egrep -q "^\s*AllowAgentForwarding\s+.+$" /etc/ssh/sshd_config && sed -ri "s/^(#)?\s*AllowAgentForwarding\s+.+$/AllowAgentForwarding no/" /etc/ssh/sshd_config || echo "AllowAgentForwarding no" >> /etc/ssh/sshd_config
  # CentOS7 (缺省IgnoreRhosts yes) 关闭禁用用户的 .rhosts 文件  ~/.ssh/.rhosts 来做为认证
  egrep -q "^(#)?\s*IgnoreRhosts\s+.+$" /etc/ssh/sshd_config && sed -ri "s/^(#)?\s*IgnoreRhosts\s+.+$/IgnoreRhosts yes/" /etc/ssh/sshd_config || echo "IgnoreRhosts yes" >> /etc/ssh/sshd_config
  # 重置SSH启动端口后，防止因为Selinux无法进行重启ssh应用;
  semanage port -a -t ssh_port_t -p tcp 20211
}

function ServicesSnmp(){

if [[ -d /etc/snmp/ ]];then
  # 修改SNMP默认团体字
  echo
  echo \*\*\*\* 修改SNMP默认团体字 \*\*\*\*
  cat > /etc/snmp/snmpd.conf <<EOF
  com2sec name  default    $password   
  group   ****Grp         v1           ****Sec
  group   ****Grp         v2c          ****Sec
  view    systemview      included        .1                      80
  view    systemview      included        .1.3.6.1.2.1.1
  view    systemview      included        .1.3.6.1.2.1.25.1.1
  view    ****View        included        .1.3.6.1.4.1.2021.80
  access  ****Grp         ""      any       noauth    exact  systemview none none
  access  ****Grp         ""      any       noauth    exact  ****View   none none
  dontLogTCPWrappersConnects yes
  #
  #
  #exec mq_ttt /home/107_mq.sh
  #exec core_timebargain_ttt /home/105_core_timebargain.sh
  #exec core_espot_ttt /home/101_core_espot.sh
  #exec core_conditionPlugin_ttt /home/103_core_conditionPlugin.sh
  #
  #
  trapcommunity $password
  authtrapenable 1
  trap2sink IP
  agentSecName ****Sec
  rouser ****Sec
  defaultMonitors yes
  linkUpDownNotifications yes
EOF
fi
}


function AppliactionManagement() {
  systemctl restart sshd
}

function FirewallSetting(){
  # 应用端口开放访问
  firewall-cmd --add-port=${SSHPORT}/tcp --permanent

  # 重载防火墙策略
  firewall-cmd --reload
}


function AppliactionSecurity(){
  OSServiceSecurity
  ServicesSSH
  ServiceFtp
  ServicesTelnet
  ServicesSnmp
}



function main(){
  # 用户会话权限策略相关
  AccountAuthority
  AccountPolicy
  AccountSecurity
  AccountSession

  # 系统安全
  OSSecuritySetting

  # 日志安全
  LoggerSecurity

  # 应用安全
  AppliactionSecurity


  # 防火墙设置
  FirewallSetting

  # 应用服务管理
  AppliactionManagement
}


setenforce 0
main

