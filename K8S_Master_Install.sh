#!/bin/bash
# 2020-12-9 15:27:39
# 丁佑强
# 网络环境：手机热点（192.168.43.0），虚拟机桥接网卡安装K8S主节点脚本


# ---------------------------------------------
# yum安装一堆东西
yum -y install lrzsz wget vim net-tools ntpdate
# 同步时间
ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime; ntpdate ntp1.aliyun.com 
# 关防火墙
systemctl stop firewalld ; iptables -F ; setenforce 0

# ---------------------------------------------
# K8S 一些安装注意的点
IP=`ifconfig | grep broad | awk '{print $2}'`
echo "$IP `hostname`" >>/etc/hosts
swapoff -a ;  sed -i 's/.*swap.*/#&/' /etc/fstab
cat <<EOF >  /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sysctl --system
echo "1" >/proc/sys/net/bridge/bridge-nf-call-iptables
cat > /etc/sysctl.d/k8s.conf << EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sysctl --system
yum -y install yum-utils device-mapper-persistent-data lvm2   #一些依赖环境

# ---------------------------------------------
# Docker的安装
DOCKER_INSTALL () {
yum -y install createrepo
QINGHUA_DOCKER_REPO_SAVE_DIR=/root
QINGHUA_DOCKER_REPO='https://mirrors.tuna.tsinghua.edu.cn/docker-ce/linux/centos/7/x86_64/stable/repodata/repomd.xml'
cd  $QINGHUA_DOCKER_REPO_SAVE_DIR 
wget $QINGHUA_DOCKER_REPO 
createrepo ./
cat >> /etc/yum.repos.d/docker-rpm.repo <<EOF
[docker]
baseurl=file://$QINGHUA_DOCKER_REPO_SAVE_DIR/
enabled=1
gpgcheck=0
EOF
yum makecache && yum -y install docker
sudo mkdir -p /etc/docker
sudo tee /etc/docker/daemon.json <<-'EOF'
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "registry-mirrors": ["https://hdt4ge3h.mirror.aliyuncs.com"]
}
EOF
sudo systemctl daemon-reload
sudo systemctl restart docker
}
DOCKER_INSTALL  #安装docker，这里用的是自己做的脚本

# ---------------------------------------------
# 下载kubeadm等控制工具
cat >> /etc/yum.repos.d/kubernetes.repo <<EOF
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64/
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg
        https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF
yum makecache
yum -y install kubeadm-1.15.2  kubelet-1.15.2  kubectl-1.15.2  #这是客户端控制器
systemctl enable kubelet

# ---------------------------------------------
# K8S准备初始化
echo 'KUBELET_EXTRA_ARGS="--fail-swap-on=false"' > /etc/sysconfig/kubelet
kubeadm  init  --kubernetes-version=v1.15.2 \ 
--image-repository  registry.aliyuncs.com/google_containers \
--pod-network-cidr=10.244.0.0/16 \ 
--service-cidr=10.96.0.0/12 \ 
--ignore-preflight-errors=Swap 
HOME='/root/'
mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config

# ---------------------------------------------
# K8S下载一些组件
echo '151.101.108.133     raw.githubusercontent.com' >> /etc/hosts
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
