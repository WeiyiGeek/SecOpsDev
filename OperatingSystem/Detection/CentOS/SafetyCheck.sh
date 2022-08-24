#!/bin/bash
#
# #------------------------------------------------------------------#
# |   服务器安全检查工具      WeiyiGeek | Server security check tool  |
# #------------------------------------------------------------------#
# #------------------------------------------------------------------#
#

# === 全局定义 ===
# 全局参数定义
BuildTime="20200606"
WorkDir=".SecurityChech/"

# 字体颜色定义
Font_Black="\033[30m"
Font_Red="\033[31m"
Font_Green="\033[32m"
Font_Yellow="\033[33m"
Font_Blue="\033[34m"
Font_Purple="\033[35m"
Font_SkyBlue="\033[36m"
Font_White="\033[37m"
Font_Suffix="\033[0m"

# === 全局模块 ===
# 消息提示定义
function Msg(){
  case $1 in
    "Info")
      Msg_Info="${Font_Blue}[Info] ${2} ${Font_Suffix}"
      echo -e ${Msg_Info}
    ;;
    "Warning") 
      Msg_Warning="${Font_Yellow}[Warning] ${2} ${Font_Suffix}"
      echo -e ${Msg_Warning}
    ;;
    "Debug")
      Msg_Debug="${Font_Yellow}[Debug] ${2} ${Font_Suffix}"
      echo -e ${Msg_Debug}
    ;;
    "Error")
      Msg_Error="${Font_Red}[Error] ${2} ${Font_Suffix}"
      echo -e ${Msg_Error}
    ;;
    "Success")
      Msg_Success="${Font_Green}[Success] ${2} ${Font_Suffix}"
      echo -e ${Msg_Success}
    ;;
    "Fail")
      Msg_Fail="${Font_Red}[Failed] ${2} ${Font_Suffix}"
      echo -e ${Msg_Fail}
    ;;
    *)
      Msg_Normal="--- $2 ---"
      echo -e ${Msg_Normal}
    ;;
  esac
}


# =============== -> 主程序开始 <- ==================
# 检测临时目录是否存在
if [ -d ${WorkDir} ];then
  
fi






