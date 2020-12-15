#!/bin/bash
export WXMSGURL="https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=4e1165c3-55c1-4bc4-8493-ecc5ccda9278"
#export WXMSGURL="https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=8239f334-5ae1-4bcc-b183-b505662315e1"
IPADDR=$1
PORT=$2
APPNAME=$3
HOSTIP=$(hostname -I | cut -f 1 -d ' ')
if [[ -f "/sys/class/net/ens192/address" ]];then
  HOSTMAC=$(cat /sys/class/net/ens192/address| tr ':' '-')
else
  HOSTMAC=$(cat /sys/class/net/eth0/address | tr ':' '-')
fi
ERRORFILE="./logs/${1}-${2}.log"


## [脚本帮助]
if [ $# -ne 3 ]; then
  echo "Usage:"
  echo "  $0 [IPADDR|DOMAIN] [PORT] [APPNAME]"
  echo ""
  echo "Examples:"
  echo "  $0 localhost 80 Web"
  echo "  $0 192.168.1.1 80 Web"
  exit
fi

## [判断nc是否安装在此机器上]
nc --version >/dev/null 2>&1
if [[ $? -ne 0 ]];then yum install -y nc; fi
if [[ ! -d "./logs" ]];then mkdir ./logs/; fi 
if [[ ! -f $ERRORFILE  ]];then touch ./$ERRORFILE; fi 

## [端口开放检测]
function Ncat() {
  nc -zvw3 ${1} ${2} > ${1}.txt 2>&1
  STATUS=$(grep -c "Connected" ${1}.txt)
  if [[ $STATUS -eq 1 ]];then
    return 1
  else
    return 2
  fi
}

## 端口预警
function WXMsg(){
  if [[ "$1" == "error" ]];then
    echo '{"msgtype":"markdown","markdown":{"content":"**'$2'**\n> 主机地址: ['${HOSTIP}']('${HOSTIP}')\n> 主机MAC: '$HOSTMAC'\n> 访问主机: '${IPADDR}'\n> 访问端口: '${PORT}'\n> 访问应用: '${APPNAME}'\n> 端口状态: <font color=\"warning\">\n'$3'</font>"}}' > markdown.json
  else
    echo '{"msgtype":"markdown","markdown":{"content":"**'$2'**\n> 主机地址: ['${HOSTIP}']('${HOSTIP}')\n> 主机MAC: '$HOSTMAC'\n> 访问主机: '${IPADDR}'\n> 访问端口: '${PORT}'\n> 访问应用: '${APPNAME}'\n> 端口状态: <font color=\"info\">\n'$3'</font>"}}' > markdown.json
  fi
  sed -i 's#_#\\n#g' markdown.json
  curl ${WXMSGURL} -X POST -H "Content-Type:application/json" -d@markdown.json
}

Ncat ${IPADDR} ${PORT}
PORTSTATUS=$?
ERROR=$(cat $ERRORFILE)
if [[ $PORTSTATUS -eq 2 && "${ERROR}" != "true" ]];then
  WXMsg "error" "应用-综合查询系统依赖检查" "端口访问异常"
  echo "true" > $ERRORFILE
elif [[ $PORTSTATUS -eq 1 && "${ERROR}" == "true" ]];then
  WXMsg "success" "应用-综合查询系统依赖检查" "端口访问已恢复"
  echo "false" > $ERRORFILE
fi

