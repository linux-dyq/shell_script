#!/bin/bash
# 2021-1-7 08:58:59
# author: 丁佑强
# 安装ansible
yum -y install epel-release
yum -y install ansible
ansible --version
# ansible -v  # 输出详细结果
# ansible -i PATH  #指定host文件的路径，默认 /etc/ansible/hosts
# ansible -f NUM   # NUM是指定一个整数，默认是5，指定fork开启同步进程的个数
# ansible -m NAME  # 指定使用的module名称
# ansible -a,MODULE_ARGS  # 指定module模块的参数
# ansible -k  # 提示输入ssh的密码，而不是使用基于ssh的密钥认证
# ansible -sudo # 指定使用sudo获得root权限
# ansible -K # 提示输入sudo密码
# ansible -u USERNAME   # 指定移动端执行用户
# ansible -C  # 测试此命令执行会改变什么内容，不会真正的去执行
ansible-doc  -l  #列出所有的模块列表
# ansible-doc -s 模块名 # 查看指定模块的参数
# ansible-doc -s service
IP=$(ifconfig | grep broadcast | awk '{print $2}')
cat >> /etc/ansible/hosts <<EOF
[web-servers]
ansible_ssh_host=$IP ansible_ssh_user="root" ansible_ssh_pass="123456" ansible_ssh_port=22
EOF
ansible -i /etc/ansible/hosts web-servers -m ping # -i指定host文件路径，-m指定使用的ping模块
ansible -m  command -a "uptime" 'web-servers'
ansible -m  command -a "uname -r" 'web-servers'
ansible -m  command -a "useradd thinkmo" 'web-servers'
ansible -m  command -a "grep thinkmo /etc/passwd"  'web-servers'
ansible -m  command -a "df -Th" 'web-servers' > /tmp/commd-output.txt ; cat /tmp/command-output.txt
ansible -i /etc/ansible/hosts web-servers -m shell -a "free -m"
ansible -i  /etc/ansible/hosts web-servers -m shell -a "source ~/.bash_profile && df -h | grep sda3"
cat > /etc/ansible/net.sh << EOF
#!/bin/bash
date
hostname
EOF
chmod +x /etc/ansible/net.sh
ansible -i /etc/ansible/hosts web-servers -m script -a "/etc/ansible/net.sh"
ansible -i /etc/ansible/hosts web-servers -m copy -a "src=/etc/hosts dest=/tmp/ owner=root group=root mode=0755"
ansible -i /etc/ansible/hosts web-servers -m file -a "path=/tmp/hosts mode=0777"
ansible -i /etc/ansible/hosts web-servers -m stat -a "path=/tmp/hosts"
ansible -i /etc/ansible/hosts web-servers -m get_url -a "url=https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm dest=/tmp/ mode=0440 force=yes"
ansible-doc -s get_url
ansible -i /etc/ansible/hosts web-servers -m get_url -a "url=https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm dest=/tmp/  mode=0440 force=yes"
ansible -i /etc/ansible/hosts web-servers -m yum -a "name=httpd state=latest"
ansible -i /etc/ansible/hsots web-servers -m cron -a "name='list dir' minute='*/30'  job='ls /tmp'"
ansible -i /etc/ansible/hosts web-servers -m service -a "name=httpd state=restarted"
ansible -i /etc/ansible/hosts web-servers -m sysctl -a "name=net.ipv4.ip_forward value=1 reload=yes"
ansible -i /etc/ansible/hosts web-servers -m user -a "name=thinkmo6 state=present"
