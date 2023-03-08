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


# 函数名称: sec_usercheck
# 函数用途: 用于锁定或者删除多余的系统账户
# 函数参数: 无
function sec_usercheck () {
  log::info "[${COUNT}] Lock or delete redundant system accounts."
  log::info "[-] 用于锁定或者删除多余的系统账户."
  cp -a /etc/shadow ${BACKUPDIR}
  local defaultuser
  defaultuser=(root daemon bin sys games man lp mail news uucp proxy www-data backup list irc gnats nobody systemd-network systemd-resolve systemd-timesync messagebus syslog _apt tss uuidd tcpdump landscape pollinate usbmux sshd systemd-coredump sync _rpc _chrony statd ubuntu )
  for i in $(cat /etc/passwd | cut -d ":" -f 1,7);do
    flag=0; name=${i%%:*}; terminal=${i##*:}
    if [[ "${terminal}" == "/bin/bash" || "${terminal}" == "/bin/sh" ]];then
      log::warning "${name} 用户，shell终端为 /bin/bash 或者 /bin/sh"
    fi
    for j in ${defaultuser[@]};do
      if [[ "${name}" == "${j}" ]];then
        flag=1
        break;
      fi
    done
    if [[ $flag -eq 0 ]];then
      log::warning "${name} 为非默认用户, 请排查是否为内部人员创建."
    fi
  done

  # 请输入是否删除无用服务账号以及锁定服务账号登陆,缺省为N
  read -t ${VAR_VERIFY_TIMEOUT} -p "Please input, Lock useless account. (Y/N) : " VERIFY
  if [[ ${VERIFY:="N"} == "Y" || ${VERIFY:="N"} == "y" ]]; then
    # userdel -r lxd && groupdel lxd
    passwd -l lxd&>/dev/null 2&>/dev/null;passwd -l adm&>/dev/null 2&>/dev/null; passwd -l daemon&>/dev/null 2&>/dev/null; passwd -l bin&>/dev/null 2&>/dev/null; passwd -l sys&>/dev/null 2&>/dev/null; passwd -l lp&>/dev/null 2&>/dev/null; passwd -l uucp&>/dev/null 2&>/dev/null; passwd -l nuucp&>/dev/null 2&>/dev/null; passwd -l smmsplp&>/dev/null 2&>/dev/null; passwd -l mail&>/dev/null 2&>/dev/null; passwd -l operator&>/dev/null 2&>/dev/null; passwd -l games&>/dev/null 2&>/dev/null; passwd -l gopher&>/dev/null 2&>/dev/null; passwd -l ftp&>/dev/null 2&>/dev/null; passwd -l nobody&>/dev/null 2&>/dev/null; passwd -l nobody4&>/dev/null 2&>/dev/null; passwd -l noaccess&>/dev/null 2&>/dev/null; passwd -l listen&>/dev/null 2&>/dev/null; passwd -l webservd&>/dev/null 2&>/dev/null; passwd -l rpm&>/dev/null 2&>/dev/null; passwd -l dbus&>/dev/null 2&>/dev/null; passwd -l avahi&>/dev/null 2&>/dev/null; passwd -l mailnull&>/dev/null 2&>/dev/null; passwd -l nscd&>/dev/null 2&>/dev/null; passwd -l vcsa&>/dev/null 2&>/dev/null; passwd -l rpc&>/dev/null 2&>/dev/null; passwd -l rpcuser&>/dev/null 2&>/dev/null; passwd -l nfs&>/dev/null 2&>/dev/null; passwd -l sshd&>/dev/null 2&>/dev/null; passwd -l pcap&>/dev/null 2&>/dev/null; passwd -l ntp&>/dev/null 2&>/dev/null; passwd -l haldaemon&>/dev/null 2&>/dev/null; passwd -l distcache&>/dev/null 2&>/dev/null; passwd -l webalizer&>/dev/null 2&>/dev/null; passwd -l squid&>/dev/null 2&>/dev/null; passwd -l xfs&>/dev/null 2&>/dev/null; passwd -l gdm&>/dev/null 2&>/dev/null; passwd -l sabayon&>/dev/null 2&>/dev/null; passwd -l named&>/dev/null 2&>/dev/null
  fi

  log::success "[${COUNT}] This operation is completed!"
  sleep 1
  ((COUNT++))
}


# 函数名称: sec_userconfig
# 函数用途: 针对拥有ssh远程登陆权限的用户进行密码口令设置。
# 函数参数: 无
function sec_userconfig () {
  log::info "[${COUNT}] System account password setting."
  log::info "[-] 针对拥有ssh远程登陆权限的用户进行密码口令更改."
  cp -a /etc/passwd ${BACKUPDIR}
  cp -a /etc/group ${BACKUPDIR}
  cp -a /etc/shadow ${BACKUPDIR}
  cp -a /etc/login.defs ${BACKUPDIR}/login.defs.1

  # 1.管理员root密码更改及失效策略设置
  echo .
  read -t ${VAR_VERIFY_TIMEOUT} -p "Please input, restart setting super account [${VAR_SUPER_USER}] password. (Y/N) : " VERIFY
  echo .
  if [[ ${VERIFY:="N"} == "Y" || ${VERIFY:="N"} == "y" ]]; then
    echo "正在重置 ${VAR_SUPER_USER} 用户密码."
    echo  "${VAR_SUPER_USER}:${VAR_SUPER_PASS}" | chpasswd
    # chage -d 0 -m 0 -M 90 -W 15 ${VAR_SUPER_USER} && passwd --expire ${VAR_SUPER_USER} 
  fi

  # 2.系统用户ubuntu密码更改及失效策略设置
  echo .
  read -t ${VAR_VERIFY_TIMEOUT} -p "Please input, restart setting normal account [${VAR_USER_NAME}] password. (Y/N) : " VERIFY
  echo .
  if [[ ${VERIFY:="N"} == "Y" || ${VERIFY:="N"} == "y" ]]; then
    echo "正在重置 ${VAR_USER_NAME} 用户密码."
    echo  "${VAR_USER_NAME}:${VAR_USER_PASS}" | chpasswd
    chage -d 0 -m 0 -M 90 -W 15 ${VAR_USER_NAME} && passwd --expire ${VAR_USER_NAME} 
  fi

  # 3.普通用户密码更改及失效策略设置
  echo .
  read -t ${VAR_VERIFY_TIMEOUT} -p "Please input, create ${VAR_APP_USER} account. (Y/N) : " VERIFY
  echo .
  if [[ ${VERIFY:="N"} == "Y" || ${VERIFY:="N"} == "y" ]]; then
    grep -q "${VAR_APP_USER}:" /etc/passwd
    if [ $? == 1 ];then 
      echo "正在创建 ${VAR_APP_USER} 用户与组."
      groupadd ${VAR_APP_USER} &&  useradd -m -s /bin/bash -c "Application low privilege users" -g ${VAR_APP_USER} ${VAR_APP_USER}
    else
      log::warning "don't create ${VAR_APP_USER} account, This is account already exist."
    fi
    echo "正在设置 ${VAR_APP_USER} 用户密码."
    echo "${VAR_APP_USER}:${VAR_APP_PASS}" | chpasswd
    chage -d 0 -m 0 -M 90 -W 15 ${VAR_APP_USER} && passwd --expire ${VAR_APP_USER}
  fi

    log::info "[-] 进行用户相关策略设置."

    # 启用成功登录的日志记录
    egrep -q "^\s*LOG_OK_LOGINS\s+\S*(\s*#.*)?\s*$" /etc/login.defs && sed -ri "s/^(\s*)LOG_OK_LOGINS\s+\S*(\s*#.*)?\s*$/LOG_OK_LOGINS ${VAR_LOG_OK_LOGINS}/" /etc/login.defs || echo "LOG_OK_LOGINS  ${VAR_LOG_OK_LOGINS}" >> /etc/login.defs

    # 禁止没有主目录的用户登录。
    egrep -q "^\s*DEFAULT_HOME\s+\S*(\s*#.*)?\s*$" /etc/login.defs && sed -ri "s/^(\s*)DEFAULT_HOME\s+\S*(\s*#.*)?\s*$/DEFAULT_HOME ${VAR_DEFAULT_HOME}/" /etc/login.defs || echo "DEFAULT_HOME  ${VAR_DEFAULT_HOME}" >> /etc/login.defs

    # 删除用户时禁止同步删除用户组
    egrep -q "^\s*USERGROUPS_ENAB\s+\S*(\s*#.*)?\s*$" /etc/login.defs && sed -ri "s/^(\s*)USERGROUPS_ENAB\s+\S*(\s*#.*)?\s*$/USERGROUPS_ENAB  ${VAR_USERGROUPS_ENAB}/" /etc/login.defs || echo "USERGROUPS_ENAB  ${VAR_USERGROUPS_ENAB}" >> /etc/login.defs

  log::success "[${COUNT}] This operation is completed!"
  sleep 1
  ((COUNT++))
}



# 函数名称: sec_passpolicy
# 函数用途: 用户密码复杂性策略设置 (密码过期周期0~90、到期前15天提示、密码长度至少12、复杂度设置至少有一个大小写、数字、特殊字符、密码三次不能一样、尝试次数为三次）
# 函数参数: 无
function sec_passpolicy () {
  log::info "[${COUNT}] System account password policy setting."
  log::info "[-] 用户密码复杂性策略设置."
  cp -a /etc/login.defs ${BACKUPDIR}/login.defs.2
  cp -a /etc/pam.d/common-password ${BACKUPDIR}

  egrep -q "^\s*PASS_MIN_DAYS\s+\S*(\s*#.*)?\s*$" /etc/login.defs && sed -ri "s/^(\s*)PASS_MIN_DAYS\s+\S*(\s*#.*)?\s*$/PASS_MIN_DAYS  ${PASS_MIN_DAYS}/" /etc/login.defs || echo "PASS_MIN_DAYS  ${PASS_MIN_DAYS}" >> /etc/login.defs

  egrep -q "^\s*PASS_MAX_DAYS\s+\S*(\s*#.*)?\s*$" /etc/login.defs && sed -ri "s/^(\s*)PASS_MAX_DAYS\s+\S*(\s*#.*)?\s*$/PASS_MAX_DAYS  ${PASS_MAX_DAYS}/" /etc/login.defs || echo "PASS_MAX_DAYS  ${{PASS_MAX_DAYS}}" >> /etc/login.defs

  egrep -q "^\s*PASS_WARN_AGE\s+\S*(\s*#.*)?\s*$" /etc/login.defs && sed -ri "s/^(\s*)PASS_WARN_AGE\s+\S*(\s*#.*)?\s*$/PASS_WARN_AGE  ${PASS_WARN_AGE}/" /etc/login.defs || echo "PASS_WARN_AGE  ${PASS_WARN_AGE}" >> /etc/login.defs

  egrep -q "^\s*PASS_MIN_LEN\s+\S*(\s*#.*)?\s*$" /etc/login.defs && sed -ri "s/^(\s*)PASS_MIN_LEN\s+\S*(\s*#.*)?\s*$/PASS_MIN_LEN ${PASS_MIN_LEN}/" /etc/login.defs || echo "PASS_MIN_LEN  ${PASS_MIN_LEN}" >> /etc/login.defs
  
  egrep -q "^\s*ENCRYPT_METHOD\s+\S*(\s*#.*)?\s*$" /etc/login.defs && sed -ri "s/^(\s*)ENCRYPT_METHOD\s+\S*(\s*#.*)?\s*$/ENCRYPT_METHOD ${VAR_PASS_ENCRYPT}/" /etc/login.defs || echo "ENCRYPT_METHOD  ${VAR_PASS_ENCRYPT}" >> /etc/login.defs

  egrep -q "^password\s.+pam_cracklib.so\s+\w+.*$" /etc/pam.d/common-password && sed -ri "/^password\s.+pam_cracklib.so/{s/pam_cracklib.so\s+\w+.*$/pam_cracklib.so retry=${VAR_PASS_RETRY} difok=${VAR_PASS_DIFOK} minlen=${PASS_MIN_LEN} minclass=${VAR_PASS_MINCLASS} ucredit=${VAR_PASS_UCREDIT} lcredit=${VAR_PASS_LCREDIT} dcredit=${VAR_PASS_DCREDIT} ocredit=${VAR_PASS_OCREDIT}/g;}" /etc/pam.d/common-password

  egrep -q "^password\s.+pam_unix.so\s+\w+.*$" /etc/pam.d/common-password && sed -ri "/^password\s.+pam_unix.so/{s/pam_unix.so\s+\w+.*$/pam_unix.so obscure use_authtok try_first_pass sha512 remember=${VAR_PASS_REMEMBER}/g;}" /etc/pam.d/common-password

  log::info "[-] 验证查看用户密码复杂性策略设置."
  if [[ ${VAR_VERIFY_RESULT} == "Y" ]];then 
    grep "^PASS_" /etc/login.defs
    egrep "pam_cracklib.so|pam_unix.so" /etc/pam.d/common-password
  fi

  log::success "[${COUNT}] This operation is completed!"
  sleep 1
  ((COUNT++))
}


# 函数名称: sec_sshdpolicy
# 函数用途: 系统sshd服务安全策略设置
# 函数参数: 无
function sec_sshdpolicy () {
  log::info "[${COUNT}] System sshd service security policy setting."
  log::info "[-] 系统sshd服务安全策略设置."
  cp -a /etc/ssh/sshd_config ${BACKUPDIR}

  # 1.禁止root远程登录（推荐配置-但还是要根据需求配置）
  egrep -q "^\s*PermitRootLogin\s+.+$" /etc/ssh/sshd_config && sed -ri "s/^\s*PermitRootLogin\s+.+$/PermitRootLogin no/" /etc/ssh/sshd_config || echo "PermitRootLogin no" >> /etc/ssh/sshd_config
  # 2.启用严格模式
  sudo egrep -q "^\s*StrictModes\s+.+$" /etc/ssh/sshd_config && sed -ri "s/^(#)?\s*StrictModes\s+.+$/StrictModes yes/" /etc/ssh/sshd_config || echo "StrictModes yes" >> /etc/ssh/sshd_config
  # 3.更改服务端口
  sudo egrep -q "^\s*Port\s+.+$" /etc/ssh/sshd_config && sed -ri "s/^(#)?\s*Port\s+.+$/Port ${VAR_SSHD_PORT}/" /etc/ssh/sshd_config || echo "Port ${VAR_SSHD_PORT}" >> /etc/ssh/sshd_config
  # 4.禁用X11转发及端口转发
  sudo egrep -q "^\s*X11Forwarding\s+.+$" /etc/ssh/sshd_config && sed -ri "s/^(#)?\s*X11Forwarding\s+.+$/X11Forwarding no/" /etc/ssh/sshd_config || echo "X11Forwarding no" >> /etc/ssh/sshd_config
  sudo egrep -q "^\s*X11UseLocalhost\s+.+$" /etc/ssh/sshd_config && sed -ri "s/^(#)?\s*X11UseLocalhost\s+.+$/X11UseLocalhost yes/" /etc/ssh/sshd_config || echo "X11UseLocalhost yes" >> /etc/ssh/sshd_config
  sudo egrep -q "^\s*AllowTcpForwarding\s+.+$" /etc/ssh/sshd_config && sed -ri "s/^(#)?\s*AllowTcpForwarding\s+.+$/AllowTcpForwarding no/" /etc/ssh/sshd_config || echo "AllowTcpForwarding no" >> /etc/ssh/sshd_config
  sudo egrep -q "^\s*AllowAgentForwarding\s+.+$" /etc/ssh/sshd_config && sed -ri "s/^(#)?\s*AllowAgentForwarding\s+.+$/AllowAgentForwarding no/" /etc/ssh/sshd_config || echo "AllowAgentForwarding no" >> /etc/ssh/sshd_config
  # 5.关闭禁用用户的 .rhosts 文件  ~/.ssh/.rhosts 来做为认证: 缺省 IgnoreRhosts yes 
  egrep -q "^(#)?\s*IgnoreRhosts\s+.+$" /etc/ssh/sshd_config && sed -ri "s/^(#)?\s*IgnoreRhosts\s+.+$/IgnoreRhosts yes/" /etc/ssh/sshd_config || echo "IgnoreRhosts yes" >> /etc/ssh/sshd_config

  log::success "[${COUNT}] This operation is completed!"
  sleep 1
  ((COUNT++))
}


# 函数名称: sec_loginpolicy
# 函数用途: 用户登陆安全策略设置
# 函数参数: 无
function sec_loginpolicy () {
  log::info "[${COUNT}] System user login security policy setting."
  log::info "[-] 用户登陆安全策略设置."

  # 1.判断发型版本，温馨最新的 22.04 使用的是 pam_faillock.so 模块了而非 pam_tally2.so 所以此处需要根据版本切换（坑呀）。
  log::info "[-] 用户远程连续登录失败10次锁定帐号5分钟包括root账号"
  release=$(lsb_release -c -s)
  if [ ${release} == "jammy" ];then
    # if [ ! -f /var/run/faillock ];then mkdir -vp /var/run/faillock;fi
    cp -a /etc/pam.d/common-auth ${BACKUPDIR}
    sed -ri "/^\s*auth\s.+pam_faillock.so\s+.+(\s*#.*)?\s*$/d" /etc/pam.d/common-auth
    sed -ri "/pam_unix.so nullok$/a # User Login failed lock policy.\nauth [default=die] pam_faillock.so authfail silent audit dir=/var/run/faillock fail_interval=${VAR_LOGIN_FAIL_INTERVAL} deny=${VAR_LOGIN_FAIL_COUNT} unlock_time=${VAR_LOGIN_LOCK_TIME} even_deny_root root_unlock_time=${VAR_LOGIN_LOCK_TIME}\nauth sufficient pam_faillock.so authsucc" /etc/pam.d/common-auth
  elif [ ${release} == "focal" ] ||  [ ${release} == "bionic" ] ;then
    cp -a /etc/pam.d/login ${BACKUPDIR}
    cp -a /etc/pam.d/sshd ${BACKUPDIR}
    sed -ri "/^\s*auth\s+required\s+pam_tally2.so\s+.+(\s*#.*)?\s*$/d" /etc/pam.d/sshd 
    sed -ri "2a auth required pam_tally2.so deny=${VAR_LOGIN_FAIL_COUNT} unlock_time=${VAR_LOGIN_LOCK_TIME} even_deny_root root_unlock_time=${VAR_LOGIN_LOCK_TIME}" /etc/pam.d/sshd 
    # 宿主机控制台登陆也受到限制(可选)
    # sed -ri "/^\s*auth\s+required\s+pam_tally2.so\s+.+(\s*#.*)?\s*$/d" /etc/pam.d/login
    # sed -ri "2a auth required pam_tally2.so deny=5 unlock_time=300 even_deny_root root_unlock_time=300" /etc/pam.d/login
  fi

  # 2.终端登陆超时时间设置
  log::info "[-] 设置登录超时时间为${VAR_LOGIN_TIMEOUT}分钟 "
  egrep -q "^\s*(export|)\s*TMOUT\S\w+.*$" /etc/profile && sed -ri "s/^\s*(export|)\s*TMOUT.\S\w+.*$/export TMOUT=${VAR_LOGIN_TIMEOUT}\nreadonly TMOUT/" /etc/profile || echo -e "export TMOUT=${VAR_LOGIN_TIMEOUT}\nreadonly TMOUT" >> /etc/profile
  egrep -q "^\s*.*ClientAliveInterval\s\w+.*$" /etc/ssh/sshd_config && sed -ri "s/^\s*.*ClientAliveInterval\s\w+.*$/ClientAliveInterval ${VAR_LOGIN_TIMEOUT}/" /etc/ssh/sshd_config || echo "ClientAliveInterval ${VAR_LOGIN_TIMEOUT}" >> /etc/ssh/sshd_config

  log::success "[${COUNT}] This operation is completed!"
  sleep 1
  ((COUNT++))
}


# 函数名称: sec_historypolicy
# 函数用途: 用户终端执行的历史命令记录安全策略设置
# 函数参数: 无
function sec_historypolicy () {
  log::info "[${COUNT}] System user shell command record security policy setting."
  # 1.历史命令条数限制以及历史命令输出文件
  log::info "[-] 用户终端执行的历史命令记录."
  egrep -q "^HISTSIZE\W\w+.*$" /etc/profile && sed -ri "s/^HISTSIZE\W\w+.*$/HISTSIZE=${VAR_HISTSIZE}/" /etc/profile || echo "HISTSIZE=${VAR_HISTSIZE}" >> /etc/profile
  sudo tee /etc/profile.d/history-record.sh <<'EOF'
# 历史命令执行记录文件路径.
LOGTIME=$(date +%Y%m%d-%H-%M-%S)
export HISTFILE="/var/log/.history/${USER}.${LOGTIME}.history"
if [ ! -f ${HISTFILE} ];then
  touch ${HISTFILE}
fi
chmod 600 ${HISTFILE}
# 历史命令执行文件大小记录设置.
HISTFILESIZE=128
HISTTIMEFORMAT="%F_%T $(whoami)#$(who -u am i 2>/dev/null| awk '{print $NF}'|sed -e 's/[()]//g'):"
EOF

  # 2.执行权限赋予与及时生效 
  chmod a+x /etc/profile.d/history-record.sh
  source /etc/profile.d/history-record.sh

  log::success "[${COUNT}] This operation is completed!"
  sleep 1
  ((COUNT++))
}


# 函数名称: sec_grubpolicy
# 函数用途: 系统 GRUB 安全设置防止物理接触从grub菜单中修改密码
# 函数参数: 无
function sec_grubpolicy() {
  log::info "[${COUNT}] System GRUB security policy setting."
  log::info "[-] 系统 GRUB 安全设置 (防止物理接触从grub菜单中修改密码), 缺省密码为 【WeiyiGeek】"
  # 1.GRUB 关键文件备份
  cp -a /etc/grub.d/00_header ${BACKUPDIR}
  cp -a /etc/grub.d/10_linux ${BACKUPDIR}
  # 2.设置GRUB菜单界面显示时间
  sed -i -e 's|GRUB_TIMEOUT_STYLE=hidden|#GRUB_TIMEOUT_STYLE=hidden|g' -e 's|GRUB_TIMEOUT=0|GRUB_TIMEOUT=3|g' /etc/default/grub
  sed -i -e 's|set timeout_style=${style}|#set timeout_style=${style}|g' -e 's|set timeout=${timeout}|set timeout=3|g' /etc/grub.d/00_header
  # 自行创建认证密码 (此处密码: WeiyiGeek)
  # sudo grub-mkpasswd-pbkdf2
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

  # 3.设置进入正式系统不需要认证如进入单用户模式进行重置账号密码时需要进行认证。 （高敏感数据库系统不建议下述操作）
  # 在191和193 分别加入--user=grub 和 --unrestricted
  # 191       echo "menuentry --user=grub '$(echo "$title" | grub_quote)' ${CLASS} \$menuentry_id_option 'gnulinux-$version-$type-$boot_device_id' {" | sed "s/^/$submenu_indentation/"  # 如果按e进行menu菜单则需要用grub进行认证
  # 192   else
  # 193       echo "menuentry --unrestricted '$(echo "$os" | grub_quote)' ${CLASS} \$menuentry_id_option 'gnulinux-simple-$boot_device_id' {" | sed "s/^/$submenu_indentation/"          # 正常进入系统则不认证
  sed -i '/echo "$title" | grub_quote/ { s/menuentry /menuentry --user=grub /;}' /etc/grub.d/10_linux
  sed -i '/echo "$os" | grub_quote/ { s/menuentry /menuentry --unrestricted /;}' /etc/grub.d/10_linux

  # 4.Ubuntu 方式更新GRUB从而生成boot启动文件。
  update-grub

  log::success "[${COUNT}] This operation is completed!"
  sleep 1
  ((COUNT++))
}


# 函数名称: sec_firewallpolicy
# 函数用途: 系统防火墙策略设置, 建议操作完成后重启计算机.
# 函数参数: 无
function sec_firewallpolicy() {
  log::info "[${COUNT}] System Firewall security policy setting."
  
  log::info "[-] 启用 ufw 系统防火墙"
  ufw status | grep -q "inactive"
  if [ $? == 0 ];then 
    systemctl start ufw.service
    echo -e "y\n" | ufw enable
    systemctl enable ufw.service
    systemctl mask ufw.servicee >/dev/null 2>&1
    ufw status verbose   
  fi

  log::info "[-]  防火墙策略设置"
  for port in ${VAR_ALLOW_PORT[@]};do 
    echo "ufw allow ${port}"
    ufw allow ${port}
  done

  log::info "[-]  防火墙服务及策略显示"
  systemctl status ufw.service --no-pager && ufw status verbose

  log::success "[${COUNT}] This operation is completed!"
  sleep 1
  ((COUNT++))
}


# 函数名称: sec_ctrlaltdel
# 函数用途: 禁用 ctrl+alt+del 组合键对系统重启 (必须要配置我曾入过坑)
# 函数参数: 无
function sec_ctrlaltdel() {
  log::info "[${COUNT}] Disable ctrl+alt+del key restart computer."
  log::info "[-] 禁用控制台 Ctrl+Alt+Del 组合键重启."
  
  if [ -f /usr/lib/systemd/system/ctrl-alt-del.target ];then
    systemctl stop ctrl-alt-del.target
    systemctl mask ctrl-alt-del.target >/dev/null 2>&1
    sed -i 's/^#CtrlAltDelBurstAction=.*/CtrlAltDelBurstAction=none/' /etc/systemd/system.conf
    mv /usr/lib/systemd/system/ctrl-alt-del.target ${BACKUPDIR}/ctrl-alt-del.target.bak
  fi

  log::success "[${COUNT}] This operation is completed!"
  sleep 1
  ((COUNT++))
} 

    
# 函数名称: sec_recyclebin
# 函数用途: 设置文件删除回收站别名(防止误删文件)(必须要配置,我曾入过坑)
# 函数参数: 无
function sec_recyclebin() {
  log::info "[${COUNT}] Enable file or dirctory delete recycle bin."
  log::info "[-] 设置文件删除回收站别名(防止误删文件)"

  # 1.防止rm -rf误操作为其设置别名
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
  # 定义秒时间戳
  STAMP=$(date +%s)
  # 得到文件名称(非文件夹)，参考man basename
  fileName=$(basename $i)
  # 将输入的参数，对应文件mv至.trash目录，文件后缀，为当前的时间戳
  mv $i ${TRASH_DIR}/${fileName}.${STAMP}
done
EOF

  # 2.执行权限赋予立即生效
  sudo chmod a+x /usr/local/bin/remove.sh /etc/profile.d/alias.sh
  source /etc/profile.d/alias.sh /etc/profile.d/history-record.sh

  log::success "[${COUNT}] This operation is completed!"
  sleep 1
  ((COUNT++))
}


# 函数名称: sec_supolicy
# 函数用途: 切换用户日志记录和切换命令更改名称为SU(可选)
# 函数参数: 无
function sec_supolicy() {
  log::info "[${COUNT}] Rename su command to SU command."

  log::info "[-] 将用户切换命令更改名称为 SU "
  # 1.su 命令切换记录
  if [ ! -f  ${SU_LOG_FILE} ];then touch ${SU_LOG_FILE};fi
  egrep -q "^(\s*)SULOG_FILE\s+\S*(\s*#.*)?\s*$" /etc/login.defs && sed -ri "s/^(\s*)SULOG_FILE\s+\S*(\s*#.*)?\s*$/\SULOG_FILE ${SU_LOG_FILE}" /etc/login.defs || echo "SULOG_FILE  ${SU_LOG_FILE}" >> /etc/login.defs
  # egrep -q "^\s*SU_NAME\s+\S*(\s*#.*)?\s*$" /etc/login.defs && sed -ri "s/^(\s*)SU_NAME\s+\S*(\s*#.*)?\s*$/\SU_NAME  SU/" /etc/login.defs || echo "SU_NAME SU" >> /etc/login.defs
  # mv /usr/bin/su /usr/bin/SU

  log::info "[-] 配置不允许指定组使用su切换 "
  egrep -q "^(\s*).+auth\s.+pam_wheel.so deny\s+\w+.*$" /etc/pam.d/su && sed -ri "/^(\s*).+auth\s.+pam_wheel.so deny/{s/^(\s*).+auth\s.+pam_wheel.so\s+\w+.*$/auth required pam_wheel.so deny group=app /g;}" /etc/pam.d/su


  log::success "[${COUNT}] This operation is completed!"
  sleep 1
  ((COUNT++))
}



# 函数名称: sec_privilegepolicy
# 函数用途: 系统用户sudo权限与文件目录创建权限策略设置
# 函数参数: 无
function sec_privilegepolicy() {
  log::info "[${COUNT}] System account password security policy setting."
  log::info "[-]系统用户sudo权限与文件目录创建权限策略设置."
  cp -a /etc/sudoers ${BACKUPDIR}

  log::info "[-] 配置用户 sudo 权限"
  # 如 ubuntu 安装时您创建的用户 WeiyiGeek 防止直接通过 sudo passwd 修改root密码 以及 sudo -i 登陆到 shell 终端
  gpasswd -d ${VAR_USER_NAME} sudo
  # sed -i "/# Members of the admin/i ${VAR_USER_NAME} ALL=(ALL) PASSWD:ALL" /etc/sudoers

  log::info "[-] 配置用户 umask 为 022"
  egrep -q "^\s*umask\s+\w+.*$" /etc/profile && sed -ri "s/^\s*umask\s+\w+.*$/umask ${VAR_UMASK}/" /etc/profile || echo "umask ${VAR_UMASK}" >> /etc/profile
  egrep -q "^\s*umask\s+\w+.*$" /etc/bash.bashrc && sed -ri "s/^\s*umask\s+\w+.*$/umask ${VAR_UMASK}/" /etc/bashrc || echo "umask ${VAR_UMASK}" >> /etc/bash.bashrc
  egrep -q "^\s*(umask|UMASK)\s+\w+.*$" /etc/login.defs && sed -ri "s/^\s*(umask|UMASK)\s+\w+.*$/UMASK ${VAR_UMASK}/" /etc/login.defs || echo "UMASK ${VAR_UMASK}" >> /etc/login.defs

  log::info "[-] 设置/恢复重要目录和文件的权限"
  touch /etc/security/opasswd && chown root:root /etc/security/opasswd && chmod 600 /etc/security/opasswd 
  find /home -name authorized_keys -exec chmod 600 {} \;
  chmod 600 ~/.ssh/authorized_keys
  chmod 0600 /etc/ssh/sshd_config
  chmod 644 /etc/group /etc/services
  chmod 700 /etc/inetd.conf&>/dev/null 2&>/dev/null; 
  chmod 755 /etc /etc/passwd /etc/shadow /etc/security /etc/rc*.d

  log::success "[${COUNT}] This operation is completed!"
  sleep 1
  ((COUNT++))
}