#!/bin/bash
# 2020-12-21 15:53:29

HOST_CONFIG () {
# ----------本地解析主机名------------------
read -p "enter hostname: " NAME
IP=`ifconfig | grep broad | awk '{print $2}'`
hostnamectl set-hostname $NAME ; echo "$IP `hostname`" >> /etc/hosts

# -----------Host 文件--------------------
K8S_HOST1='master1'
K8S_IP1='192.168.2.132'
K8S_HOST2='master2'
K8S_IP2='192.168.2.133'
NODE_HOST1='node1'
NODE_IP1='192.168.2.134'
NODE_HOST2=''
NODE_IP2=''
echo "$K8S_IP1 $K8S_HOST1" >> /etc/hosts
echo "$K8S_IP2 $K8S_HOST2" >> /etc/hosts
echo "$NODE_IP1 $NODE__HOST1" >> /etc/hosts
echo "$NODE_IP2 $NODE__HOST2" >> /etc/hosts

# ----------SSH创建密钥------------------
ssh-keygen -t rsa
ssh-copy-id root@$K8S_IP1
ssh-copy-id root@$K8S_IP2
ssh-copy-id root@$NODE1_IP2
ssh-copy-id root@$NODE2_IP2
}

K8S_ATTENTION () {
# ------------K8S安装注意事项--------------
swapoff -a ; sed -i.bak '/swap/s/^/#/' /etc/fstab
cat > /etc/rc.sysinit << EOF
#!/bin/bash
for file in /etc/sysconfig/modules/*.modules ; do
[ -x $file ] && $file
done
EOF
cat > /etc/sysconfig/modules/br_netfilter.modules << EOF
modprobe br_netfilter
EOF
chmod 755 /etc/sysconfig/modules/br_netfilter.modules
cat <<EOF >  /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sysctl -p /etc/sysctl.d/k8s.conf
}

K8S_YUM_REPO () {
# ---------------K8S 的yum源-----------------
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64/
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF
yum clean all ; yum -y makecache
}

DOCKER_INSTALL () {
# --------------Docker 18.09.0 安装-----------
yum install -y yum-utils   device-mapper-persistent-data   lvm2
yum-config-manager --add-repo https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
yum install docker-ce-18.09.9 docker-ce-cli-18.09.9 containerd.io -y
yum -y install bash-completion
source /etc/profile.d/bash_completion.sh 2>/dev/null #!!!!!!!!!!!!!
sudo mkdir -p /etc/docker
sudo tee /etc/docker/daemon.json <<-'EOF'
{
  "registry-mirrors": ["https://hdt4ge3h.mirror.aliyuncs.com"],
  "exec-opts": ["native.cgroupdriver=systemd"]
}
EOF
systemctl daemon-reload
systemctl start docker
systemctl restart docker
systemctl enable docker
}

K8S_INSTALL() {
# ---------------------K8S 1.16.4 安装--------------
yum install -y kubelet-1.16.4 kubeadm-1.16.4 kubectl-1.16.4
systemctl enable kubelet && systemctl start kubelet
echo "source <(kubectl completion bash)" >> ~/.bash_profile 2>/dev/null
source .bash_profile  2>/dev/null
cat > image.sh <<EOF
#!/bin/bash
url=registry.cn-hangzhou.aliyuncs.com/loong576
version=v1.16.4
images=(\`kubeadm config images list --kubernetes-version=\$version|awk -F '/' '{print \$2}'\`)
for imagename in \${images[@]} ; do
  docker pull \$url/\$imagename
  docker tag \$url/\$imagename k8s.gcr.io/\$imagename
  docker rmi -f \$url/\$imagename
done
EOF
sh image.sh

}

K8S_MULTI_MASTER () {
read -p 'please enter the Virtual IP: ' VIP1
sh image.sh
K8S_HOST1='master1'
K8S_IP1='192.168.2.132'
K8S_HOST2='master2'
K8S_IP2='192.168.2.133'
cat > kubeadm-config.yaml <<EOF
apiVersion: kubeadm.k8s.io/v1beta2
kind: ClusterConfiguration
kubernetesVersion: v1.16.4
apiServer:
  certSANs:  
  - $K8S_HOST1
  - $K8S_HOST2
  - $K8S_IP1
  - $K8S_IP2
controlPlaneEndpoint: "$VIP1:6443"
networking:
  podSubnet: "10.244.0.0/16"
EOF
kubeadm init --config=kubeadm-config.yaml 1>>join.txt
sleep 2
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
}

FLANNEL () {
cat > kube-flannel.yml <<EOF
---
apiVersion: policy/v1beta1
kind: PodSecurityPolicy
metadata:
  name: psp.flannel.unprivileged
  annotations:
    seccomp.security.alpha.kubernetes.io/allowedProfileNames: docker/default
    seccomp.security.alpha.kubernetes.io/defaultProfileName: docker/default
    apparmor.security.beta.kubernetes.io/allowedProfileNames: runtime/default
    apparmor.security.beta.kubernetes.io/defaultProfileName: runtime/default
spec:
  privileged: false
  volumes:
  - configMap
  - secret
  - emptyDir
  - hostPath
  allowedHostPaths:
  - pathPrefix: "/etc/cni/net.d"
  - pathPrefix: "/etc/kube-flannel"
  - pathPrefix: "/run/flannel"
  readOnlyRootFilesystem: false
  # Users and groups
  runAsUser:
    rule: RunAsAny
  supplementalGroups:
    rule: RunAsAny
  fsGroup:
    rule: RunAsAny
  # Privilege Escalation
  allowPrivilegeEscalation: false
  defaultAllowPrivilegeEscalation: false
  # Capabilities
  allowedCapabilities: ['NET_ADMIN', 'NET_RAW']
  defaultAddCapabilities: []
  requiredDropCapabilities: []
  # Host namespaces
  hostPID: false
  hostIPC: false
  hostNetwork: true
  hostPorts:
  - min: 0
    max: 65535
  # SELinux
  seLinux:
    # SELinux is unused in CaaSP
    rule: 'RunAsAny'
---
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: flannel
rules:
- apiGroups: ['extensions']
  resources: ['podsecuritypolicies']
  verbs: ['use']
  resourceNames: ['psp.flannel.unprivileged']
- apiGroups:
  - ""
  resources:
  - pods
  verbs:
  - get
- apiGroups:
  - ""
  resources:
  - nodes
  verbs:
  - list
  - watch
- apiGroups:
  - ""
  resources:
  - nodes/status
  verbs:
  - patch
---
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: flannel
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: flannel
subjects:
- kind: ServiceAccount
  name: flannel
  namespace: kube-system
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: flannel
  namespace: kube-system
---
kind: ConfigMap
apiVersion: v1
metadata:
  name: kube-flannel-cfg
  namespace: kube-system
  labels:
    tier: node
    app: flannel
data:
  cni-conf.json: |
    {
      "name": "cbr0",
      "cniVersion": "0.3.1",
      "plugins": [
        {
          "type": "flannel",
          "delegate": {
            "hairpinMode": true,
            "isDefaultGateway": true
          }
        },
        {
          "type": "portmap",
          "capabilities": {
            "portMappings": true
          }
        }
      ]
    }
  net-conf.json: |
    {
      "Network": "10.244.0.0/16",
      "Backend": {
        "Type": "vxlan"
      }
    }
---
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: kube-flannel-ds
  namespace: kube-system
  labels:
    tier: node
    app: flannel
spec:
  selector:
    matchLabels:
      app: flannel
  template:
    metadata:
      labels:
        tier: node
        app: flannel
    spec:
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchExpressions:
              - key: kubernetes.io/os
                operator: In
                values:
                - linux
      hostNetwork: true
      priorityClassName: system-node-critical
      tolerations:
      - operator: Exists
        effect: NoSchedule
      serviceAccountName: flannel
      initContainers:
      - name: install-cni
        image: quay.io/coreos/flannel:v0.13.1-rc1
        command:
        - cp
        args:
        - -f
        - /etc/kube-flannel/cni-conf.json
        - /etc/cni/net.d/10-flannel.conflist
        volumeMounts:
        - name: cni
          mountPath: /etc/cni/net.d
        - name: flannel-cfg
          mountPath: /etc/kube-flannel/
      containers:
      - name: kube-flannel
        image: quay.io/coreos/flannel:v0.13.1-rc1
        command:
        - /opt/bin/flanneld
        args:
        - --ip-masq
        - --kube-subnet-mgr
        resources:
          requests:
            cpu: "100m"
            memory: "50Mi"
          limits:
            cpu: "100m"
            memory: "50Mi"
        securityContext:
          privileged: false
          capabilities:
            add: ["NET_ADMIN", "NET_RAW"]
        env:
        - name: POD_NAME
          valueFrom:
            fieldRef:
              fieldPath: metadata.name
        - name: POD_NAMESPACE
          valueFrom:
            fieldRef:
              fieldPath: metadata.namespace
        volumeMounts:
        - name: run
          mountPath: /run/flannel
        - name: flannel-cfg
          mountPath: /etc/kube-flannel/
      volumes:
      - name: run
        hostPath:
          path: /run/flannel
      - name: cni
        hostPath:
          path: /etc/cni/net.d
      - name: flannel-cfg
        configMap:
          name: kube-flannel-cfg

EOF
kubectl apply -f kube-flannel.yml
}

SEND_CRT () {
# 避免传给自己
K8S_IP2='192.168.2.133'
ssh root@K8S_IP2 "mkdir -p /etc/kubernetes/pki/etcd"
cat > cert-main-master.sh <<EOF
USER=root # customizable
CONTROL_PLANE_IPS="$K8S_IP2"
for host in \${CONTROL_PLANE_IPS}; do
    scp /etc/kubernetes/pki/ca.crt "\${USER}"@\$host:/etc/kubernetes/pki/
    scp /etc/kubernetes/pki/ca.key "\${USER}"@\$host:/etc/kubernetes/pki/
    scp /etc/kubernetes/pki/sa.key "\${USER}"@\$host:/etc/kubernetes/pki/
    scp /etc/kubernetes/pki/sa.pub "\${USER}"@\$host:/etc/kubernetes/pki/
    scp /etc/kubernetes/pki/front-proxy-ca.crt "\${USER}"@\$host:/etc/kubernetes/pki/
    scp /etc/kubernetes/pki/front-proxy-ca.key "\${USER}"@\$host:/etc/kubernetes/pki/
    scp /etc/kubernetes/pki/etcd/ca.crt "\${USER}"@\$host:/etc/kubernetes/pki/etcd/ca.crt
    # Quote this line if you are using external etcd
    scp /etc/kubernetes/pki/etcd/ca.key "\${USER}"@\$host:/etc/kubernetes/pki/etcd/ca.key
done
EOF
sh  cert-main-master.sh
}

MASTER2_JOIN(){
TOKEN="`kubeadm token create`"
TOKEN_HASH="`openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | openssl dgst -sha256 -hex | sed 's/^.* //'`"
ssh root@$K8S_IP2 "kubeadm join $VIP1:6443  --token $TOKEN  --discovery-token-ca-cert-hash sha256:$TOKEN_HASH --control-plane"
mkdir -p /root/.kube
sudo cp -i /etc/kubernetes/admin.conf /root/.kube/config
sudo chown root:root /root/.kube/config

}

NODE_JOIN () {
TOKEN="`kubeadm token create`"
TOKEN_HASH="`openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | openssl dgst -sha256 -hex | sed 's/^.* //'`"
ssh root@$NODE_HOST1 "kubeadm join $VIP1:6443  --token $TOKEN  --discovery-token-ca-cert-hash sha256:$TOKEN_HASH "
ssh root@$NODE_HOST2 "kubeadm join $VIP1:6443  --token $TOKEN  --discovery-token-ca-cert-hash sha256:$TOKEN_HASH "
}

MAIN () {
HOST_CONFIG
K8S_ATTENTION
K8S_YUM_REPO
DOCKER_INSTALL
K8S_INSTALL
K8S_MULTI_MASTER
FLANNEL
SEND_CRT
MASTER2_JOIN
NODE_JOIN
}
MAIN
