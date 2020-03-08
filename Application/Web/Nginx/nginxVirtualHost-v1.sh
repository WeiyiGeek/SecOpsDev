#!/bin/bash
#@Desc:Nginx多实例部署虚拟主机
#@Author:WeiyiGeek
#@CreatTime:2020年3月8日 12点06分
#@Site:WeiyiGeek.top
#@Test_Linux: Linux weiyigeek 3.10.0-693.el7.x86_64 #1 SMP Tue Aug 22 21:09:27 UTC 2017 x86_64 x86_64 x86_64 GNU/Linux
#@release:CentOS Linux release 7.4.1708 (Core)

## Define nginx variable
NGX_VER=1.16.1
NGX_URI="http://nginx.org/download/nginx-${NGX_VER}.tar.gz"
NGX_SRC="nginx-${NGX_VER}.tar.gz"
NGX_NAME=${NGX_SRC%.tar.gz}
NGX_DIR="/usr/local/nginx/${NGX_VER}"
NGX_ARGS="--prefix=${NGX_DIR} --user=nginx --group=nginx --with-http_stub_status_module"
NGX_SRCCODE="${NGX_NAME}/src/core/nginx.h"
NGX_VHDIR="${NGX_DIR}/conf/domains"

## Define 防火墙开放端口
FIREWALL_PORT=(80 8080)

## [Firewall CONFIG]
function firewall_config(){
    echo -e "\e[32m5.Firewalld防火墙设置....... \e[0m"
    firewall-cmd --list-all
    if [ $? -eq 0 ];then
        for i in ${FIREWALL_PORT[@]}
        do
            firewall-cmd --add-port=${i}/tcp --permanent
            # iptables -t filter -A INPUT -m tcp -p tcp --dport 80 -j ACCEPT
        done
        firewall-cmd --reload
        firewall-cmd --list-all
    else
        echo -e "\e[33m#Msg: 防火墙未开启不用进行设置........ \e[0m";
    fi
}


## [Nginx INSTALL]
function nginx_install(){
    echo -e "\e[32m1.核查安装依赖....... \e[0m"
    CHECK_SOFT=$(rpm -qa | grep -cE "^gcc|^pcre|^zlib")
    if [ $CHECK_SOFT -lt 2 ];then yum install -y gcc gcc-c++ pcre pcre-devel zlib-devel;fi

    echo -e "\e[32m2.检查nginx源码包是否存在....... \e[0m"
    if [ ! -f $NGX_SRC ];then wget -c $NGX_URI;fi
    if [ ! -d $NGX_NAME ];then tar -zxf $NGX_SRC;fi

    echo -e "\e[32m3.nginx安装陆军是否存在....... \e[0m"
    if [ ! -f $NGX_DIR/sbin/nginx ];then mkdir -vp $NGX_DIR;fi

    echo -e "\e[32m3.验证nginx用户是否存在不存在则建立低权限用户....... \e[0m"
    CHECK_USER=$(getent passwd | grep -wc nginx)
    if [ $CHECK_USER -eq 0 ];then useradd -s /sbin/nologin nginx -M; fi

    echo -e "安全设置:Nginx版本隐藏......"
    sed -i "s/$NGX_VER//g" $NGX_SRCCODE
    sed -i 's/nginx\//JWS/g' $NGX_SRCCODE
    sed -i 's/"NGINX"/"JWS"/g' $NGX_SRCCODE

    echo -e "\e[32m4.进行nginx预编译及其编译安装....... \e[0m"
    cd $NGX_NAME && ./configure $NGX_ARGS 
    if [ $? -eq 0 ];then
        #进行四个线程并行编译
        make -j2 && make -j2 install
    else
        echo -e "\e[31m#Error: 预编译失败!终止安装,请检查软件依赖! \e[0m"
        exit
    fi
    if [ $? -ne 0 ];then echo -e "\e[31m#Error: 编译安装失败!终止安装 \e[0m";exit;fi
    echo -e "\e[32m Nginx 成功安装....... \n安装目录:${NGX_DIR} \n 正在启动Nginx....\e[0m"
    $NGX_DIR/sbin/nginx
}

## [Nginx CONFIG]
function nginx_vhost(){
    NGX_VHOSTS=$1
    firewall_config
    cd ${NGX_DIR}
    NGX_CNF="${NGX_DIR}/conf/nginx.conf"
    if [ ! -f $NGX_CONF ];then echo -e "Nginx-配置文件不存在请仔细检查!";exit;fi
    #判断是否已经存在domains配置文件是则不同重新建立;
    grep "domains" ${NGX_CNF} >>/dev/null 2>&1
    if [ $? -ne 0 ];then
        #备份NGX配置文件
        cp ${NGX_CNF}{,_$(date +%F_%H%M%S).bak}
    	mkdir -vp ${NGX_VHDIR}
        sed -i "s/#user  nobody/user  nginx/g" ${NGX_CNF}
        sed -i "s/#gzip/gzip/g" ${NGX_CNF}
        #去除空行以及注释
	    grep -vE "#|^$" ${NGX_CNF} > ${NGX_CNF}.swp
        #重点删除server字符到文件末尾
	    sed -i '/server/,$d' ${NGX_CNF}.swp
        cp ${NGX_CNF}.swp ${NGX_CNF}
        #重点(值得学习)
	    echo -e "    include domains/*;\n}" >> ${NGX_CNF}
    fi
    
cat>${NGX_VHDIR}/$NGX_VHOSTS.conf<<EOF
server {
    listen       80;
    server_name  $NGX_VHOSTS;

    location / {
        root   html/$NGX_VHOSTS;
        index  index.html index.htm;
    }
    #Nginx 监控模块启用
    location /nginxStatus {
        stub_status;
    }
    error_page   500 502 503 504  /50x.html;
    location = /50x.html {
        root   html;
    }
}
EOF
   

echo -e "\e[32m$NGX_VHOSTS 网站目录建立之中.....\e[0m"
if [ ! -d $NGX_DIR/html/$NGX_VHOSTS/ ];then
    mkdir -vp $NGX_DIR/html/$NGX_VHOSTS/
cat>$NGX_DIR/html/$NGX_VHOSTS/index.html<<EOF
<h1>$NGX_VHOSTS Test Pages. </h1>
<p>By WeiyiGeek.top </p>
<hr color=red>
EOF
fi
    echo -e "\e[32mNginx配置文件验证中.....\e[0m"
    $NGX_DIR/sbin/nginx -t
    if [ $? -ne 0 ];then
        echo -e "\e[31mNginx配置文件有误，请处理错误后重启Nginx服务器：\n ${NGX_DIR}/sbin/nginx -s reload"
    fi
    cat ${NGX_VHDIR}/$NGX_VHOSTS.conf

    echo -e "\e[32mNginx重启之中.....\e[0m"
    $NGX_DIR/sbin/nginx -s reload
    CHECK_STATUS=$(netstat -tlnp | grep -wc "nginx")
    if [ $CHECK_STATUS -ne 0 ];then
        echo -e "\e[32m#Nginx 启动成功.... \e[0m"
    else
        echo -e "\e[31m#Nginx 启动失败.... \e[0m"
    fi
}


## [Nginx Usage]
function Usage(){
    echo -e "\e[32m#@Desc:Nginx多实例部署虚拟主机 \n#@Author:WeiyiGeek \e[0m"
    echo -e "\e[32mUsage:${0} install [v1.weiyigeek.top]  #安装并部署\e[0m"
    echo -e "\e[32mUsage:${0} deploy [v2.weiyigeek.top]   #部署虚拟网站\e[0m"
    exit
}


## [安装验证]
function install_verity() {
    NGX_VHOSTS=$1
    #验证Nginx是否已经安装和
    if [ ! -f ${NGX_DIR}/sbin/nginx ];then
        nginx_install
    else
        echo -e "\e[31m该Nginx - ${NGX_VER}已经安装过无需重新安装......\e[0m" 
    fi

    #验证安装部署的网站是否已经存在
    if [ -f ${NGX_VHDIR}/$NGX_VHOSTS.conf ];then
        echo -e "\e[31m该 $NGX_VHOSTS 虚拟网站已经存在无需进行配置部署......\e[0m"
        exit
    fi
    #判断虚拟主机变量是否为空
    if [ -n $NGX_VHOSTS ];then
        echo -e "\e[32m建立的虚拟主机名称为 $NGX_VHOSTS"
        nginx_vhost $NGX_VHOSTS
    else
        echo -e "\e[31m已安装Nginx,但是并未设置虚拟主机......\e[0m"
    fi
}

## [部署验证]
function deploy_verity(){
    NGX_VHOSTS=$1
    #验证Nginx是否已经安装和
    if [ ! -f ${NGX_DIR}/sbin/nginx ];then
        echo -e "\e[31m部署初始化由于Nginx-${NGX_VER}未安装正在安装......\e[0m"
        nginx_install
    fi

    if [ -f ${NGX_VHDIR}/$NGX_VHOSTS.conf ];then
        echo -e "\e[31m该 $NGX_VHOSTS 虚拟网站已经存在无需进行安装部署......\e[0m"
        exit
    fi
    #判断虚拟主机变量是否为空
    if [ -n $NGX_VHOSTS ];then
        echo -e "\e[32m建立的虚拟主机名称为 $NGX_VHOSTS"
        nginx_vhost $NGX_VHOSTS
    else
        echo -e"\e[31m该 $NGX_VHOSTS 虚拟网站名称有误......\e[0m"
        Usage
    fi
}

## [Shell程序入口]
if [ $# -lt 2 ];then
    Usage
fi
case $1 in
    install)
     install_verity $2
    ;;
    deploy)
     deploy_verity $2
    ;;
    *)
    Usage
    ;;
esac