#!/bin/bash
# Description: CentOS7 Oracle 自动部署
# Author:WeiyiGeek
# CentOS Linux release 7.7.1908 (Core) 3.10.0-1062.el7.x86_64

HOST_NAME=WeiyiGeek-Oracle
HOST_IP=192.168.1.1
ORACLE_PASSWORD=WeiyiGeek-Database


# [关闭安全措施]
function close_Selinux(){
  sed -i.bak '/SELINUX/s/enforcing/disabled/' /etc/sysconfig/selinux   
  setenforce 0
}

# [软件镜像源设置以及下载需要到的工具]
function mirrors_Soft(){
  curl -o /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo
  yum clean all && yum makecache
  yum update -y && yum upgrade -y
  # [ 基础工具安装 ]
  yum install -y nano vim net-tools tree wget dos2unix unzip ntpdate
  # [ 依赖安装 ]
  yum -y install autoconf \
automake \
binutils \
binutils-devel \
bison  \
cpp \
gcc \
gcc-c++ \
lrzsz \
python-devel \
compat-db*  \
compat-gcc-34 \
compat-gcc-34-c++ \
compat-libcap1 \
compat-libstdc++-33 \
compat-libstdc++-33.i686 \
glibc-* \
glibc-*.i686 \
glibc \
glibc-common \
glibc-devel \
glibc-headers \
libXpm-*.i686\
libXp.so.6 \
libXt.so.6 \
libXtst.so.6 \
libXext \
libXext.i686 \
libXtst \
libXtst.i686 \
libX11 \
libX11.i686 \
libXau \
libXau.i686 \
libxcb \
libxcb.i686 \
libXi \
libXi.i686 \
libXtst \
libstdc++-docs \
libgcc_s.so.1 \
libstdc++.i686 \
libstdc++-devel \
libstdc++-devel.i686 \
libaio \
libaio.i686 \
libaio-devel \
libaio-devel.i686 \
ksh \
libXp \
libaio-devel \
numactl \
numactl-devel \
make \
sysstat \
unixODBC  \
unixODBC-devel \
elfutils-libelf-devel-0.97 \
elfutils-libelf-devel \
elfutils-libelf \
elfutils-libelf-devel \
libgcc \
expat 

# [检查依赖是否安装完整]

CHECK_SOFT=$(rpm -q \
binutils \
compat-libstdc++-33 \
elfutils-libelf \
elfutils-libelf-devel \
expat \
gcc \
gcc-c++ \
glibc \
glibc-common \
glibc-devel \
glibc-headers \
libaio \
libaio-devel \
libgcc \
libstdc++ \
libstdc++-devel \
make \
pdksh \
sysstat \
unixODBC \
unixODBC-devel | grep -c "not installed")
if [ $CHECK_SOFT -ne 0 ];then
  echo -e "\e[31m#基础依赖包未安装完整请检查.....\e[0m"
  exit
else
  echo -e "\e[32m#Env Pass\e[0m"
fi

}


function baseSetting(){
  # [ 系统hosts绑定 ]
  hostnamectl set-hostname $HOST_NAME  #在/etc/hosts文件中将hostname与回环IP地址对应上就解决了。
  CHECK_INSERT=$(grep -c "$HOST_IP" /etc/hosts)
  if [ $CHECK_INSERT -eq 0 ];then
    echo "${HOST_IP} $HOST_NAME" >> /etc/hosts
  fi

  # [系统语言与java环境设置]
  CHECK_INSERT=$(grep -c "LANG=en_US.UTF8" ~/.bash_profile)
  if [ $CHECK_INSERT -eq 0 ];then
    echo "export LANG=en_US.UTF8" >> ~/.bash_profile
    source ~/.bash_profile
  fi

  if [ ! -d /usr/local/jdk1.8.0_211/ ];then
    tar -zxf jdk-8u211-linux-x64.tar.gz -C /usr/local/
  fi

  CHECK_ENV=$(grep -c "JAVA_HOME" /etc/profile)
  export JAVA_HOME=/usr/local/jdk1.8.0_211
  if [ $CHECK_ENV -gt 1 ];then
cat >> /etc/profile <<END
export JAVA_HOME=/usr/local/jdk1.8.0_211
export CLASSPATH=.:\$JAVA_HOME/lib/dt.jar:\$JAVA_HOME/lib/tools.jar;
export PATH=\$PATH:\$JAVA_HOME/bin

if [ \$USER = "oracle" ]  || [ \$USER = "grid" ] ; then
    if [ \$SHELL = "/bin/ksh" ]; then
          ulimit -p 16384
          ulimit -n 65536
    else
          ulimit -u 16384 -n 65536
    fi
  umask 022
fi
END
  fi
  source /etc/profile
  java -version
  if [ $? -ne 0 ];then
    echo -e "\e[31m#Java环境未安装成功请检查....\e[0m"
    exit
  else  
    echo -e "\e[32m#Java环境安装成功....\e[0m"
  fi


  # [建立oracle应用账号与组]
  CHECK_USER=$(getent passwd | grep -Ec "^oracle")
  if [ $CHECK_USER -eq 0 ];then
    /usr/sbin/groupadd -g 60001 oinstall
    /usr/sbin/groupadd -g 60002 dba
    /usr/sbin/groupadd -g 60003 oper
    /usr/sbin/groupadd -g 60004 backupdba
    /usr/sbin/groupadd -g 60005 dgdba
    /usr/sbin/groupadd -g 60006 kmdba
    /usr/sbin/useradd -u 61002 -g oinstall -G dba,backupdba,dgdba,kmdba,oper oracle  #oracle用户
  fi

  CHECK_PASSWORD=$(getent shadow | grep -E "^oracle"|awk -F ':' '{print $2}'|wc -c)
  if [ $CHECK_PASSWORD -eq 3 ];then
    echo -e "\e[32m#正在设置oracle用户密码.....\e[0m"
    echo $ORACLE_PASSWORD | passwd --stdin oracle
  elif [ $CHECK_PASSWORD -gt 3 ];then
    echo -e "\e[32m#oracle用户密码已设置.....\e[0m"
  else
    echo -e "\e[31m#不存在oracle用户请检查....\e[0m"
    exit
  fi
}

# [ Oracle 数据库基础环境安装 ]
function Oracle_Setting(){
  wget http://public-yum.oracle.com/public-yum-ol7.repo -O /etc/yum.repos.d/public-yum-ol7.repo
  wget http://public-yum.oracle.com/RPM-GPG-KEY-oracle-ol7 -O /etc/pki/rpm-gpg/RPM-GPG-KEY-oracle
  CHECK_RPMORACLE=$(rpm -qa | grep -c "oracle-rdbms-server-11gR2-preinstall")
  if [ $CHECK_RPMORACLE -eq 0 ];then
    yum install oracle-rdbms-server-11gR2-preinstall -y
  else
    echo echo -e "\e[32m#oracle-rdbms-server-11gR2-preinstall已安装.....\e[0m"
  fi

  #[oracle安装的目录&授权]
  if [ ! -d /app/oracle/product/11.2.0.1/db1 ];then
    mkdir -p /app/oracle/product/11.2.0.1/db1 /var/oracle
    mkdir -p /app/oracle/{oraInventor,oradata,tmp,recovery_data}
    chown -R oracle:oinstall /var/oracle /app/oracle/
    chmod -R 755 /var/oracle /app/oracle/
    chmod a+wr /app/oracle/tmp
  fi

  #[配置oracle系统配置文件&授权]
  cat >> /etc/oraInst.loc <<EOF
inventory_loc=/app/oracle/oraInventor
inst_group=oinstall
EOF
chown oracle:oinstall /etc/oraInst.loc && chmod 664 /etc/oraInst.loc

  cat /etc/security/limits.conf
  CHECK_PAM=$(grep -c 'pam_limits.so' /etc/pam.d/login)
  if [ $CHECK_PAM -eq 0 ];then
    echo "session required pam_limits.so" >> /etc/pam.d/login
    echo "session required /lib64/security/pam_limits.so" >> /etc/pam.d/login
  else
    cat /etc/pam.d/login
  fi
  sysctl -p

  #查看内核配置文件是否存在和grup配置
  cat /sys/kernel/mm/transparent_hugepage/defrag
  cat /sys/kernel/mm/transparent_hugepage/enabled

  CHECK_GRUB=$(grep -c "numa=off" /etc/default/grub)
  if [ $CHECK_GRUB -eq 0 ];then
    sed -i 's#quiet"#quiet" numa=off#g' /etc/default/grub
  else
    echo -e "\e[32#Gurb 已修改 ....."
  fi
}


##### [在Oracle用户中进行运行]
function oracle_Install(){
  echo -e "\e[32m#恭喜您安装完成....请继续在Oracle用户中进行环境配置"
su - oracle

export LANG=en_US
export TMP=/app/oracle/tmp
export TMPDIR=$TMP

CHECK_PROFILE=$(grep -c "SETUP-ORACLE-ENVIRONMENT" ~/.bash_profile)
if [ $CHECK_PROFILE -eq  0 ];then
cat >> ~/.bash_profile << END
# +--------------------------+
# | SETUP-ORACLE-ENVIRONMENT |
# +--------------------------+
umask 022
export LANG=en_US
export TMP=/app/oracle/tmp
export TMPDIR=\$TMP
ORACLE_HOSTNAME=WeiyiGeek-oracle
ORACLE_BASE=/app/oracle
ORACLE_HOME=\$ORACLE_BASE/product/11.2.0.1/db1
ORACLE_SID=orcl
ORACLE_TERM=xterm;
PATH=.:\$PATH:\$HOME/.local/bin:\$HOME/bin:\$ORACLE_HOME/bin
NLS_DATE_FORMAT="yyyy-mm-dd HH24:MI:SS"
NLS_LANG=AMERICAN_AMERICA.AL32UTF8
export ORACLE_HOSTNAME ORACLE_BASE ORACLE_HOME ORACLE_SID ORACLE_TERM PATH NLS_DATE_FORMAT NLS_LANG
END
else
  echo -e "\e[31m#bash_profile已经配置无需重复配置.....\e[0m"
fi
source .bash_profile
source /etc/profile

  chown -R oracle:oinstall /home/oracle/
  chown -R oracle:oinstall /app/oracle/

  # [解压oracle安装程序到自定目录]
  if [ ! -f /home/oracle/database/response/db_install.rsp ];then
    unzip linux.x64_11gR2_database_1of2.zip -q -d /home/oracle/
    unzip linux.x64_11gR2_database_2of2.zip -q -d /home/oracle/
  fi

  # [ 配置db_install.rsp ]
  cp -r /home/oracle/database/response/ /home/oracle
  cat /home/oracle/response/db_install.rsp | grep -E -v "^#" | tr -s '\n' > /home/oracle/db_install.rsp
  sed -i '/oracle.install.option=/s/=/=INSTALL_DB_AND_CONFIG/'  /home/oracle/db_install.rsp  
  sed -i "/ORACLE_HOSTNAME=/s/=/=WeiyiGeek-oracle/"  /home/oracle/db_install.rsp
  sed -i "/UNIX_GROUP_NAME=/s/=/=oinstall/"  /home/oracle/db_install.rsp
  sed -i "/INVENTORY_LOCATION=/s/=/=\/app\/oracle\/oraInventor/"  /home/oracle/db_install.rsp
  sed -i "/SELECTED_LANGUAGES=/s/=/=zh_CN,en/"  /home/oracle/db_install.rsp
  sed -i "/ORACLE_HOME=/s/=/=\/app\/oracle\/product\/11.2.0.1\/db1/"  /home/oracle/db_install.rsp
  sed -i '/ORACLE_BASE=/s/=/=\/app\/oracle\/product/' /home/oracle/db_install.rsp
  sed -i '/InstallEdition=/s/=/=EE/' /home/oracle/db_install.rsp
  sed -i '/isCustomInstall=/s/=false/=true/' /home/oracle/db_install.rsp
  sed -i '/DBA_GROUP=/s/=/=dba/' /home/oracle/db_install.rsp
  sed -i '/OPER_GROUP=/s/=/=oinstall/' /home/oracle/db_install.rsp
  sed -i '/starterdb.type=/s/=/=GENERAL_PURPOSE/' /home/oracle/db_install.rsp
  sed -i '/starterdb.globalDBName=/s/=/=orcl.db1/' /home/oracle/db_install.rsp
  sed -i '/starterdb.SID=/s/=/=orcl/' /home/oracle/db_install.rsp
  sed -i '/starterdb.memoryLimit=/s/=/=2024/' /home/oracle/db_install.rsp
  sed -i '/starterdb.installExampleSchemas=/s/=false/=true/' /home/oracle/db_install.rsp
  sed -i '/starterdb.password.ALL=/s/=/=Oracl_2020#WeiyiGeek/' /home/oracle/db_install.rsp
  sed -i '/starterdb.storageType=/s/=/=FILE_SYSTEM_STORAGE/' /home/oracle/db_install.rsp
  sed -i '/starterdb.fileSystemStorage.dataLocation=/s/=/=\/app\/oracle\/oradata/' /home/oracle/db_install.rsp
  sed -i '/DECLINE_SECURITY_UPDATES=/s/=/=true/' /home/oracle/db_install.rsp

  # [ Intall 数据库 ]
  /home/oracle/database/runInstaller -silent -ignorePrereq  -responseFile /home/oracle/db_install.rsp
  
  # [新窗口root运行否则会卡在Thread]
  /app/oracle/product/11.2.0.1/db1/root.sh
  
  #自启动设置
  CHECK_AUTSTART=$(grep -c "/app/oracle" /etc/oratab)
  if [ $CHECK_AUTSTART -eq 0 ];then
    echo "orcl:/app/oracle/product/11.2.0.1/db1:Y" >> /etc/oratab
  else
    echo "已配置......"
  fi

  CHECK_AUTSTART=$(grep -c "ORACLE_HOME_LISTNER=\$ORACLE_HOME" /app/oracle/product/11.2.0.1/db1/bin/dbstart)
  if [ $CHECK_AUTSTART -eq 0 ];then
    sed -i "s#ORACLE_HOME_LISTNER=\$1#ORACLE_HOME_LISTNER=\$ORACLE_HOME#g" /app/oracle/product/11.2.0.1/db1/bin/dbstart
    cat >> /etc/rc.d/rc.local <<END
su oracle -lc "/app/oracle/product/11.2.0.1/db1/bin/lsnrctl start"
su oracle -lc /app/oracle/product/11.2.0.1/db1/bin/dbstart
END
  fi
  chmod +x /etc/rc.d/rc.local
}