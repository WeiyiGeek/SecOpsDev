#!/bin/bash
# Desc: Etcd集群一件安装
# Author: WeiyiGeek
# Create: 2020年4月24日 09:48:48

#[全局变量]
export ETCD_VER=v3.4.7
export ETCD_SRCNAME=etcd-${ETCD_VER}-linux-amd64.tar.gz
export ETCD_URL=https://github.com/etcd-io/etcd/releases/download/${ETCD_VER}/${ETCD_SRCNAME}
export ETCD_DIR=/usr/local/etcd
export ETCD_CONF=/etc/etcd
export ETCD_DATA=/apps/etcd/data
export ETCD_NODE1=192.168.10.241
export ETCD_NODE2=192.168.10.242
export ETCD_NODE3=192.168.10.243


function Usage(){
  echo -e "\e[33m#Usage:$0 node[1~3].weiyigeek.top\n#Example: NODENAME = node[1~3] \n\n\e[0m"
}

Usage

set -xue
export CURRENT_NODE=$1
export NODE_NAME=${CURRENT_NODE%%.*}
export NODE_DOMAIN=${CURRENT_NODE#*.}

#[使用帮助]


function BeforeSetting(){
  #1.当前机器hostname设置
  hostnamectl set-hostname ${NODE_NAME}

  #2.配置/etc/hosts
rm -rf /etc/hosts
cat <<END >/etc/hosts
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
$ETCD_NODE1 node1.${NODE_DOMAIN}
$ETCD_NODE2 node2.${NODE_DOMAIN}
$ETCD_NODE3 node3.${NODE_DOMAIN}
END

  #3.防火墙配置
  firewall-cmd --permanent --zone=public --add-port=2379-2380/tcp 
  firewall-cmd --reload
}


#[暂时没用]
# function ChangeDownUrl(){
#   ETCD_URL=$(echo $1 | sed 's/raw.githubusercontent.com/cdn.jsdelivr.net\/gh/' \
#                | sed 's/github.com/cdn.jsdelivr.net\/gh/' \
#                | sed 's/\/master//' | sed 's/\/blob//' )
# }

function Download(){
  if [[ ! -f ./${ETCD_SRCNAME} ]];then
    curl -L ${DOWNLOAD_URL}/${ETCD_VER}/etcd-${ETCD_VER}-linux-amd64.tar.gz -o etcd-${ETCD_VER}-linux-amd64.tar.gz
  else
    echo -e "#${ETCD_SRCNAME} Already Exsit!"
  fi
}

function Install(){
  #安装验证
  if [[ ! -d ${ETCD_DIR} ]];then
    mkdir -p ${ETCD_DIR}
  else
    rm -rf ${ETCD_DIR}
    mkdir -p ${ETCD_DIR}
  fi
  
  #数据存储
  mkdir -vp  ${ETCD_DATA}

  #解压
  tar xzvf ${ETCD_SRCNAME} -C ${ETCD_DIR} --strip-components=1

  #判断软件链接
  if [[ ! -f /usr/bin/etcd ]];then
    echo -e "#links File Not Exsit!"
    ln -s ${ETCD_DIR}/etcd /usr/bin
    ln -s ${ETCD_DIR}/etcdctl /usr/bin
  fi

  #验证是否安装成功否则停止安装
  /usr/bin/etcd --version
  /usr/bin/etcdctl version

  if [[ $? -ne 0 ]];then
    echo -e "\e[31m#Install Error!\e[0m"
    exit 0
  fi
}


function AfterSetting(){
  #Etcd配置
  rm -rf ${ETCD_CONF}/etcd.conf
  mkdir -vp ${ETCD_CONF} /var/lib/etcd/
  export CURRENT_HOST=$(cat /etc/hosts | grep ${NODE_NAME} | awk -F " " '{print $1}')
cat > ${ETCD_CONF}/etcd.conf <<END
[member]
ETCD_NAME=${NODE_NAME}
ETCD_DATA_DIR=${ETCD_DATA}
ETCD_LISTEN_CLIENT_URLS="http://${CURRENT_HOST}:2379,http://127.0.0.1:2379"
ETCD_LISTEN_PEER_URLS="http://${CURRENT_HOST}:2380"

[cluster]
ETCD_ADVERTISE_CLIENT_URLS="http://${CURRENT_NODE}:2379"
ETCD_INITIAL_ADVERTISE_PEER_URLS="http://${CURRENT_NODE}:2380"
ETCD_INITIAL_CLUSTER="node1=http://node1.${NODE_DOMAIN}:2380,node2=http://node2.${NODE_DOMAIN}:2380,node3=http://node3.${NODE_DOMAIN}:2380"
ETCD_INITIAL_CLUSTER_TOKEN="etcd-cluster"
ETCD_INITIAL_CLUSTER_STATE=new

# [version]
# ETCD_ENABLE_V2=true

#[Security]
# ETCD_CERT_FILE="/opt/etcd/ssl/server.pem"
# ETCD_KEY_FILE="/opt/etcd/ssl/server-key.pem"
# ETCD_TRUSTED_CA_FILE="/opt/etcd/ssl/ca.pem"
# ETCD_CLIENT_CERT_AUTH="true"
# ETCD_PEER_CERT_FILE="/opt/etcd/ssl/server.pem"
# ETCD_PEER_KEY_FILE="/opt/etcd/ssl/server-key.pem"
# ETCD_PEER_TRUSTED_CA_FILE="/opt/etcd/ssl/ca.pem"
# ETCD_PEER_CLIENT_CERT_AUTH="true"
END

 #systemd配置
cat > /usr/lib/systemd/system/etcd.service <<END
[Unit]
Description=Etcd Server
Documentation=https://github.com/etcd-io/etcd
After=network.target

[Service]
Type=simple
WorkingDirectory=/var/lib/etcd/
EnvironmentFile=-/etc/etcd/etcd.conf
ExecStart=/usr/bin/etcd
KillMode=process
Restart=always
RestartSec=3
LimitNOFILE=655350
LimitNPROC=655350
PrivateTmp=false
SuccessExitStatus=143

[Install]
WantedBy=multi-user.target
END

 #Reload systemd manager configuration
 systemctl daemon-reload
}


function ServiceRun(){
  echo -e "#正在启动Etcd服务"
  systemctl restart etcd.service
  echo -e "#当所有节点启动后运行以下脚本或者 cat etcd.txt 查看"
  echo -e "ENDPOINTS=$ETCD_NODE1:2379,$ETCD_NODE2:2379,$ETCD_NODE3:2379 \netcdctl -w table --endpoints=\$ENDPOINTS endpoint status"
  echo -e "ENDPOINTS=$ETCD_NODE1:2379,$ETCD_NODE2:2379,$ETCD_NODE3:2379 \netcdctl -w table --endpoints=\$ENDPOINTS endpoint status" > etcd.txt
}

BeforeSetting
Download
Install
AfterSetting
ServiceRun
