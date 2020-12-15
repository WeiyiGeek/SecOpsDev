
#!/bin/bash
# Description:查看Registry仓库中的镜像信息并从仓库中删除指定镜像，然后进行垃圾回收
# Author:WeiyiGeek
# createTime:2020年8月23日 16:55:57

set -x

# [+ Defined]
PARM=$1
IMAGE_NAME=${2}
ACTION=${PARM:="NONE"}

REGISTRY_URL="https://localhost/v2"
REGISTRY_NAME="registry"
REGISTRY_HOME="/var/lib/registry/docker/registry/v2"
MANIFESTS_DIGEST=""
AUTH="Authorization: Basic d2VpeWlnZWVrOjEyMzQ1Ng=="

function Usage(){
  echo -e "\e[32m#查看Registry仓库中的镜像信息并从仓库中删除指定镜像，然后进行垃圾回收 \e[0m"
  echo -e "\e[32mUsage: $0 {view} \e[0m"
  echo -e "\e[32m       $0 {tags} <image-name> \e[0m"
  echo -e "\e[32m       $0 {gc} <registry-container-name|container-id> \e[0m"
  echo -e "\e[32m       $0 {delete} <image-name> <reference> \e[0m"

  exit;
}

# [+ 显示仓库中的镜像]
function ViewRegistry(){
  curl -s -H "${AUTH}" "${REGISTRY_URL}/_catalog" | jq ".repositories"
}

# [+ 显示仓库中镜像标记]
function ViewTags(){
  local FLAG=0
  local IMAGE_NAME=$1
  curl -s -H "${AUTH}" "${REGISTRY_URL}/_catalog" | jq ".repositories" > registry.repo
  sed -i "s#\[##g;s#]##g;s# ##g;s#\"##g;s#,##g;/^\s*$/d" registry.repo
  
  for i in $(cat registry.repo)
  do
    if [[ "$i" == "${IMAGE_NAME}" ]];then
      FLAG=1
      break
    fi
  done

  if [[ $FLAG -eq 1 ]];then
    curl -s -H "${AUTH}" "${REGISTRY_URL}/${IMAGE_NAME}/tags/list" | jq ".tags"
  else
    echo -e "\e[31m[ERROR]: Registry 不存在 ${IMAGE_NAME} 该镜像\e[0m"
    exit
  fi
}

# [+ 仓库废弃镜像回收] 
function GcRegistry(){
  docker exec -it $1 sh -c "/bin/registry garbage-collect -m --delete-untagged=true /etc/docker/registry/config.yml"
  if [[ $? -ne 0 ]];then
    echo -e "\e[31m[ERROR]:GC Failed! \e[0m"
    exit
  fi

  # 删除 blobs/sha256中的空目录
  for i in $(find ${REGISTRY_HOME}/blobs/sha256/ | grep -v "data");do 
    if [[ $(ls -A $i|wc -c) -eq 0 ]];then 
      echo -e "[info]delete empty directory : ${i}"
      rm -rf ${i}
    fi
  done

  echo -e "[+ Registry restart ....]"
  docker restart $1
}


# [+ 删除仓库中的镜像]
function Del() {
  local IMAGE_NAME=$1
  local TAGS=$2

  if [[ "$TAGS" != "" ]];then
    # 验证删除的镜像是否存在
    curl -s -H "${AUTH}" -H 'Accept: application/vnd.docker.distribution.manifest.v2+json' "${REGISTRY_URL}/${IMAGE_NAME}/manifests/${TAGS}" > images.mainfests
    
    err_flag=$(grep -c '"errors"' images.mainfests)
    if [[ $err_flag -ne 0 ]];then
      echo -e "\e[31m[ERROR]:$(cat images.mainfests) \e[0m"
      exit
    fi

    # 获取要删除镜像的digest摘要
    MANIFESTS_DIGEST=$(curl -s -H "${AUTH}" -H 'Accept: application/vnd.docker.distribution.manifest.v2+json' "${REGISTRY_URL}/${IMAGE_NAME}/manifests/${TAGS}" | grep "Docker-Content-Digest:" | cut -f 2 -d " ")

    grep "digest" images.mainfests | sed 's# ##g;s#"##g;s#digest:##g' > images.digest
    echo ${MANIFESTS_DIGEST} >> images.digest

    # 删除 镜像 _Manifests目录中的Tags相关目录
    curl -v -H "${AUTH}" -H 'Accept: application/vnd.docker.distribution.manifest.v2+json' -X DELETE "${REGISTRY_URL}/${IMAGE_NAME}/manifests/${MANIFESTS_DIGEST}"
    
    # 删除 镜像 _Layer 目录下的link
    for digest in $(cat images.digest);do
      curl -v -H "${AUTH}" -X DELETE "${REGISTRY_URL}/${IMAGE_NAME}/blobs/${digest}"
    done
  fi

  # GC 回收(注意参数为容器镜像名称)
  GcRegistry ${REGISTRY_NAME}

  # 判断 镜像 是否存在其它 tags 不存在时候直接删除其目录
  $flag_tags=$(curl -s -H "${AUTH}" "${REGISTRY_URL}/${IMAGE_NAME}/tags/list" | jq ".tags") 
  if [[ -z $flag_tags ]];then
    rm -rf "${REGISTRY_HOME}/repositories/${IMAGE_NAME}"
  fi
  # 删除 _layers 目录下的digest文件空的目录
  for i in $(find ${REGISTRY_HOME}/repositories/${IMAGE_NAME}/_layers/sha256/ | grep -v "link");do 
      if [[ $(ls -A $i|wc -c) -eq 0 ]];then 
        echo -e "[info]delete empty directory : ${i}"
        rm -rf ${i}
      fi
  done

  # 删除 manifests 目录下的digest文件空的目录
  for i in $(find ${REGISTRY_HOME}/repositories/${IMAGE_NAME}/_manifests/revisions/sha256/ | grep -v "link");do 
      if [[ $(ls -A $i|wc -c) -eq 0 ]];then 
        echo -e "[info]delete empty directory : ${i}"
        rm -rf ${i}
      fi
  done
}


# [Main]
if [[ "$ACTION" = "NONE" ]];then
  Usage
elif [[ "$ACTION" = "view" ]];then
  ViewRegistry
elif  [[ "$ACTION" = "tags" ]];then
  ViewTags $2
elif  [[ "$ACTION" = "delete" ]];then
  Del $2 $3
elif  [[ "$ACTION" = "gc" ]];then
  GcRegistry $2
else
  Usage
fi
