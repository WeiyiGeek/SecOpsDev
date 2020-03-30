#!/bin/bash
# Description:自动部署Treesoft数据库查看管理软件
# 环境依赖:Docker
# Author:WeiyiGeek

TREEDMS_NAME="treesoft.zip"
TREEDMS_URL="http://10.20.172.109/${TREEDMS_NAME}"

if [ ! -f treesoft.zip -o ! -d ./treesoft ];then
  wget $TREEDMS_URL
  unzip $TREEDMS_NAME
else
  echo -e "#已下载已解压......"
fi

if [ ! -d /app/treesoft ];then mkdir -p /app/treesoft;fi
if [ ! -f /app/treesoft/treesoft/index.jsp ];then
  cp -ar ./treesoft /app/treesoft
else
  echo -e "#程序已在Webapps中"
fi


# [防火墙设置]
firewall-cmd --add-port=8080/tcp --permanent
firewall-cmd --reload


# [Tomcat镜像拉取]
CHECK_TOMCAT=$(docker images | grep -c "tomcat")
if [ $CHECK_TOMCAT -eq 0 ];then
  docker pull tomcat:7.0.103-jdk8
fi

CHECK_STATUS=$(docker ps | grep -c "OracleManager")
CHECK_STATUS1=$(docker ps -a | grep -c "OracleManager")
if [ $CHECK_STATUS -eq 0 -a $CHECK_STATUS1 -eq 0 ];then
  echo -e "#Run Tomcat"
  docker run -d --restart=always --nameOracleManager  -v /app/treesoft:/usr/local/tomcat/webapps:z -p 8080:8080 -e JAVA_OPTS=-Dsome.property=value -e Xmx=1024m tomcat:7.0.103-jdk8
elif [ $CHECK_STATUS -eq 0 -a $CHECK_STATUS1 -eq 1 ]
  echo -e "#Tomcat start ....."
  docker start OracleManager
else
  echo -e "#Tomcat 已在运行之中....."
fi

curl -I  http://127.0.0.1:8080/treesoft/treesoft/index
curl -I  http://127.0.0.1:8080/treenms/treesoft/index
CHECK_WEB=$(curl -Is http://127.0.0.1:8080/treesoft/treesoft/index | grep -c "200")
if [ $CHECK_WEB -eq 1 ];then
  echo -e "\e[32m#项目启动成功，恭喜你.....\e[0m"  
else
  echo -e "\e[31m#项目启动失败请检查.....\e[0m"  
fi