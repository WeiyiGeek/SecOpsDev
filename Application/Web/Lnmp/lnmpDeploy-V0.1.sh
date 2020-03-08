#!/bin/bash
# Description:LNMP一键安装
# Author: WeiyiGeek
# Site: WeiyiGeek.top
# Test_Linux: Linux weiyigeek 3.10.0-693.el7.x86_64 #1 SMP Tue Aug 22 21:09:27 UTC 2017 x86_64 x86_64 x86_64 GNU/Linux
# release:CentOS Linux release 7.4.1708 (Core)

## Define nginx variable
NGX_VER=1.17.9
NGX_URI="http://nginx.org/download/nginx-${NGX_VER}.tar.gz"
NGX_NAME="nginx-${NGX_VER}.tar.gz"
NGX_SRC=${NGX_NAME%.tar.gz}
NGX_DIR="/usr/local/nginx/${NGX_VER}"
NGX_ARGS="--user=nginx --group=nginx --with-http_stub_status_module"

## Define php-fpm variable
PHP_VER=7.4.3
PHP_SOFT="php-${PHP_VER}.tar.bz2"
PHP_URL="http://mirrors.sohu.com/php/${PHP_SOFT}"
PHP_SRC=${PHP_SOFT%.tar.bz2}
PHP_DIR="/usr/local/php/${PHP_VER}"

## Define Mysql-Boost variable
MYSQL_VER=5.7.29
MYSQL_NAME="mysql-boost-${MYSQL_VER}.tar.gz"
MYSQL_URL="http://mirrors.163.com/mysql/Downloads/MySQL-${MYSQL_VER%.*}/mysql-boost-${MYSQL_VER}"
MYSQL_SRC="${MYSQL_NAME%.tar.gz}"
MYSQL_DIR="/usr/local/mysql/${MYSQL_VER}"
MYSQL_DATADIR="/data/mysql/db"

## Define GCC Variable
GCC_VER=5.5.0
GCC_NAME="gcc-${GCC_VER}"
GCC_SRC="${GCC_VER}.tar.xz"
GCC_URL="http://ftp.tsukuba.wide.ad.jp/software/gcc/releases/${GCC_NAME}/gcc-5.5.0.tar.xz"


## [ 安装 nginx ]
function nginx_install(){
    echo -e "\e[32m 安装Nginx中..... \e[0m"

    CHECK_NUM=$(rpm -qa|grep -wcE "gcc|pcre-devel")
	if [ $CHECK_NUM -lt 2 ];then
		yum install -y wget -c gzip tar make gcc
		yum install -y pcre pcre-devel zlib zlib-devel
	fi

    CHECK_USER=$(getent passwd | grep -wc nginx)
    if [ $CHECK_USER -eq 0 ];then useradd -s /sbin/nologin nginx -M; fi

    if [ ! -f $NGX_NAME ];then
        wget -c $NGX_URI
    else
        echo -e "\e[31m#Messge: Nginx 已存在 无需下载 \e[0m"
    fi

    if [ ! -d $NGX_SRC ];then tar -zxf $NGX_NAME; fi
    if [ ! -d $NGX_DIR ];then mkdir -p $NGX_DIR; fi

	cd $NGX_SRC && ./configure --prefix=$NGX_DIR $NGX_ARGS 
    if [ $? -eq 0 ];then
		make && make install
    else
        echo -e "\e[31m#Error: 编译失败!终止安装 \e[0m"
        exit
	fi

    echo -e "\e[32m#Messge: Nginx安装成功正在进行防火墙设置 \e[0m"
    #fireall_set nginx

    echo -e "\e[32m#Messge: 正在启动 Nginx \e[0m"
    if [ ! -f /usr/bin/nginx ];then
        ln -s $NGX_DIR/sbin/nginx /usr/bin/nginx
    fi
    $NGX_DIR/sbin/nginx

    CHECK_STATUS=$(netstat -tlnp | grep -wc "nginx")
    if [ $CHECK_STATUS -ne 0 ];then
        echo -e "\e[32m#Nginx 启动成功.... \e[0m"
    else
        echo -e "\e[31m#Nginx 启动失败.... \e[0m"
    fi
}


## [ 安装 mysql ]
function mysql_install(){
    echo -e "\e[32m 安装Mysql及其yum 依赖安装中..... \e[0m"
    yum install -y gcc.x86_64 gcc-c++.x86_64 make perl autoconf openssl* ncurses ncurses-devel bison bison-devel xz -y 
	yum install -y automake zlib libxml2 libxml2-devel libgcrypt libtool bison
    # 验证系统中mariadb版本
    # CHECK_MARIADB=$(rpm -qa | grep -w mariadb)
    # if [ $CHECK_MARIADB != "" ];then
    #     rpm -e $CHECK_MARIADB
    # fi

    # MySQL 8.X 需要环境准备gcc 5.0 (还是推荐二进制的吧)
    if [ ! -f ${GCC_SRC} -a ${MYSQL_VER%.*.*} == "8" ];then
        #yum install -y cmake3 
        #wget -c $GCC_URL
        echo "8.x暂未验证"
        exit
    else
        echo "#当前 MySQL 版本 无需安装高版本的 cmake 以及 gcc"
        yum install -y cmake && cmake --version
    fi
    
    CHECK_USER=$(getent passwd | grep -wc mysql)
    if [ $CHECK_USER -eq 0 ];then
        useradd -s /sbin/nologin mysql -M
    else
        echo -e "MySQL用户已添加"
    fi

    if [ ! -f $MYSQL_NAME ];then
        wget -c $MYSQL_URL
    else
        echo -e "\e[32m#Messge: MySQL 已存在 无需下载 \e[0m"
    fi

    if [ ! -d $MYSQL_SRC ];then tar -zxf $MYSQL_NAME; fi
    if [ ! -d $MYSQL_DATADIR ];then
        mkdir -p $MYSQL_DATADIR
        mkdir -p /data/mysql/tmp/
        chown -R mysql.mysql /data
    fi

    if [ ! -f $MYSQL_DIR/bin/mysqld ];then
        mkdir -p $MYSQL_DIR
        cd $MYSQL_SRC && cmake . -DWITH_BOOST=./boost -DCMAKE_INSTALL_PREFIX=$MYSQL_DIR/ -DSYSCONFDIR=/etc/my.cnf -DSYSTEMD_PID_DIR=$MYSQL_DATADIR/ -DMYSQL_UNIX_ADDR=/tmp/mysql.sock -DMYSQL_DATADIR=$MYSQL_DATADIR/ -DMYSQL_USER=mysql -DMYSQL_TCP_PORT=3306 -DMYSQLX_TCP_PORT=33060 -DTMPDIR=$MYSQL_DATADIR/tmp/ -DWITH_XTRADB_STORAGE_ENGINE=1 -DWITH_INNOBASE_STORAGE_ENGINE=1 -DWITH_PARTITION_STORAGE_ENGINE=1 -DWITH_BLACKHOLE_STORAGE_ENGINE=1 -DWITH_MYISAM_STORAGE_ENGINE=1 -DWITH_JEMALLOC=1 -DMAX_INDEXES=64 -DDEFAULT_CHARSET=utf8 -DDEFAULT_COLLATION=utf8_general_ci

        if [ $? -eq 0 ];then
        #安装编译时候不建议使用 make -j 4 ，虽然安装快但是可能影响程序的完整性;
        make && make install
        ln -s $MYSQL_DIR/bin/* /usr/bin/
        else  
            echo -e "\e[31m#Error: 编译失败,终止安装.... \e[0m"
            exit
        fi
    fi

    if [ $? -eq 0 ];then
        echo -e "\e[32m#MySQL 安装成功 .....\e[0m"
        cp /etc/my.cnf /etc/my.cnf.bak
cat > /etc/my.cnf<<END
[mysqld]
datadir=/data/mysql/db/
socket=/tmp/mysql.sock
symbolic-links=0
default_authentication_plugin=mysql_native_password
character-set-server=utf8

[mysqld_safe]
log-error=/data/mysql/db/error.log
pid-file=/data/mysql/db/mysql.pid
END
        cd $MYSQL_DIR/
        cp support-files/mysql.server /etc/init.d/mysqld
        chmod +x /etc/init.d/mysqld
        chkconfig --add mysqld
        chkconfig --level 35 mysqld on
        service  mysqld stop
        sed -i "s#^basedir=#basedir=${MYSQL_DIR}#g" /etc/init.d/mysqld
        sed -i "s#^datadir=#datadir=${MYSQL_DATADIR}/#g" /etc/init.d/mysqld
        echo -e "\e[32m##MySQL初始化......\e[0m'"
        ./bin/mysqld --initialize --user=mysql --basedir=$MYSQL_DIR --datadir=$MYSQL_DATADIR
        # ./bin/mysqld_safe --defaults-file=/etc/my.cnf --basedir=/usr/local/mysql/5.7.29/ --user=mysql
        service mysqld start

        CHECK_STATUS=$(netstat -tlnp | grep -wc "mysqld")
        if [ $CHECK_STATUS -ne 0 ];then
            echo -e "\e[32m#MySQL 启动成功.... \e[0m"
            echo -e "\e[32m#sql> mysql -uroot -p'!/K+ak7*RAkR' --connect-expired-password <<EOF\e[0"
            echo -e "\e[32m#alter user user() identified by 'WeiyiGeek' \e[0"
            echo -e "\e[32m#EOF \e[0"
        else
            echo -e "\e[31m#MySQL 启动失败.... \e[0m"
        fi
    else   
        echo -e "\e[31m#Error:安装失败，请检查报错....\e[0m"
        exit
    fi

    echo -e "\e[32m#Messge: MySQL安装成功正在进行防火墙设置 \e[0m"
    #fireall_set mysql
    echo .
}

## [安装 php-fpm ]
function php_install(){
    echo -e "\e[32m#Message: 正在进行安装php环境..... \e[0m"
    if [ ! -f $PHP_SOFT ];then
        wget -c $PHP_URL
    else
       echo -e "\e[32m#Message: 源码文件已经存在无需重新下载 \e[0m"
    fi

    CHECK_USER=$(getent passwd | grep -wc "www")
    if [ $CHECK_USER -eq 0 ];then useradd -M -s/sbin/nologin www; fi

    echo -e "#PHP依赖安装"
    yum install libxml2 libxml2-devel gzip bzip2 sqlite-devel -y

    if [ ! -d $PHP_SRC ];then
        tar jxf $PHP_SOFT
        mkdir -p $PHP_DIR
        mkdir -p /etc/php/
    fi

    cd $PHP_SRC && ./configure --prefix=$PHP_DIR --with-config-file-path=$PHP_DIR/php-config --with-pdo-mysql=mysqlnd --enable-mysqlnd --enable-fpm

    if [ $? -eq 0 ];then
        echo -e "\e[32m#Message: PHP 编译成功正在执行make && make install 安装操作 \e[0m"
        make && make install
        ln -s $PHP_DIR/etc/* /etc/php/
    else
        echo -e "\e[31m#Error: 编译失败终止安装.... \e[0m"
        exit
    fi

    #配置 php-fpm 配置文件
    cp php.ini-development $PHP_DIR/php.ini
	cp $PHP_DIR/etc/php-fpm.conf.default $PHP_DIR/etc/php-fpm.conf
    cp $PHP_DIR/etc/php-fpm.d/www.conf.default $PHP_DIR/etc/php-fpm.d/www.conf

    #由于下面需要使用systemctl来启动为了不动启动配置文件所以进行设置
    sed -i 's#;error_log = log/php-fpm.log#error_log = /var/log/php-fpm.log' $PHP_DIR/etc/php-fpm.conf
    sed -i 's#;pid = run/php-fpm.pid#pid = /var/run/php-fpm.pid' $PHP_DIR/etc/php-fpm.conf
    sed -i 's#nobody#www#g' $PHP_DIR/etc/php-fpm.conf

    #方式1:配置/etc/init.d/进行启动
    cp sapi/fpm/init.d.php-fpm /etc/init.d/php-fpm
	chmod o+x /etc/init.d/php-fpm
    service php-fpm restart

    #方式2:配置systectl启动
    cp sapi/fpm/php-fpm.service /usr/lib/systemd/user/php-fpm.servic
    systemctl daemon-reload
    # systemctl start php-fpm
    # systemctl status php-fpm

    if [ ! -f /usr/bin/php-fpm ];then
        ln -s $PHP_DIR/sbin/php-fpm /usr/bin/php-fpm
    fi

    CHECK_STATUS=$(netstat -tlnp | grep -wc "php-fpm")
    if [ $CHECK_STATUS -eq 0 ];then
        echo -e "\e[32m#Message: 启动失败请请检查错误原因后重试.... \e[0m"
    else
         echo -e "\e[32m#Message: 启动成功.... \e[0m"
    fi
}


## [ LNMP 配置 ]
function lnmp_config(){
    echo -e "\e[32m#LNMP 测试配置....\e[0m"
    cp $NGX_DIR/conf/nginx.conf{,.bak}
cat > $NGX_DIR/conf/nginx.conf <<EOF
user nginx;
worker_processes  1;
error_log  logs/error.log;
#pid       logs/nginx.pid;
events {
    worker_connections  1024;
}
http {
    include       mime.types;
    default_type  application/octet-stream;
    #log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
    #                  '$status $body_bytes_sent "$http_referer" '
    #                  '"$http_user_agent" "$http_x_forwarded_for"';
    #access_log  logs/access.log  main;
    sendfile        on;
    #tcp_nopush     on;
    keepalive_timeout  65;
    #gzip  on;
    server {
        listen       9081;
        server_name  my.weiyigeek.top;
        charset utf-8;
        #access_log  logs/host.access.log  main;
        location / {
            root   html;
            index  index.html index.htm;
        }
        error_page  404              /404.html;

        # redirect server error pages to the static page /50x.html
        #
        error_page   500 502 503 504  /50x.html;
        location = /50x.html {
            root   html;
        }
        # Nginx 监控模块启用
        location / nginxStatus {
            stub_status;
        }
        # pass the PHP scripts to FastCGI server listening on 127.0.0.1:9000
        location / {
           root           html;
           fastcgi_pass   127.0.0.1:9000;
           fastcgi_index  index.php;
           fastcgi_param  SCRIPT_FILENAME  \$document_root\$fastcgi_script_name;
           include        fastcgi_params;
        }
        # deny access to .htaccess files, if Apache's document root
        # concurs with nginx's one
        location ~ /\.ht {
           deny  all;
        }
    }
}
EOF
    echo "<?php  phpinfo(); ?>" > $NGX_DIR/html/phpinfo.php
    echo "<?php  echo "Hello World! php" ?>" > $NGX_DIR/html/index.php
    $NGX_DIR/sbin/nginx -s reload
}


## [nginx 卸载]
function nginx_remove(){
    $NGX_DIR/sbin/nginx -s stop
    pkill nginx
    rm -rf /usr/local/nginx /usr/bin/nginx
}

## [mysql 卸载]
function mysql_remove(){
    service mysqld stop
    pkill mysql
    mv /data /root/`date +%F`"-$RANDOM"
    rm -rf /data
}

## [php-fpm 卸载]
function php_remove(){
    service php-fpm stop
    pkill php-fpm
    rm -rf $PHP_DIR
    rm -rf /var/log/php-fpm.log /var/run/php-fpm.pid
    rm -rf /usr/bin/php-fpm
}


## [防火墙设置]
function fireall_set(){
    echo -e "\e[32m # 防火墙设置中..... \e[0m"
    if [ $1 == "nginx" ];then
        firewall-cmd --add-port=80/tcp --permanent
        firewall-cmd --reload
	    iptables -A INPUT -m tcp -p tcp --dport 80 -j ACCEPT
    elif [$1 == "mysql"];then
        firewall-cmd --add-port=3306/tcp --permanent
        firewall-cmd --reload
	    iptables -A INPUT -m tcp -p tcp --dport 3306 -j ACCEPT
    elif [ $1 == "php-fpm" ];then
        firewall-cmd --permanent --add-rich-rule="rule family="ipv4" source address="127.0.0.1" port protocol="tcp" port="9000" accept"
    fi
}



## [使用说明]
function usage() {
    clear
    echo -e "\e[32m #############LNMP INSTALL && REMOVE##########\e[0m"
    echo -e "\e[32m Description: Linux + Nginx ($NGX_VER) + MySQL($MYSQL_VER) + PHP ($PHP_VER) 一键安装和删除 \e[0m"
    echo -e "\e[32m Usage: $0 [install|remove] [nginx|mysql|php|config|lnmp]  \e[0m"
    echo -e "\e[32m Param: config 配置前面安装的LNMP环境\e[0m"
    echo -e "\e[32m Param: lnmp 一键安装LNMP 默认最后安装MySQL 由于8.0需要依赖高版本的cmake3和gcc5.x安装 \e[0m"
    echo -e "\e[32m 注意事项1: 需要保证 80 3306 9000等端口未占用\e[0m"
    echo -e "\e[32m 注意事项2: 如果需要安装 Mysql 8.0 建议最后进行安装 \e[0m"
}


## [安装判断]
function install_jduge(){
    if [ $1 == "nginx" ];then
        nginx_install
    elif [ $1 == "mysql" ];then
        mysql_install
    elif [ $1 == "php" ];then
        php_install
    elif [ $1 == "config" ];then
        lnmp_config
    else
        usage
    fi
}

## [卸载判断]
function remove_jduge(){
    if [ $1 == "nginx" ];then
        nginx_remove
    elif [ $1 == "mysql" ];then
        mysql_remove
    elif [ $1 == "php" ];then
        php_remove
    else
        usage
    fi
}

if [ $# -lt 2 ];then
    usage
    exit
fi

case $1 in
    install)
    install_jduge $2
    ;;
    remove)
    remove_jduge $2
    ;;
    *)
    usage
    ;;
esac

