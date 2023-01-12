#!/bin/bash
## @Title: 使用phantomjs针对网站首页监控预与监控检测并进行企业微信预警
## @Author: WeiyiGeek 
## @CreateTime: 2023年1月11日 15点34分
## @Blog: https://blog.weiyigeek.top
## @Version: 1.3
# set -e

# 监控目标站点配置文件
MONITORSITE=/tmp/target.txt
cat > ${MONITORSITE} <<'EOF'
https://www.weiyigeek.top
https://blog.weiyigeek.top
EOF


# 全局变量
# 请将此处修改为你企业微信机器人webhook地址
export WXMSGURL="https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=51648169-7638-43a4-97d6-dfd39b48ea23"
export NETTYPE="外网访问"
export HCMSG=""
export XKMSG=""
export ZHCXMSG=""
# 安装使用phantomjs时报 ` libproviders.so: cannot open shared object file:` 错误时需要取消如下注释。
# export OPENSSL_CONF=/dev/null


################################
# 名称: DependencyCheck
# 说明: 脚本运行依赖检测
################################
function DependencyCheck(){
  phantomjs -v > /dev/null 2>&1
  if [[ "$?" != "0" ]];then echo -e "\e[31m[Error] Phantomjs NotFound,Please Install this! \e[0m";exit 0;fi
  jq --version > /dev/null 2>&1
  if [[ "$?" != "0" ]];then echo -e "\e[31m[Error] Phantomjs jq,Please Install jq! \n$ yum install jq \e[0m";exit 0;fi
}


################################
# 名称: SendWXMsg
# 说明: 企业微信消息机器人消息发送
################################
function SendWXMsg(){
  if [[ "$1" == "text" ]];then
    #text 格式
    case $2 in 
    "1")
        echo '{"msgtype":"text","text":{"mentioned_list":["@all"],"content":"访问类型:'${NETTYPE}'\n报警类型:'$3'\n监控地址:'${TARGETURL}'\n报警信息:'$4'"}}' > text.json
       ;;
    "2")
        echo '{"msgtype":"text","text":{"mentioned_list":["@all"],"content":"访问类型:'${NETTYPE}'\n报警类型:'$3'\n监控地址:'${TARGETURL}'\n报警信息:'$4'异常标识校验值:'$5'\n备注:网站预览图生成上传中."}}' > text.json
      ;;
    *)
        sleep 1
      ;;
    esac
    sed -i 's#_#\\n#g' text.json
    curl ${WXMSGURL} -X POST -H "Content-Type:application/json" -d@text.json
  elif [[ "$1" == "image" ]];then
    #image 格式
    echo '{"msgtype":"image","image":{"base64":"'$2'","md5":"'$3'"}}' > data.json
    curl ${WXMSGURL} -X POST -H "Content-Type:application/json" -d@data.json
  elif [[ "$1" == "markdown" ]];then
    #markdown 格式
    if [[ "$2" == "1" ]];then
      echo '{"msgtype":"markdown","markdown":{"content":"**'$3'**\n> 访问类型:'${NETTYPE}'访问\n> 应用状态信息:<font color=\"info\">\n'$4'</font>"}}' > markdown.json
      sed -i 's#_#\\n#g' markdown.json
    fi
     curl ${WXMSGURL} -X POST -H "Content-Type:application/json" -d@markdown.json
  else
    sleep
  fi
}

################################
# 名称: TargetMD5
# 说明: 目标站点首页的MD5值生成
################################
function TargetMD5(){
  # 判断文件是否存在
  if [[ ! -d "${TARGETDIR}" ]];then echo "Create directory ${TARGETDIR}.....";mkdir -p $TARGETDIR; fi 
  if [[ ! -f "${TARGETFILE}" ]]; then curl -m 15 ${TARGETURL} -o ${TARGETFILE}; fi
  export TARGETFILEMD5=$(md5sum ${TARGETFILE} | awk -F ' ' '{print $1}')
}


################################
# 名称: Record
# 说明: 网站首页指纹(md5值)比对以及网页截图
################################
function Record(){ 
   curl -m 20 ${TARGETURL} -o ${RECORDFILE}
   export RECORDFILEMD5="$(md5sum $_ | awk -F '  ' '{print $1}')"  
   if [[ "${TARGETFILEMD5}MD5" != "${RECORDFILEMD5}MD5" ]]; then
      # 异常信息记录
      echo "${RECORDFILE}-${RECORDFILEMD5}" >> ${TARGETDIR}exception.log

      # 差异比对
      DIFFTEXT=$(diff --normal ${TARGETFILE} ${RECORDFILE} | egrep "^[0-9]" | tr '\n' '__' )

      # 使用 phantomjs 生成截图，注意此处 /usr/local/src/phantomjs/custom/screen-capture.js 路径
      /usr/local/bin/phantomjs //usr/local/src/phantomjs/custom/screen-capture.js ${TARGETURL} ${RECORDFILE}.png
      IMGMD5="$(md5sum ${RECORDFILE}.png| awk -F '  ' '{print $1}')"
      IMGBASE64="$(base64 -w 0 < ${RECORDFILE}.png)"

      # 信息发送
      SendWXMsg "text" "2" "网站修改提醒" "被修改的行数:\n${DIFFTEXT}" "${RECORDFILEMD5}"

      sleep 1

      # 网页截图发送 (外网发送)
      SendWXMsg "image" "${IMGBASE64}" "${IMGMD5}" 
      cp -f ${RECORDFILE} ${TARGETFILE}

      # 发送警告次数
      RCOUNT=RCOUNT${FLAG}
      let ${RCOUNT}+=1
      export ${RCOUNT}=${!RCOUNT}
      if [[ ${!RCOUNT} -eq 1 ]];then
        cp -f ${RECORDFILE} ${TARGETFILE}
        export ${RCOUNT}=0
      fi
  fi 
}


################################
# 名称: SiteMonitorCheck
# 说明: 网站访问异常检测
################################
function SiteMonitorCheck (){
    STATUS=$(curl -I -m 10 -s -o /dev/null -w "%{http_code}" ${TARGETURL} )
    if [[ $? -ne 0 ]];then STATUS="CLOSE";fi
    # 当系统故障关闭后只推送三次，然后恢复正常时候又重新计数
    COUNT=COUNT${FLAG}
    let ${COUNT}+=1
    if [[ "$STATUS" == "200" ]];then
      Record
    elif [[ "$STATUS" == "200" && ${!COUNT} -gt 2 ]];then
      export ${COUNT}=0
    elif [[ "$STATUS" == "302" ]];then
      local LOCATION=$(curl -I -m 10 -s  ${TARGETURL} | egrep "^Location" | tr -d '\r' | cut -d "/" -f 3)
      SendWXMsg "text" "1" "请求跳转异常地址" "_HTTP响应码:${STATUS}_跳转地址:${LOCATION}"
    elif [[ "$STATUS" == "CLOSE" && ${mcount} -le 2 ]];then
      SendWXMsg "text" "1" "访问异常" "外网无法访问该网站" 
      export ${COUNT}=${!COUNT}
      continue
    else
      if [[ "${STATUS}" == "403" && "$(echo ${TARGETURL} | egrep -c "40081|30081") == '1'" ]];then
       Record
       continue
      else
        SendWXMsg "text" "1" "请求返回响应码异常" "HTTP响应码[${STATUS}]"
      fi
    fi
}


################################
# 名称: HealthCheck
# 说明: 网页站点外网访问检测
################################
function HealthCheck(){
  if [[ "$NETTYPE" == "外网" ]];then
    local CHECK=$(curl -m 15 -o /dev/null -s -w "DNS解析耗时: "%{time_namelookup}"s_重定向耗时: "%{time_redirect}"s_TCP连接耗时: "%{time_connect}"s_请求准备耗时: "%{time_pretransfer}"s_应用连接耗时: "%{time_appconnect}"s_传输耗时: "%{time_starttransfer}"s_下载速度: "%{speed_download}"byte/s_整体请求响应耗时: "%{time_total}"s" "${TARGETURL}")
    if [[ $? -eq 0 ]];then
      SendWXMsg "markdown" "1" "${NETTYPE}-检查网站连接状态" "__> ${CHECK}"
    else
      SendWXMsg "markdown" "1" "${NETTYPE}-检查网站连接状态" "巡检地址: ${TARGETURL}__> 巡检信息: 访问异常"
    fi
  else
    local CHECK=$(curl -m 10 -o /dev/null -s -w "%{http_code}" "${TARGETURL}")
    if [[ $? -ne 0 || "$CHECK" != "200" ]];then
      export HCMSG="${HCMSG}__> 巡检地址: ${TARGETURL}_巡检信息: 异常"
    else
      # export HCMSG="${HCMSG}__> 巡检地址: ${TARGETURL}_巡检信息: 正常"
      echo .
    fi
  fi
}


################################
# 名称: XKservice
# 说明: 指定应用监控埋点
################################
function XKservice(){
  if [[ "$NETTYPE" == "外网" ]];then
    local CHECK=$(echo $TARGETURL | egrep -c "xk")
    if [[  "$CHECK" == "1" ]];then
      curl -m 15 -s "${TARGETURL}/app/version" -o xk.json
      local STATUS=$(jq '"应用状态:"+(.code|tostring)+"_应用信息:"+(.msg|tostring)+"_当前应用版本:"+(.data.version)' xk.json  | tr -d '"')
      SendWXMsg "markdown" "1" "应用埋点监控" "__> ${STATUS}"
    fi
  else
    local CHECK=$(echo "${TARGETURL}" | egrep -c "8010|9010")
    if [[ "$CHECK" == "1" ]];then
      curl -m 15 -s "${TARGETURL}/app/version" -o xk.json
      local STATUS=$(jq -M '"_Status:"+(.code|tostring)+"_Msg:"+(.msg|tostring)+"_Version:"+(.data.version)' xk.json  | tr -d '"')
      export XKMSG="${XKMSG}__> 应用地址:${TARGETURL}_${STATUS}"
    fi
  fi
}

################################
# 名称: InnerAppServices
# 说明: 内部应用服务监控埋点
################################
function InnerAppServices(){
  if [[ "$(echo $TARGETURL| egrep -c '40081|30081')" == "1" ]];then
    curl -m 15 -s "${TARGETURL}/user/getVersion.htmls" -o innerApp.json
    STATUS=$(jq -M '"_Status:"+(.db|tostring)+"_Version:"+(.version|tostring)' innerApp.json | tr -d '"')
    export ZHCXMSG="${ZHCXMSG}__> 应用地址:${TARGETURL}_${STATUS}"
  fi
}


################################
# 名称: main
# 说明: 脚本主执行入口
# 参数: 无
# 返回值: 无
################################
function main(){
  # 依赖检测
  DependencyCheck

  # 目标监控
  for i in $(cat ${MONITORSITE});do
    CHECK=$(echo $i | egrep -c "^#")
    if [[ "$CHECK" == "1" ]];then continue;fi
    export TARGETURL=$i
    export URL=$(echo $i|cut -f 3 -d '/')
    export TARGETDIR="/var/log/WebScreenCapture/${URL}/"
    export TARGETFILE="${TARGETDIR}index.html"
    export RECORDFILE="${TARGETDIR}$(date +%Y%m%d%H%M%S)-index.html"

    # 目标MD5值
    TargetMD5

    if [[ "$1" == "H"  ]];then
      HealthCheck
      XKservice
      InnerAppServices
    else
      let FLAG+=1
      export FLAG=${FLAG}
      SiteMonitorCheck
    fi
  done

  # 指定应用执行完毕后
  if [[ "$1"  == "H" && "$NETTYPE" == "内网" ]];then
    if [[ "${#HCMSG}" != "0" ]];then 
      SendWXMsg "markdown" "1" "${NETTYPE}-业务应用运行情况巡查" "${HCMSG}_检测时间:$(date +%Y-%m-%d~%H:%M:%S)"
    else
      SendWXMsg "markdown" "1" "${NETTYPE}-业务应用运行情况巡查" "所有被监控业务正常_检测时间:$(date +%Y-%m-%d~%H:%M:%S)"
    fi;

    if [[ "${#XKMSG}" != "0" ]];then
      SendWXMsg "markdown" "1" "${NETTYPE}-xk应用系统监控" "${XKMSG}_检测时间:$(date +%Y-%m-%d~%H:%M:%S)"
    fi

    if [[ "${#ZHCXMSG}" != "0" ]];then
      echo ${ZHCXKMSG}
      SendWXMsg "markdown" "1" "${NETTYPE}-zhcx应用系统监控" "${ZHCXMSG}_检测时间:$(date +%Y-%m-%d~%H:%M:%S)"
    fi
  fi
}

main $1
# export HCMSG=""
# export XKMSG=""
# export ZHCXMSG=""
export FLAG=0