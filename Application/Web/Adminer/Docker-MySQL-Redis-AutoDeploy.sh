#!/bin/bash
# Author:WeiyiGeek
# Description: Docker 自动安装MySQL-Redis
# Test:Linux WeiyiGeek-MySQL 4.18.0-80.el8.x86_64 #1 SMP Tue Jun 4 09:19:46 UTC 2019 x86_64 x86_64 x86_64 GNU/Linux

DOCKER_COMPOSE="http://127.0.0.1/docker-compose.yml"
DOCKER_CONTAINERD="containerd.io-1.2.6-3.3.el7.x86_64.rpm"

# [环境依赖软件下载]
yum install -y wget
CHECK_REPO=$(grep -c "mirrors.aliyun.com" /etc/yum.repos.d/CentOS-Base.repo)
if [ $CHECK_REPO -eq 0 ];then
  sudo cp -a CentOS-Base.repo{,.bak}
  sudo wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-8.repo
else
  echo -e "\e[32m CentOS-Base.repo Already configured mirrors.aliyun.com \e[0m"
fi

# [验证是否安装过旧版本]
CHECK_DOCKER=$(rpm -qa | grep -Ec "docker|docker-engine")
CHECK_NEWDOCKER=$(rpm -qa | grep -Ec "docker-ce")
if [ $CHECK_DOCKER -gt 0 -a $CHECK_NEWDOCKER -ne 2 ];then
  sudo yum remove docker docker-common docker-selinux docker-engine
else
  echo -e "\e[32m 您已经安装 Docker-ce 请勿重新安装......"
fi

# [依赖安装]
sudo yum install -y yum-utils device-mapper-persistent-data lvm2 libcgroup
if [! -f /etc/yum.repos.d/docker-ce.repo ];then
  sudo wget -O /etc/yum.repos.d/docker-ce.repo https://download.docker.com/linux/centos/docker-ce.repo
  sudo sed -i 's+download.docker.com+mirrors.tuna.tsinghua.edu.cn/docker-ce+' /etc/yum.repos.d/docker-ce.repo
fi

# [下载安装Docker Container]
if [ ! -f $DOCKER_CONTAINERD ];then
  echo -e "\e[32m Download  ${DOCKER_CONTAINERD} \e[0m"
  sudo wget https://download.docker.com/linux/centos/7/x86_64/edge/Packages/${DOCKER_CONTAINERD}
  sudo yum install -y ${DOCKER_CONTAINERD}
else
  echo -e "\e[32m  ${DOCKER_CONTAINERD} Already  Download \e[0m"
fi

# [建立YUM源Index缓存]
sudo yum makecache
yum list docker-ce --showduplicates | sort -r
read -t 15 -p "请输入需要安装的制定版本(否则安装默认版本): " version
if [ "$version" = "" ];then
  sudo yum install -y docker-ce 
else
  sudo yum install -y docker-ce-${version}
fi

# [下载安装Dokcer-Compose]
if [ ! -f /usr/local/bin/docker-compose ];then
  sudo curl -L "https://github.com/docker/compose/releases/download/1.23.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/bin/docker-compose
  sudo chmod +x /usr/local/docker-compose
  docker-compose --version
fi

# [检测是否安装成功并启动]
CHECK_INSTALL_DOCKER=$(docker --version | grep -c "version")
if [ $CHECK_INSTALL_DOCKER -eq  1 ];then
  echo -e "\e[32m#Docker 已经成功安装.....\e[0m"
  CHECK_SPEEDUP=$(grep -c "aliyuncs" /usr/lib/systemd/system/docker.service)
  if [ $CHECK_SPEEDUP -eq 0 ];then
    sudo systemctl enable docker && systemctl start docker
    sudo sed -i 's#containerd.sock#containerd.sock --registry-mirrors=https://xlx9erfu.mirror.aliyuncs.com#g' /usr/lib/systemd/system/docker.service
    sudo  systemctl stop docker && sudo systemctl daemon-reload
  fi
else
  echo -e "\e[31m#Docker 安装失败请检查.....\e[0m"
  exit
fi

# [启动Docker]
sudo systemctl start docker
CHECK_STATUS=$(systemctl status docker | grep -c "active (running)")
if [ $CHECK_STATUS -eq 1 ];then  
  echo -e "\e[32m#Docker 启动成功.....\e[0m";
else
  echo -e "\e[31m#Docker 启动失败.....\e[0m";
  journalctl -xe
fi


# [持久化目录建立]
if [ ! -d /app/mysql5/ -o ! -d /app/mysql8/ ];then
  echo -e "\e[32m#构建数据库持久化目录.....\e[0m";
  sudo mkdir -p /app/{mysql5,mysql8,redis}
fi

# [下载编辑的Docker-compose]
if [ ! -f "docker-compose.yml" ];then
  echo -e "\e[32m#正在下载Docker-compose.yml并进行验证.....\e[0m";
  sudo wget $DOCKER_COMPOSE
fi

# [验证Docker-compose.yml 并设置 防火墙]
docker-compose config
if [ $? -eq 0 ];then
  echo -e "\e[32m#验证结果：OK..\e[0m";
  sudo firewall-cmd --add-port=6379/tcp --permanent
  sudo firewall-cmd --add-port=3305-3306/tcp --permanent
  sudo firewall-cmd --add-port=8888/tcp --permanent
  sudo firewall-cmd --reload
else
  echo -e "\e[31m#请验证docker-compose.yml文件....\e[0m";
  exit
fi

# [查看设置的防火墙以及采用Docker-compose启动pull镜像创建容器]
echo -e "\e[32m#防火墙设置查看....\e[0m";
sudo firewall-cmd --list-all
echo -e "\e[32m#镜像构建中.....\e[0m";
sudo docker-compose up
 