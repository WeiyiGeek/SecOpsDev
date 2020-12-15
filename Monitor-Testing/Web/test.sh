#!/bin/bash
export WXMSGURL="https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=4e1165c3-55c1-4bc4-8493-ecc5ccda9278"
export URL="http://192.168.10.200:31086/sfrz/selectLoginInfo.do?ksh=18400141110000&password=0659c7992e268962384eb17fafe88364"

curl ${URL} --silent -X POST > flag.txt
export FLAG=$(grep -c "内部错误" flag.txt)
export CONTENT=$(cat flag.txt)

if [[ "$FLAG" == "1" ]];then
  echo '{"msgtype":"markdown","markdown":{"content":"**考生中心运行状态**\n> 应用接口:'$(echo $URL| cut -d "/" -f 3)' \n>Message信息:<font color=\"warning\">\n 内部错误，请稍候再试或联系管理员 </font>"}}' > markdown.json
  curl ${WXMSGURL} -X POST -H "Content-Type:application/json" -d@markdown.json
fi


cat > /tmp/target.txt <<'EOF'
http://192.168.12.181
http://192.168.12.182
http://192.168.12.183
http://192.168.12.184
EOF
