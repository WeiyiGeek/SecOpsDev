#!/bin/bash
#Desc: Gitlab代码服务器自动化部署
#Author:WeiyiGeek
#SupportOS:CentOS7 / CentOS8

GITLAB_BASEDOMAIN=weiyigeek.top
GITLAB_VERSION=12.9.2
GITlABOS7=gitlab-ce-${GITLAB_VERSION}-ce.0.el7.x86_64.rpm
GITlABOS8=gitlab-ce-${GITLAB_VERSION}-ce.0.el8.x86_64.rpm

GITLABRUNNER_VERSION=12.9.0-1
GITLABRUNNER_NAME=gitlab-runner-${GITLABRUNNER_VERSION}.x86_64.rpm	
CheckOSVersion=$(uname -r | grep -c el8)

## [镜像源设置]
function repoChange(){
  mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.$(date +"%Y%m%d").backup
  if [ $CheckOSVersion -eq 1 ];then
    # CentOS8 源
    curl -o /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-8.repo
    # 安装 epel 配置包并地址替换为阿里云镜像站地址
    dnf install -y https://mirrors.aliyun.com/epel/epel-release-latest-8.noarch.rpm
    sed -i 's|^#baseurl=https://download.fedoraproject.org/pub|baseurl=https://mirrors.aliyun.com|' /etc/yum.repos.d/epel*
    sed -i 's|^metalink|#metalink|' /etc/yum.repos.d/epel*
    dnf clean all
    dnf makecache
  else
    # CentOS7 源
    curl -o /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo
    sed -i -e '/mirrors.cloud.aliyuncs.com/d' -e '/mirrors.aliyuncs.com/d' /etc/yum.repos.d/CentOS-Base.repo
    wget -O /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo
#添加信任 GitLab 里的 GPG 公钥
sudo cat > /etc/yum.repos.d/gitlab-ce.repo <<EOF
[gitlab-ce]
name=Gitlab CE Repository
baseurl=https://mirrors.tuna.tsinghua.edu.cn/gitlab-ce/yum/el7/
gpgcheck=0
enabled=1
gpgkey=https://packages.gitlab.com/gpg.key
EOF
  yum clean all
  yum makecache
  fi
}

#[yum 方式安装]
function yumInstall(){
  # 查看可用的版本neng'b
  yum list gitlab-ce --showduplicates
  # 默认安装最新的版本
  yum install -y gitlab-ce
  # 安装指定版本 12.3.5
  # yum install gitlab-ce-12.3.5-ce.0.el7.x86_64.rpm
}


#[rpm 方式安装-推荐方式]
function OmnibusInstall(){
  if [ $CheckOSVersion -eq 1 ];then
    wget -O $GITlABOS8 https://mirrors.tuna.tsinghua.edu.cn/gitlab-ce/yum/el7/${GITlABOS8}
    rpm -i $GITlABOS8
  else
    wget -O $GITlABOS7 https://mirrors.tuna.tsinghua.edu.cn/gitlab-ce/yum/el7/${GITlABOS7}
    rpm -i  $GITlABOS7
  fi
}


function gitlabSetting(){
  sed -i "s#example.com#${GITLAB_BASEDOMAIN}#g" /etc/gitlab/gitlab.rb
  echo "127.0.0.1 gitlab.${GITLAB_BASEDOMAIN}" > /etc/hosts
}


function useage(){
  echo -e "\e[32m# Description: Gitlab 自动化安装部署脚本"
  echo -e "usage: $0 [rpm|yum] #指定rpm安装还是yum安装"
  echo -e "Author:WeiyiGeek\e[0m"
}

#[低于 12.3.x 版本的才进行设置]
function Chinesization(){
  #停止gitlab
  gitlab-ctl stop

  #获取当前安装的版本补丁
  git clone https://gitlab.com/xhang/gitlab.git
  cd gitlab
  gitlab_version=$(cat /opt/gitlab/embedded/service/gitlab-rails/VERSION)

  # 生成对应版本补丁文件
  git diff remotes/origin/12-3-stable remotes/origin/12-3-stable-zh > ../${gitlab_version}-zh.diff

  # 打补丁的时候会提示一些补丁文件不存在，一定要跳过这些文件，不然后面reconfig的时候会报错的。
  patch -d /opt/gitlab/embedded/service/gitlab-rails -p1 < ../${gitlab_version}-zh.diff
  gitlab-ctl reconfigure
  gitlab-ctl restart
}


## [安装配置脚本入口函数]
function main(){
  #关闭Sellinux
  echo "当前Selinux: $(getenforce)"
  setenforce 0
  sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
  echo "设置Selinux: $(getenforce)"

  #环境依赖安装
  repoChange
  sudo yum install -y curl policycoreutils openssh-server wget postfix git htop ncdu net-tools
  systemctl enable postfix
  systemctl start postfix

  #防护墙设置
  sudo firewall-cmd --permanent --add-service=http
  sudo firewall-cmd --permanent --add-service=https
  sudo systemctl reload firewalld

  #选择安装方式
  if [ $1 == "rpm" ];then
    OmnibusInstall
  elif [ $1 == "yum" ];then 
    yumInstall
  else
    usage
  fi

  gitlabSetting
  gitlab-ctl reconfigure
  gitlab-ctl start
  gitlab-ctl status
}

#[参数验证]
if [ $# -ne 1 ];then
  usage
else 
  main $1
fi