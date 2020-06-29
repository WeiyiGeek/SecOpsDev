!/bin/bash
# 20170122 修改/etc/passwd 、 /etc/shadow 缺省权限设置 ，缺省注释“禁止root从远程登录”
# 20170125 手动创建/etc/security/opasswd，解决首次登录修改密码时提示 "passwd: Authentication token manipulation error"
# 20170129 放宽/etc/passwd、/etc/shadow、/etc/security的权限，解决图形界面oracle用户无法登录的问题

echo \*\*\*\* 开始自动配置安全基线

# 设置口令长度最小值和密码复杂度策略
echo
echo \*\*\*\* 设置口令长度最小值和密码复杂度策略
# 大写字母、小写字母、数字、特殊字符 4选3
# 修改system-auth
egrep -q "^\s*password\s*(requisite|required)\s*pam_cracklib.so.*$" /etc/pam.d/system-auth  && sed -ri "s/^\s*password\s*(requisite|required)\s*pam_cracklib.so.*$/\password    requisite     pam_cracklib.so try_first_pass retry=3 minlen=12 dcredit=-1 ocredit=-1 lcredit=-1/" /etc/pam.d/system-auth || echo "password    requisite     pam_cracklib.so try_first_pass retry=3 minlen=12 dcredit=-1 ocredit=-1 lcredit=-1" >> /etc/pam.d/system-auth
# 修改password-auth
egrep -q "^\s*password\s*(requisite|required)\s*pam_cracklib.so.*$" /etc/pam.d/password-auth && sed -ri "s/^\s*password\s*(requisite|required)\s*pam_cracklib.so.*$/\password    requisite     pam_cracklib.so try_first_pass retry=3 minlen=12 dcredit=-1 ocredit=-1 lcredit=-1/" /etc/pam.d/password-auth || echo "password    requisite     pam_cracklib.so try_first_pass retry=3 minlen=12 dcredit=-1 ocredit=-1 lcredit=-1" >> /etc/pam.d/password-auth
# 修改login.defs
egrep -q "^\s*PASS_MIN_LEN\s+\S*(\s*#.*)?\s*$" /etc/login.defs && sed -ri "s/^(\s*)PASS_MIN_LEN\s+\S*(\s*#.*)?\s*$/\PASS_MIN_LEN    12/" /etc/login.defs || echo "PASS_MIN_LEN    12" >> /etc/login.defs

# 设置口令生存周期
:<<!
echo
echo \*\*\*\* 设置口令生存周期
egrep -q "^\s*PASS_MAX_DAYS\s+\S*(\s*#.*)?\s*$" /etc/login.defs && sed -ri "s/^(\s*)PASS_MAX_DAYS\s+\S*(\s*#.*)?\s*$/\PASS_MAX_DAYS   180/" /etc/login.defs || echo "PASS_MAX_DAYS   180" >> /etc/login.defs
egrep -q "^\s*PASS_MIN_DAYS\s+\S*(\s*#.*)?\s*$" /etc/login.defs && sed -ri "s/^(\s*)PASS_MIN_DAYS\s+\S*(\s*#.*)?\s*$/\PASS_MIN_DAYS   14/" /etc/login.defs || echo "PASS_MIN_DAYS   14" >> /etc/login.defs
egrep -q "^\s*PASS_WARN_AGE\s+\S*(\s*#.*)?\s*$" /etc/login.defs && sed -ri "s/^(\s*)PASS_WARN_AGE\s+\S*(\s*#.*)?\s*$/\PASS_WARN_AGE   14/" /etc/login.defs || echo "PASS_WARN_AGE   14" >> /etc/login.defs
!
# 密码重复使用次数限制
echo
echo \*\*\*\* 记住3次已使用的密码
# 修改system-auth
egrep -q "^\s*password\s*sufficient\s*pam_unix.so.*$" /etc/pam.d/system-auth && sed -ri "s/^\s*password\s*sufficient\s*pam_unix.so.*$/\password    sufficient    pam_unix.so sha512 shadow nullok try_first_pass use_authtok remember=3/" /etc/pam.d/system-auth || echo "password    sufficient    pam_unix.so sha512 shadow nullok try_first_pass use_authtok remember=3" >> /etc/pam.d/system-auth
# 修改password-auth
egrep -q "^\s*password\s*sufficient\s*pam_unix.so.*$" /etc/pam.d/password-auth && sed -ri "s/^\s*password\s*sufficient\s*pam_unix.so.*$/\password    sufficient    pam_unix.so sha512 shadow nullok try_first_pass use_authtok remember=3/" /etc/pam.d/password-auth || echo "password    sufficient    pam_unix.so sha512 shadow nullok try_first_pass use_authtok remember=3" >> /etc/pam.d/password-auth

# 锁定与设备运行、维护等工作无关的账号
echo
echo \*\*\*\* 锁定与设备运行、维护等工作无关的账号
passwd -l adm&>/dev/null 2&>/dev/null; passwd -l daemon&>/dev/null 2&>/dev/null; passwd -l bin&>/dev/null 2&>/dev/null; passwd -l sys&>/dev/null 2&>/dev/null; passwd -l lp&>/dev/null 2&>/dev/null; passwd -l uucp&>/dev/null 2&>/dev/null; passwd -l nuucp&>/dev/null 2&>/dev/null; passwd -l smmsplp&>/dev/null 2&>/dev/null; passwd -l mail&>/dev/null 2&>/dev/null; passwd -l operator&>/dev/null 2&>/dev/null; passwd -l games&>/dev/null 2&>/dev/null; passwd -l gopher&>/dev/null 2&>/dev/null; passwd -l ftp&>/dev/null 2&>/dev/null; passwd -l nobody&>/dev/null 2&>/dev/null; passwd -l nobody4&>/dev/null 2&>/dev/null; passwd -l noaccess&>/dev/null 2&>/dev/null; passwd -l listen&>/dev/null 2&>/dev/null; passwd -l webservd&>/dev/null 2&>/dev/null; passwd -l rpm&>/dev/null 2&>/dev/null; passwd -l dbus&>/dev/null 2&>/dev/null; passwd -l avahi&>/dev/null 2&>/dev/null; passwd -l mailnull&>/dev/null 2&>/dev/null; passwd -l nscd&>/dev/null 2&>/dev/null; passwd -l vcsa&>/dev/null 2&>/dev/null; passwd -l rpc&>/dev/null 2&>/dev/null; passwd -l rpcuser&>/dev/null 2&>/dev/null; passwd -l nfs&>/dev/null 2&>/dev/null; passwd -l sshd&>/dev/null 2&>/dev/null; passwd -l pcap&>/dev/null 2&>/dev/null; passwd -l ntp&>/dev/null 2&>/dev/null; passwd -l haldaemon&>/dev/null 2&>/dev/null; passwd -l distcache&>/dev/null 2&>/dev/null; passwd -l webalizer&>/dev/null 2&>/dev/null; passwd -l squid&>/dev/null 2&>/dev/null; passwd -l xfs&>/dev/null 2&>/dev/null; passwd -l gdm&>/dev/null 2&>/dev/null; passwd -l sabayon&>/dev/null 2&>/dev/null; passwd -l named&>/dev/null 2&>/dev/null
echo \*\*\*\* 锁定帐号完成

# 用户认证失败次数限制（可选）
:<<!
echo
echo \*\*\*\* 连续登录失败5次锁定帐号5分钟
sed -ri "/^\s*auth\s+required\s+pam_tally2.so\s+.+(\s*#.*)?\s*$/d" /etc/pam.d/sshd /etc/pam.d/login /etc/pam.d/system-auth /etc/pam.d/password-auth
sed -ri '1a auth       required     pam_tally2.so deny=5 unlock_time=300 even_deny_root root_unlock_time=30' /etc/pam.d/sshd /etc/pam.d/login /etc/pam.d/system-auth /etc/pam.d/password-auth
egrep -q "^\s*account\s+required\s+pam_tally2.so\s*(\s*#.*)?\s*$" /etc/pam.d/sshd || sed -ri '/^password\s+.+(\s*#.*)?\s*$/i\account    required     pam_tally2.so' /etc/pam.d/sshd
egrep -q "^\s*account\s+required\s+pam_tally2.so\s*(\s*#.*)?\s*$" /etc/pam.d/login || sed -ri '/^password\s+.+(\s*#.*)?\s*$/i\account    required     pam_tally2.so' /etc/pam.d/login
egrep -q "^\s*account\s+required\s+pam_tally2.so\s*(\s*#.*)?\s*$" /etc/pam.d/system-auth || sed -ri '/^account\s+required\s+pam_permit.so\s*(\s*#.*)?\s*$/a\account     required      pam_tally2.so' /etc/pam.d/system-auth
egrep -q "^\s*account\s+required\s+pam_tally2.so\s*(\s*#.*)?\s*$" /etc/pam.d/password-auth || sed -ri '/^account\s+required\s+pam_permit.so\s*(\s*#.*)?\s*$/a\account     required      pam_tally2.so' /etc/pam.d/password-auth
!
# 用户的umask安全配置
echo
echo \*\*\*\* 修改umask为022
egrep -q "^\s*umask\s+\w+.*$" /etc/profile && sed -ri "s/^\s*umask\s+\w+.*$/umask 022/" /etc/profile || echo "umask 022" >> /etc/profile
egrep -q "^\s*umask\s+\w+.*$" /etc/csh.login && sed -ri "s/^\s*umask\s+\w+.*$/umask 022/" /etc/csh.login || echo "umask 022" >>/etc/csh.login
egrep -q "^\s*umask\s+\w+.*$" /etc/csh.cshrc && sed -ri "s/^\s*umask\s+\w+.*$/umask 022/" /etc/csh.cshrc || echo "umask 022" >> /etc/csh.cshrc
egrep -q "^\s*umask\s+\w+.*$" /etc/bashrc && sed -ri "s/^\s*umask\s+\w+.*$/umask 022/" /etc/bashrc || echo "umask 022" >> /etc/bashrc

# 重要目录和文件的权限设置
echo
echo \*\*\*\* 设置重要目录和文件的权限
chmod 755 /etc; chmod 750 /etc/rc.d/init.d; chmod 777 /tmp; chmod 600 /etc/inetd.conf&>/dev/null 2&>/dev/null; chmod 755 /etc/passwd; chmod 755 /etc/shadow; chmod 644 /etc/group; chmod 755 /etc/security; chmod 644 /etc/services; chmod 750 /etc/rc*.d

# 用户目录缺省访问权限设置
echo
echo \*\*\*\* 设置用户目录默认权限为022
egrep -q "^\s*(umask|UMASK)\s+\w+.*$" /etc/login.defs && sed -ri "s/^\s*(umask|UMASK)\s+\w+.*$/UMASK 022/" /etc/login.defs || echo "UMASK 022" >> /etc/login.defs

# 登录超时设置
echo
echo \*\*\*\* 设置登录超时时间为5分钟
egrep -q "^\s*(export|)\s*TMOUT\S\w+.*$" /etc/profile && sed -ri "s/^\s*(export|)\s*TMOUT.\S\w+.*$/export TMOUT=300/" /etc/profile || echo "export TMOUT=300" >> /etc/profile

# SSH登录前警告Banner
echo
echo \*\*\*\* 设置ssh登录前警告Banner
echo "****************** WARNING**************" >> /etc/issue;echo "Authorized only. All activity will be monitored and reported." >> /etc/issue
egrep -q "^\s*(banner|Banner)\s+\W+.*$" /etc/ssh/sshd_config && sed -ri "s/^\s*(banner|Banner)\s+\W+.*$/Banner \/etc\/issue/" /etc/ssh/sshd_config || echo "Banner /etc/issue" >> /etc/ssh/sshd_config

# SSH登录后Banner
echo
echo \*\*\*\* 设置ssh登录后Banner
echo "****************** WARNING**************" > /etc/motd;echo "Login success. All activity will be monitored and reported." >> /etc/motd

# 日志文件非全局可写
echo
echo \*\*\*\* 设置日志文件非全局可写
chmod 755 /var/log/messages; chmod 775 /var/log/spooler; chmod 775 /var/log/mail&>/dev/null 2&>/dev/null; chmod 775 /var/log/cron; chmod 775 /var/log/secure; chmod 775 /var/log/maillog; chmod 775 /var/log/localmessages&>/dev/null 2&>/dev/null

# 记录su命令使用情况
echo
echo \*\*\*\* 配置并记录su命令使用情况
egrep -q "^\s*authpriv\.\*\s+.+$" /etc/rsyslog.conf && sed -ri "s/^\s*authpriv\.\*\s+.+$/authpriv.*                                              \/var\/log\/secure/" /etc/rsyslog.conf || echo "authpriv.*                                              /var/log/secure" >> /etc/rsyslog.conf

# 记录安全事件日志
echo
echo \*\*\*\* 配置安全事件日志审计
touch /var/log/adm&>/dev/null; chmod 755 /var/log/adm
mkdir /etc/adm&>/dev/null; touch /etc/adm/messages&>/dev/null; chmod 666 /etc/adm/messages
egrep -q "^\s*\*\.err;kern.debug;daemon.notice\s+.+$" /etc/rsyslog.conf && sed -ri "s/^\s*\*\.err;kern.debug;daemon.notice\s+.+$/*.err;kern.debug;daemon.notice          \/var\/adm\/messages/" /etc/rsyslog.conf || echo "*.err;kern.debug;daemon.notice          /var/log/adm" >> /etc/rsyslog.conf

# 禁用telnet服务
echo
echo \*\*\*\* 配置禁用telnet服务
egrep -q "^\s*telnet\s+\d*.+$" /etc/services && sed -ri "/^\s*telnet\s+\d*.+$/s/^/#/" /etc/services

# 禁止root远程登录（缺省不配置）
:<<!
echo
echo \*\*\*\* 禁止root远程SSH登录
egrep -q "^\s*PermitRootLogin\s+.+$" /etc/ssh/sshd_config && sed -ri "s/^\s*PermitRootLogin\s+.+$/PermitRootLogin no/" /etc/ssh/sshd_config || echo "PermitRootLogin no" >> /etc/ssh/sshd_config
!

# 修改SNMP默认团体字（需自定义username password IP）
echo
echo \*\*\*\* 修改SNMP默认团体字
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

# 禁止匿名用户登录FTP
echo
echo \*\*\*\* 禁止匿名用户登录FTP
chkconfig --list|grep vsftpd > /dev/null && sed -ri "/^\s*anonymous_enable\s*\W+.+$/s/^/#/" /etc/vsftpd/vsftpd.conf && echo "anonymous_enable=NO" >> /etc/vsftpd/vsftpd.conf

# 禁止root用户登录FTP
echo
echo \*\*\*\* 禁止root用户登录FTP
chkconfig --list|grep vsftpd > /dev/null && echo "root" >> /etc/vsftpd/ftpusers

# 禁用ctrl+alt+del组合键
echo
echo \*\*\*\* 禁用ctrl+alt+del组合键
egrep -q "^\s*exec\s+/sbin/shutdown\s+.+$" /etc/init/control-alt-delete.conf && sed -ri "s/^\s*exec\s+\/sbin\/shutdown\s+.+$/exec \/usr\/bin\/logger \-p authpriv.notice \-t init 'Ctrl-Alt-Del was pressed and ignored'/" /etc/init/control-alt-delete.conf || echo "exec /usr/bin/logger -p authpriv.notice -t init 'Ctrl-Alt-Del was pressed and ignored' " >> /etc/init/control-alt-delete.conf

# 删除潜在威胁文件
echo
echo \*\*\*\* 删除潜在威胁文件
find / -maxdepth 3 -name hosts.equiv | xargs rm -rf
find / -maxdepth 3 -name .netrc | xargs rm -rf
find / -maxdepth 3 -name .rhosts | xargs rm -rf

# 限制不必要的服务
echo
echo \*\*\*\* 限制不必要的服务
chkconfig chargen-dgram off&>/dev/null 2&>/dev/null;chkconfig chargen-stream off&>/dev/null 2&>/dev/null;chkconfig daytime-dgram off&>/dev/null 2&>/dev/null;chkconfig daytime-stream off&>/dev/null 2&>/dev/null;chkconfig discard-dgram off&>/dev/null 2&>/dev/null;chkconfig discard-stream off&>/dev/null 2&>/dev/null;chkconfig echo-dgram off&>/dev/null 2&>/dev/null;chkconfig echo-stream off&>/dev/null 2&>/dev/null;chkconfig time-dgram off&>/dev/null 2&>/dev/null;chkconfig time-stream off&>/dev/null 2&>/dev/null;chkconfig rexec off&>/dev/null 2&>/dev/null;chkconfig rlogin off&>/dev/null 2&>/dev/null;chkconfig rsh off&>/dev/null 2&>/dev/null;chkconfig talk off&>/dev/null 2&>/dev/null;chkconfig telnet off&>/dev/null 2&>/dev/null;chkconfig tftp off&>/dev/null 2&>/dev/null;chkconfig rsync off&>/dev/null 2&>/dev/null;chkconfig xinetd off&>/dev/null 2&>/dev/null;chkconfig nfs off&>/dev/null 2&>/dev/null;chkconfig nfslock off&>/dev/null 2&>/dev/null

# 历史命令设置
echo
echo \*\*\*\* 设置保留历史命令的条数为10，并加上时间戳
egrep -q "^\s*HISTSIZE\s*\W+[0-9].+$" /etc/profile && sed -ri "s/^\s*HISTSIZE\W+[0-9].+$/HISTSIZE=10/" /etc/profile || echo "HISTSIZE=10" >> /etc/profile
egrep -q "^\s*HISTTIMEFORMAT\s*\S+.+$" /etc/profile && sed -ri "s/^\s*HISTTIMEFORMAT\s*\S+.+$/HISTTIMEFORMAT='%F %T | '/" /etc/profile || echo "HISTTIMEFORMAT='%F %T | '" >> /etc/profile
egrep -q "^\s*export\s*HISTTIMEFORMAT.*$" /etc/profile || echo "export HISTTIMEFORMAT" >> /etc/profile

# 限制FTP用户上传的文件所具有的权限
echo
echo \*\*\*\* 限制FTP用户上传的文件所具有的权限
chkconfig --list|grep vsftpd > /dev/null && sed -ri "/^\s*write_enable\s*\W+.+$/s/^/#/" /etc/vsftpd/vsftpd.conf && echo "write_enable=NO" >> /etc/vsftpd/vsftpd.conf
chkconfig --list|grep vsftpd > /dev/null && sed -ri "/^\s*ls_recurse_enable\s*\W+.+$/s/^/#/" /etc/vsftpd/vsftpd.conf && echo "ls_recurse_enable=NO" >> /etc/vsftpd/vsftpd.conf
chkconfig --list|grep vsftpd > /dev/null && sed -ri "/^\s*anon_umask\s*\W+.+$/s/^/#/" /etc/vsftpd/vsftpd.conf && echo "anon_umask=077" >> /etc/vsftpd/vsftpd.conf
chkconfig --list|grep vsftpd > /dev/null && sed -ri "/^\s*local_umask\s*\W+.+$/s/^/#/" /etc/vsftpd/vsftpd.conf && echo "local_umask=022" >> /etc/vsftpd/vsftpd.conf

# 限制FTP用户登录后能访问的目录
echo
echo \*\*\*\* 限制FTP用户登录后能访问的目录
chkconfig --list|grep vsftpd > /dev/null && sed -ri "/^\s*chroot_local_user\s*\W+.+$/s/^/#/" /etc/vsftpd/vsftpd.conf && echo "chroot_local_user=NO" >> /etc/vsftpd/vsftpd.conf

# 配置自动屏幕锁定（适用于具备图形界面的设备）
echo
echo \*\*\*\* 对于有图形界面的系统配置5分钟屏幕锁定
gconftool-2 --direct \
--config-source xml:readwrite:/etc/gconf/gconf.xml.mandatory \
--type bool \
--set /apps/gnome-screensaver/idle_activation_enabled true \
--set /apps/gnome-screensaver/lock_enabled true \
--type int \
--set /apps/gnome-screensaver/idle_delay 10 \
--type string \
--set /apps/gnome-screensaver/mode blank-only

# FTP Banner 设置
echo
echo \*\*\*\* FTP Banner 设置
chkconfig --list|grep vsftpd > /dev/null && sed -ri "/^\s*ftpd_banner\s*\W+.+$/s/^/#/" /etc/vsftpd/vsftpd.conf && echo "ftpd_banner='Authorized only. All activity will be monitored and reported.'" >> /etc/vsftpd/vsftpd.conf

# 配置"用户下次登录时需更改密码"
echo
echo \*\*\*\* 配置下次登录时修改root密码
chage -d0 root

# 手动创建/etc/security/opasswd，解决首次登录修改密码时提示"passwd: Authentication token manipulation error"
mv /etc/security/opasswd /etc/security/opasswd.old
touch /etc/security/opasswd

#结束
