#!/bin/bash
#Descript: Tomcat一键安装部署运行和停止(多实例)
#Author: WeiyiGeek
#WebSite: WeiyiGeek.top

# Basic Info
export JDK_SOFT="jdk-8u211-linux-x64.tar.gz"
export JDK_VER="1.8.0_211"
export JDk_DIR="/usr/java"

export TOMCAT_VER="9.0.31"
export TOMCAT_SOFT="apache-tomcat-${TOMCAT_VER}.tar.gz"
export TOMCAT_SOFT_URL="http://mirror.bit.edu.cn/apache/tomcat/tomcat-9/v${TOMCAT_VER}/bin/${TOMCAT_SOFT}"
export TOMCAT_DIR="/usr/local/tomcat"
export TOMCAT_NAME=$(echo $TOMCAT_SOFT|sed 's/.tar.gz//g')

export ACTION=$1
export TOMCAT_PROJECT=$2
export TOMCAT_PORT=${TOMCAT_PROJECT#*-}
export shutDownPort=$(expr $TOMCAT_PORT + 2000 + 1)
export ajpPort=$(expr $TOMCAT_PORT + 1000 + 1)
source /etc/profile

# Function 
# // Usage
function usage(){
    if [ $# -eq 0 ];then
        echo -e "\033[32m#Descript: Tomcat一键安装部署(多实例)   \033[0m"
        echo -e "\033[32m#Author: WeiyiGeek  \033[0m"
        echo -e "\033[32m#Usage(首次): $0 deploy PeojectName-Port \033[0m"
        echo -e "\033[32m#Usage(非首次): $0 ls (查看当前的项目) \033[0m"
        echo -e "\033[32m#Usage(非首次): $0 [start|stop|restart] PeojectName-Port \033[0m"
        exit
    fi
}

# //启动Tomcat
function startTomcat(){
    echo -e "\033[32m#正在启动Tomcat服务....#\033[0m"
    $TOMCAT_DIR/$TOMCAT_PROJECT/bin/startup.sh
}

# //停止Tomcat
function stopTomcat(){
    echo -e "\033[32m#正在停止Tomcat服务....#\033[0m"
    $TOMCAT_DIR/$TOMCAT_PROJECT/bin/shutdown.sh
}

# //重启Tomcat
function resetTomcat(){
    stopTomcat
    sleep 3
    startTomcat
}

# //验证Tomcat状态
function verity(){
    export JDK_VER="1.8.0_211"
    export JDk_DIR="/usr/java"
    echo -e "\033[32m#验证是否·启动或者停止·成功 ${shutDownPort} ${ajpPort} ${TOMCAT_PORT}$ ...#\033[0m"
    sleep 2
    status1=$(netstat -tln | awk '{ printf $4"\n"}' | awk -F ':' '{printf $NF"\n"}' | grep -wE "^${shutDownPort}$|^${ajpPort}$|^${TOMCAT_PORT}$"|wc -l)
    curl -sI http://127.0.0.1:${TOMCAT_PORT}
    sleep 1
    status2=$?
    if [ ! $status1 -eq 0 -a $status2 -eq 0 ];then
       echo -e "\033[32m#Tomcat 已启动...#\033[0m"
    else
       echo -e "\033[33m#Tomcat 已停止...#\033[0m"
    fi
    exit
}

# Configure JDK
# //安装JDK环境
function installJDK(){
    echo 当前软件包目录:`pwd`
    # //判断JDK是否已经存在
    if [ ! -d $JDk_DIR/jdk$JDK_VER/ ];then
        echo -e "\033[31m#正在进行JDK部署配置....#\033[0m"
        mkdir -p $JDk_DIR
        tar -zxf $JDK_SOFT -C $JDk_DIR
        if [ ! $(grep 'JAVA_HOME' /etc/profile | wc -l) -eq 3 ];then
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
}


# Configure Tomcat
# //部署项目环境
function installTOMCAT(){
    if [ ! -f $TOMCAT_SOFT ];then
        echo "#### 下载Tomcat中....."
        wget -c $TOMCAT_SOFT_URL
        echo "#### Tomcat 已成功下载"
    else
        echo -e "\033[31m#Tomcat部署包已经存在!#\033[0m"
        ls -alh $TOMCAT_SOFT
    fi

    if [ ! -d $TOMCAT_DIR/$TOMCAT_NAME ];then
        echo -e "\033[32m#解压部署Tomcat中.....#\033[0m"
        mkdir -p $TOMCAT_DIR/
        tar -zxf $TOMCAT_SOFT -C $TOMCAT_DIR
        echo $TOMCAT_DIR/$TOMCAT_NAME
    fi

    if [ ! -d $TOMCAT_DIR/$TOMCAT_PROJECT ];then
        echo -e "\033[32m#拷贝Tomcat应用程序到 $TOMCAT_PROJECT 项目中....#\033[0m"
        mkdir -p $TOMCAT_DIR/$TOMCAT_PROJECT
        cp -a $TOMCAT_DIR/$TOMCAT_NAME/*  $TOMCAT_DIR/$TOMCAT_PROJECT
        echo -e "$TOMCAT_DIR/$TOMCAT_PROJECT"
        ls $TOMCAT_DIR/$TOMCAT_PROJECT
    else
        echo -e "\033[31m#Tomcat应用程序 $TOMCAT_PROJECT 项目已部署无需重新部署#\033[0m"
        ls $TOMCAT_DIR/$TOMCAT_NAME
        exit
    fi
}

# //部署项目环境
# //Tomcat 默认端口 8080 、8009 、8005
function webConfig(){
    tomcatPath="$TOMCAT_DIR/$TOMCAT_PROJECT/conf/server.xml"
    if [ ! -f $tomcatPath ];then
        echo -e "\033[31m#Tomcat应用 - $TOMCAT_PROJECT 项目 server.xml 配置文件不存在部署失败#\033[0m"
        exit
    fi
    echo -e "\033[32m#正在配置Tomcat的server.xml 配置文件....#\033[0m"
    echo -e "\033[32m# Tomcat Port = ${TOMCAT_PORT}\n Tomcat ajp Port = ${ajpPort} \n Tomcat Shutdown Port ${shutDownPort}  \033[0m"
    sed -i "s/port=\"8005\"/port=\"${shutDownPort}\"/g" $tomcatPath
    sed -i "s/port=\"8009\"/port=\"${ajpPort}\"/g" $tomcatPath
    sed -i "s/port=\"8080\"/port=\"${TOMCAT_PORT}\"/g" $tomcatPath
    grep -nE "8005|8009|8080" $tomcatPath
}

# 程序入口
case $ACTION in 
    "start")
        startTomcat
        verity
        ;;
    "stop")
        stopTomcat
        verity
        ;;
    "restart")
        resetTomcat
        verity
        ;;
    "ls")
        echo -e "\033[32m # 当前已部署的Tomcat项目\033[0m"
        ls $TOMCAT_DIR
        ;;
    "deploy")
        portinfo=$(netstat -tln | awk '{ printf $4"\n"}' | awk -F ':' '{printf $NF"\n"}' | grep -wE "^${shutDownPort}$|^${ajpPort}$|^${TOMCAT_PORT}$"|wc -l)
        if [ ! $portinfo -eq 0 ];then
            echo -e "\e[31m 存在端口已被占用不能进行部署,被占用的端口如下:\e[0m"
            netstat -tnlp|grep -wE "^${shutDownPort}$|^${ajpPort}$|^${TOMCAT_PORT}$"
            exit
        fi
        installJDK
        installTOMCAT
        if [ ! $TOMCAT_PORT -eq 8080 ];then
            webConfig
        fi
        startTomcat
        verity
        ;;
    *)
        usage $*
        exit
        ;;
esac


