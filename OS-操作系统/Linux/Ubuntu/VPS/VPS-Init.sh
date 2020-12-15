#!/bin/bash
##
## Desc: Ubuntu-VPS服务器初始化常用脚本
## Author: WeiyiGeek
## Time: 2020年7月22日 22:59:19

set -xue

## 镜像源&软件
# apt-get update
# 编译依赖
apt install -y gcc gcc-c++ openssl-devel bzip2-devel
# 常规软件
apt install -y nano vim git unzip wget ntpdate dos2unix
apt install -y net-tools tree htop ncdu nload sysstat psmisc bash-completion fail2ban
apt install -y curl apt-transport-https

# 主题
curl  https://get.acme.sh | sh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="bira"/g' ~/.zshrc

# jsDelivr CDN
#GitHub rul: https://github.com/ohmyzsh/ohmyzsh/blob/master/tools/install.sh
#jsDelivr url: https://cdn.jsdelivr.net/gh/ohmyzsh/ohmyzsh/tools/install.sh

wget $(echo $1 | sed 's/raw.githubusercontent.com/cdn.jsdelivr.net\/gh/' \
                | sed 's/github.com/cdn.jsdelivr.net\/gh/' \
                | sed 's/\/master//' | sed 's/\/blob//' )

curl $(echo $1 | sed 's/raw.githubusercontent.com/cdn.jsdelivr.net\/gh/' \
                | sed 's/github.com/cdn.jsdelivr.net\/gh/' \
                | sed 's/\/master//' | sed 's/\/blob//' )

# kubeadm pull images
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF
apt-get update

for version in 1.17.5
do
    apt purge -y kubeadm kubelet kubectl
    apt install -y kubeadm=${version}-00 kubelet=${version}-00 kubectl=${version}-00
    mkdir -p ${version}/bin
    rm -rf ${version}/bin/*
    cp -a $(whereis kubelet | awk -F ":" '{print $2}') ${version}/bin/
    cp -a $(whereis kubeadm | awk -F ":" '{print $2}') ${version}/bin/
    cp -a $(whereis kubectl | awk -F ":" '{print $2}') ${version}/bin/
    kubeadm config images pull --kubernetes-version=${version}
    docker save -o kubeadm_v${version}.tar `kubeadm config images list --kubernetes-version=${version}`
    mv kubeadm_v${version}.tar ${version}
    tar -czvf ${version}{.tar.gz,}
done

#ss-obfs
apt-get -y install shadowsocks-libev simple-obfs rng-tools
rngd -r /dev/urandom
mkdir -p /etc/shadowsocks-libev/

cat > /etc/shadowsocks-libev/config.json <<EOF
{
    "server":"0.0.0.0",
    "server_port":8964,
    "local_port":1080,
    "password":"1984fuckGFW",
    "timeout":60,
    "method":"chacha20",
    "plugin":"obfs-server",
    "plugin_opts":"obfs=http"
}
EOF
systemctl restart shadowsocks-libev.service
modprobe tcp_bbr
echo "tcp_bbr" >> /etc/modules-load.d/modules.conf
echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
sysctl -p
sysctl net.ipv4.tcp_available_congestion_control
sysctl net.ipv4.tcp_congestion_control
touch /etc/sysctl.d/local.conf
echo "net.core.wmem_max = 67108864" >>/etc/sysctl.d/local.conf
echo "net.core.rmem_default = 65536" >>/etc/sysctl.d/local.conf
echo "net.core.wmem_default = 65536" >>/etc/sysctl.d/local.conf
echo "net.core.netdev_max_backlog = 4096" >>/etc/sysctl.d/local.conf
echo "net.core.somaxconn = 4096" >>/etc/sysctl.d/local.conf
echo "net.ipv4.tcp_syncookies = 1" >>/etc/sysctl.d/local.conf
echo "net.ipv4.tcp_tw_reuse = 1" >>/etc/sysctl.d/local.conf
echo "net.ipv4.tcp_tw_recycle = 0" >>/etc/sysctl.d/local.conf
echo "net.ipv4.tcp_fin_timeout = 30" >>/etc/sysctl.d/local.conf
echo "net.ipv4.tcp_keepalive_time = 1200" >>/etc/sysctl.d/local.conf
echo "net.ipv4.ip_local_port_range = 10000 65000" >>/etc/sysctl.d/local.conf
echo "net.ipv4.tcp_max_syn_backlog = 4096" >>/etc/sysctl.d/local.conf
echo "net.ipv4.tcp_max_tw_buckets = 5000" >>/etc/sysctl.d/local.conf
echo "net.ipv4.tcp_fastopen = 3" >>/etc/sysctl.d/local.conf
echo "net.ipv4.tcp_rmem = 4096 87380 67108864" >>/etc/sysctl.d/local.conf
echo "net.ipv4.tcp_wmem = 4096 65536 67108864" >>/etc/sysctl.d/local.conf
echo "net.ipv4.tcp_mtu_probing = 1" >>/etc/sysctl.d/local.conf
sysctl --system
lsmod | grep bbr



##将该脚放到 UWP 客户端下载缓存主目录下执行，安装 ffmpeg、jq
set -xu
download_dir=$(pwd)
mp4_dir=${download_dir}/mp4
mkdir -p ${mp4_dir}

for video_dir in $(ls | sort -n | grep -E -v "\.|mp4")
do
  cd ${download_dir}/${video_dir}
  up_name=$(jq ".Uploader" *.dvi | tr -d "[:punct:]\040\011\012\015")
  mkdir -p ${mp4_dir}/${up_name}
  for p_dir in $(ls | sort -n | grep -v "\.")
  do
    cd ${download_dir}/${video_dir}/${p_dir}
    video_name=$(jq ".Title" *.info | tr -d "[:punct:]\040\011\012\015")
    part_name=$(jq ".PartName" *.info | tr -d "[:punct:]\040\011\012\015")
    upload_time=$(grep -Eo "20[0-9][0-9]-[0-9][0-9]-[0-9][0-9]" *.info)
    Uploader=$(jq ".Uploader" *.info | tr -d "[:punct:]\040\011\012\015")
    mp4_audio=$(jq ".VideoDashInfo" *.info | tr -d "[:punct:]\040\011\012\015")

    if [ "null" = "${part_name}" ];then
    mp4_file_name=${video_name}.mp4
    else
    mp4_file_name=${video_name}_${p_dir}_${part_name}.mp4
    fi

    if [ "null" = "${mp4_audio}" ];then
    ls *.flv | sort -n > ff.txt
    sed -i 's/^/file /g' ff.txt
    ffmpeg -f concat -i ff.txt -c copy ${mp4_dir}/${up_name}/"${mp4_file_name}";rm -rf ff.txt
    else
    ffmpeg  -i video.mp4 -i audio1.mp4 -c:v copy -c:a copy ${mp4_dir}/${up_name}/"${mp4_file_name}"
    fi
    cd ${download_dir}/${video_dir}
  cd ${download_dir}
  done

 如果需要保留原视频请注释掉下面这一行

rm -rf ${download_dir}/${video_dir}
done