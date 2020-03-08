#!/bin/bash
#Author: WeiyiGeek
#Descript: Tomcat一键部署安装运行(单实例)
#CreateTime: 2020年2月28日 16点50分
#WebSite: WeiyiGeek.top

# Basic Info
export JDK_SOFT="jdk-8u211-linux-x64.tar.gz"
export JDK_VER="1.8.0_211"
export JDk_DIR="/usr/java"

export TOMCAT_VER="9.0.31"
export TOMCAT_SOFT="apache-tomcat-${TOMCAT_VER}.tar.gz"
export TOMCAT_SOFT_URL="http://mirror.bit.edu.cn/apache/tomcat/tomcat-9/v${TOMCAT_VER}/bin/${TOMCAT_SOFT}"
export TOMCAT_DIR="/usr/local"
export TOMCAT_NAME=$(echo $TOMCAT_SOFT|sed 's/.tar.gz//g')
export STATUS=$1

function verity(){
    echo -e "\033[32m#正在启动Tomcat服务....#\033[0m"
    $TOMCAT_DIR/$TOMCAT_NAME/bin/startup.sh
    echo "验证是否启动成功..."
    sleep 5
    netstat -anlp|grep -wE "8005|8009|8080"
    echo -e "正在访问部署的Web：\n Web 端口:8080 \n Ajp 端口:8009 \n Shutdown 端口:8005"
    curl -I http://127.0.0.1:8080
}


# Usage
if [ $# -eq 0 ];then
    echo -e "\033[32m#Descript: Tomcat一键安装部署(单实例)   \033[0m"
    echo -e "\033[32m#Author: WeiyiGeek   \033[0m"
    echo -e "\033[32m#Usage(首次): $0 deploy\033[0m"
    echo -e "\033[32m#Usage(非首次): $0 start|stop \033[0m"
    exit
fi

# Run | Stop Tomcat
if [ $STATUS == "stop" ];then
    source /etc/profile
    echo -e "\033[31m#正在关闭Tomcat服务....#\033[0m"
    $TOMCAT_DIR/$TOMCAT_NAME/bin/shutdown.sh
    sleep 3
    flag=$(netstat -tnlp|grep -wE "8005|8009|8080" | wc -l)
    if [ $flag -eq 0 ];then
    echo -e "\033[32m#Tomcat服务已成功关闭....#\033[0m"
    fi
    exit
elif [ $STATUS == "start" ];then
    source /etc/profile
    verity
    exit
fi


# Configure JDK
echo 当前软件包目录:`pwd`
# //判断JDK是否已经存在
if [ ! -d $JDk_DIR/jdk$JDK_VER/ ];then
    echo -e "\033[31m#正在进行JDK部署配置....#\033[0m"
    mkdir -p $JDk_DIR
    tar -zxf $JDK_SOFT -C $JDk_DIR
    if [ ! $(grep 'JAVA_HOME' /etc/profile | wc -l) -eq 3];then
    cat >> /etc/profile << END
export JAVA_HOME=\$JDk_DIR/jdk\$JDK_VER/
export CLASSPATH=\$CLASSPATH:\$JAVA_HOME/lib:\$JAVA_HOME/jre/lib
export PATH=\$PATH:\$JAVA_HOME\bin
END
    fi
    source /etc/profile
else
    echo -e "\033[31m#JDK已经部署成功无需重新部署:#\033[0m"
    ls -alh $JDk_DIR/jdk$JDK_VER/
    echo -e "\033[31m#JDK版本信息:#\033[0m"
    $JDk_DIR/jdk$JDK_VER/bin/java -version
    source /etc/profile
fi


# Configure Tomcat
if [ ! -f $TOMCAT_SOFT ];then
    echo "下载Tomcat中....."
    wget -c $TOMCAT_SOFT_URL
    echo "Tomcat 已成功下载"
else
    echo -e "\033[31m#Tomcat部署包已经存在!#\033[0m"
    ls -alh $TOMCAT_SOFT
fi

if [ ! -d $TOMCAT_DIR/$TOMCAT_NAME ];then
    echo "部署Tomcat中....."
    mkdir -p $TOMCAT_DIR
    tar -zxf $TOMCAT_SOFT -C $TOMCAT_DIR
    echo $TOMCAT_DIR/$TOMCAT_NAME
   
fi
ls -alh $TOMCAT_DIR/$TOMCAT_NAME
verity