#!/bin/bash
## -----------------------------------  ##
## 离线安装 K8s yum仓库与k8s.gcr.io镜像 ##
## Author:WeiyiGeek                     ##
## Version: 1.0                         ##
## OS模板信息: Centos7-muban.ovf        ##
## ------------------------------------ ##

## 全局变量
export K8SVERSION="1.18.5"
export VERSION="19.03.9"
export REGISTRY_MIRROR="https://xlx9erfu.mirror.aliyuncs.com"

## 系统基础设置
hostnamectl set-hostname k8s-yum-server && echo "127.0.0.1 k8s-yum-server" >> /etc/hosts
setenforce 0 && getenforce && hostnamectl status

## 应用基础设置
yum install -y yum-cron

sed -i "s#keepcache=0#keepcache=1#g" /etc/yum.conf && echo -e "缓存目录:" && grep "cachedir" /etc/yum.conf 
sed -i "s#update_messages = yes#update_messages = no#g" /etc/yum/yum-cron.conf
sed -i "s#download_updates = yes#download_updates = no#g" /etc/yum/yum-cron.conf

systemctl enable yum-cron
systemctl restart yum-cron


# 安装基础依赖
yum install -y yum-utils lvm2 wget nfs-utils
# 添加 docker 镜像仓库
yum-config-manager --add-repo http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
cat <<'EOF' > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=http://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=0
repo_gpgcheck=0
gpgkey=http://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg
      http://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF


## 应用安装设置
# docker 安装
docker --version 
if [[ "$?" != 0 ]];then
  yum list docker-ce --showduplicates | sort -r
  yum install -y docker-ce-${VERSION} docker-ce-cli-${VERSION} containerd.io
else
  echo -e "#Docker 已经安装......."
fi

# docker 加速配置
if [[ ! -d "/etc/docker/" ]];then mkdir /etc/docker/;fi
cat > /etc/docker/daemon.json <<EOF
{"registry-mirrors": ["REPLACE"]}
EOF
sed -i "s#REPLACE#${REGISTRY_MIRROR}#g" /etc/docker/daemon.json

# kubernetes 安装
yum list kubeadm --showduplicates | sort -r
yum install -y kubelet-${K8SVERSION} kubeadm-${K8SVERSION} kubectl-${K8SVERSION} httpd createrepo
# 安装指定版本的 docker-ce 和 kubelet、kubeadm
# yum install docker-ce-19.03.3-3.el7 kubelet-1.17.4-0 kubeadm-1.17.4-0 kubectl-1.17.4-0 --disableexcludes=kubernetes
systemctl stop docker kubelet
systemctl start docker kubelet

## Docker下载K8s.gcr.io镜像
kubeadm config images list --kubernetes-version=${K8SVERSION} 2>/dev/null | sed 's/k8s.gcr.io/docker pull mirrorgcrio/g' | sudo sh
kubeadm config images list --kubernetes-version=${K8SVERSION} 2>/dev/null | sed 's/k8s.gcr.io\(.*\)/docker tag mirrorgcrio\1 k8s.gcr.io\1/g' | sudo sh
kubeadm config images list --kubernetes-version=${K8SVERSION} 2>/dev/null | sed 's/k8s.gcr.io/docker image rm mirrorgcrio/g' | sudo sh
docker save -o v${K8SVERSION}.tar $(docker images | grep -v TAG | cut -d ' ' -f1)
# 减少镜像打包后的体积
gzip v${K8SVERSION}.tar v${K8SVERSION}.tar.gz


## YUM本地仓库搭建 
mv /etc/httpd/conf.d/welcome.conf{,.bak} && mkdir /var/www/html/yum/
find /var/cache/yum -name *.rpm -exec cp -a {} /var/www/html/yum/ \;
# 权限非常重要否则后面httpd访问下载提示权限不足
cp v${K8SVERSION}.tar.gz /var/www/html/yum/ && chmod +644 /var/www/html/yum/v${K8SVERSION}.tar.gz
# 仓库软件索引生成以及更新指定仓库
createrepo -pdo /var/www/html/yum/ /var/www/html/yum/
createrepo --update /var/www/html/yum/


## 本地yum仓库端口开放设置
firewall-cmd --add-port=80/tcp --permanent
firewall-cmd --reload
systemctl start httpd


echo -e "\e[32m#应用机器执行以下命令即可完成k8s基础环境的依赖包下载\e[0m"
echo -e '
# 测试连接到本地搭建的yum仓库
echo "10.10.107.201 yum.weiyigeek.top" >> /etc/hosts
cat > /etc/yum.repos.d/localyumserver.repo <<END
[localyumserver]
name=localyumserver
baseurl=http://yum.weiyigeek.top/yum/
enabled=1
gpgcheck=0
END

yum --enablerepo=localyumserver --disablerepo=base,extras,updates,epel,elrepo,docker-ce-stable list 

export HOSTNAME=worker-03
# 临时关闭swap和SELinux
swapoff -a && setenforce 0
# 永久关闭swap和SELinux
yes | cp /etc/fstab /etc/fstab_bak
cat /etc/fstab_bak |grep -v swap > /etc/fstab
sed -i "s/^SELINUX=.*$/SELINUX=disabled/" /etc/selinux/config

# 主机名设置(这里主机名称安装上面的IP地址规划对应的主机名称-根据安装的主机进行变化)
hostnamectl set-hostname $HOSTNAME
hostnamectl status

# 主机名设置
echo "127.0.0.1 $HOSTNAME" >> /etc/hosts
cat >> /etc/hosts <<EOF
10.10.107.191 master-01
10.10.107.192 master-02
10.10.107.193 master-03
10.10.107.194 worker-01
10.10.107.196 worker-02
10.20.172.200 worker-03
EOF

# 修改 /etc/sysctl.conf 进行内核参数的配置
egrep -q "^(#)?net.ipv4.ip_forward.*" /etc/sysctl.conf && sed -ri "s|^(#)?net.ipv4.ip_forward.*|net.ipv4.ip_forward = 1|g"  /etc/sysctl.conf || echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
egrep -q "^(#)?net.bridge.bridge-nf-call-ip6tables.*" /etc/sysctl.conf && sed -ri "s|^(#)?net.bridge.bridge-nf-call-ip6tables.*|net.bridge.bridge-nf-call-ip6tables = 1|g" /etc/sysctl.conf || echo "net.bridge.bridge-nf-call-ip6tables = 1" >> /etc/sysctl.conf 
egrep -q "^(#)?net.bridge.bridge-nf-call-iptables.*" /etc/sysctl.conf && sed -ri "s|^(#)?net.bridge.bridge-nf-call-iptables.*|net.bridge.bridge-nf-call-iptables = 1|g" /etc/sysctl.conf || echo "net.bridge.bridge-nf-call-iptables = 1" >> /etc/sysctl.conf
egrep -q "^(#)?net.ipv6.conf.all.disable_ipv6.*" /etc/sysctl.conf && sed -ri "s|^(#)?net.ipv6.conf.all.disable_ipv6.*|net.ipv6.conf.all.disable_ipv6 = 1|g" /etc/sysctl.conf || echo "net.ipv6.conf.all.disable_ipv6 = 1" >> /etc/sysctl.conf
egrep -q "^(#)?net.ipv6.conf.default.disable_ipv6.*" /etc/sysctl.conf && sed -ri "s|^(#)?net.ipv6.conf.default.disable_ipv6.*|net.ipv6.conf.default.disable_ipv6 = 1|g" /etc/sysctl.conf || echo "net.ipv6.conf.default.disable_ipv6 = 1" >> /etc/sysctl.conf
egrep -q "^(#)?net.ipv6.conf.lo.disable_ipv6.*" /etc/sysctl.conf && sed -ri "s|^(#)?net.ipv6.conf.lo.disable_ipv6.*|net.ipv6.conf.lo.disable_ipv6 = 1|g" /etc/sysctl.conf || echo "net.ipv6.conf.lo.disable_ipv6 = 1" >> /etc/sysctl.conf
egrep -q "^(#)?net.ipv6.conf.all.forwarding.*" /etc/sysctl.conf && sed -ri "s|^(#)?net.ipv6.conf.all.forwarding.*|net.ipv6.conf.all.forwarding = 1|g"  /etc/sysctl.conf || echo "net.ipv6.conf.all.forwarding = 1"  >> /etc/sysctl.conf
# 使修改的内核参数立即生效
sysctl -p

# 镜像加速
export REGISTRY_MIRROR="https://xlx9erfu.mirror.aliyuncs.com"
if [[ ! -d "/etc/docker/" ]];then mkdir /etc/docker/;fi
cat > /etc/docker/daemon.json <<EOF
{"registry-mirrors": ["REPLACE"]}
EOF
sed -i "s#REPLACE#${REGISTRY_MIRROR}#g" /etc/docker/daemon.json

# 利用内部yum源进行Kuberntes环境安装
yum install -y --enablerepo=localyumserver --disablerepo=base,extras,updates,epel,elrepo,docker-ce-stable kubelet kubeadm kubectl
sed -i "s#^ExecStart=/usr/bin/dockerd.*#ExecStart=/usr/bin/dockerd -H fd:// --containerd=/run/containerd/containerd.sock --exec-opt native.cgroupdriver=systemd#g" /usr/lib/systemd/system/docker.service
# 重启 docker，并启动 kubelet
systemctl daemon-reload && systemctl enable kubelet
systemctl restart docker kubelet

# 导入k8s.gcr.io镜像到本地机器中
wget -c http://10.10.107.201/yum/v${K8SVERSION}.tar.gz 
gzip -dv v${K8SVERSION}.tar.gz && docker load < v${K8SVERSION}.tar

# 主Master节点运行获得节点加入凭据
[root@master-01 ~]$kubeadm token create --print-join-command 2>/dev/null

# 工作节点执行加入到k8s的cluster中
APISERVER_IP=10.10.107.191
APISERVER_NAME=k8s.weiyigeek.top
echo "${APISERVER_IP} ${APISERVER_NAME}" >> /etc/hosts
[root@worker-03 ~]$kubeadm join k8s.weiyigeek.top:6443 
'