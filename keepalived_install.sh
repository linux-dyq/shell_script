#!/bin/bash
# 2020-12-21 11:06:58
# 安装keepalived并配置

# 输入要设置的VIP
read -p  "please enter the VIP: " VIP1

# 基本配置
systemctl stop firewalld; iptables -F ; setenforce 0 

# 安装keepalived
yum -y install keepalived

# 配置 keepalived
SERVER='test'     #监控服务的脚本以这个服务命名
ROUTER_ID='LVS_DEVEL'  #vrrp 用到的 router_id 标识
INTERFACE_NAME="`ifconfig | egrep '^e' | awk -F: '{print $1}'`"
cat  > /etc/keepalived/keepalived.conf <<EOF
! Configuration File for keepalived

global_defs {
   router_id $ROUTER_ID
}


vrrp_script  chk_$SERVER {            #这里指的是执行你检测的脚本会占用多少
  script "/data/sh/check_$SERVER\.sh"
  interval 2
  weight 2
}


vrrp_instance VI_1 {            #多个实例就是多个VIP
    state master
    interface $INTERFACE_NAME
    lvs_sync_daemon_interface $INTERFACE_NAME
    virtual_router_id 151
    priority 100
    advert_int 5
    nopreempt                #不抢占，这时候与 MASTER 、 BACKUP 无关
    authentication {
        auth_type PASS
        auth_pass 1111
    }
    virtual_ipaddress {
	$VIP1
    }
track_script {
    chk_$SERVER
}
}

EOF

# 尝试启动服务
systemctl start keepalived

# 生成调试脚本
mkdir -p /root/scripts ; cd  /root/scripts
cat >> kp_restart.sh <<EOF
PID=`ps -ef | grep -v grep | grep keepalived | awk '{print $2}'`
for i in $PID
do kill -9 $i
done
sleep 2
systemctl start keepalived && tail -f /var/log/messages
EOF
