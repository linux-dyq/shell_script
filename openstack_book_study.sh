#!/bin/bash
# 2021-1-26 15:57:55
# 学习openstack书
RPM_COMPONENT(){
openstack-keystone-2012.2.4-5.el6.noarch.rpm
/etc/keystone
/etc/keystone/default_catalog.templates
/etc/keystone/keystone.conf
/etc/keystone/logging.conf
/etc/keystone/plolicy.json
/etc/logrotate.d/openstack-keystone
/etc/rc.d/init.d/openstack-keystone
/usr/bin/keystone-all
/usr/bin/keystone-manage
/usr/bin/openstack-keystone-sample-date
/usr/share/doc/openstack-keystone-2012.2.4
/usr/share/doc/openstack-keystone-2012.2.4/LICENSE
/usr/share/doc/openstack-keystone-2012.2.4/README.rst
/usr/share/man/man1/keystone-all.1.gz
/usr/share/man/man1/keystone-manage.1.gz
/usr/share/openstack-keystone/
/usr/share/openstack-keystone/openstack-keystone.upstart
/usr/share/openstack-keystone/sample_data.sh
/var/lib/keystone
/var/log/keystone
/var/run/keystone
openstack-keystone-2012.2.4-5.el6.noarch.rpm
}

RPM_YUM_MANAGE(){
yum -y install yum-download
yum update httpd -y -downloadonly
yum update httpd -y -downloadonly -downloaddir=/opt
yum -y install yum-utils
yumdownloader httpd
sed -i "s/keepcache=0/keepcache=1/g" /etc/yum.conf
/etc/init.d/yum-updatesd restart
yum install httpd
cat /etc/yum.conf | grep cachedir
cd /var/cache/yum && tree ./
}

INSTALL_COMPONENT(){
cd /root/source/ && mkdir os
mount -o loop RHEL-6.3-x86_64-bin-DVD1.sio  /root/source/os
yum -y install mysql mysql-server MySQL-python
chkconfig --level 2345 mysqld on
service mysqld start
RABBIT_MQ_INSTALL(){
    yum -y install tk
    yum -y install mysql-connector-odbc
    rpm -ivh  rpm-dependency-for-RabbitMQ-OS-RHEL/*.rpm
    rpm --import http://www.rabbitmq.com/rabbitmq-signing-key-public.asc
    rpm -ivh rabbitmq-server-3.0.3-1.noarch.rpm
    chkconfig rabbitmq-server on && service rabbitmq-server start
  }
KEYSTONE_INSTALL(){
  #下面的安装应该是有依赖关系
  cd ~/packages/openstack
  rpm -ivh openstack-utils-2013.1-1.el6.noarch.rpm
  yum -y install python-paste python-decorator python-sqlalchemy python-tempita
  cd ~/packages/openstack/rpm-dependency-for-keystone-OS-RHEL
  rpm -ivh *.rpm
  yum -y install pyPAM python-memcached
  cd ~/packages/openstack/python
  rpm -ivh python-keystone-2012.2.1-1.el6.noarch.rpm
  python-keystone-2012.2.1-1.el6.noarch.rpm
  python-keystoneclient-0.1.3.27-1.el6.noarch.rpm
  cd ~/packages/openstack
  rpm -ivh openstack-keystone-2012.2.1-1.el6.noarch.rpm
  #初始化数据库
  openstack-db --service keystone --init -r 
  openstack-config --set /etc/keystone/keystone.conf DEFAULT admin_token ADMIN
  service openstack-keystone start && chkconfig openstack-keystone on 
  keystone-manage db_sync
  service openstack-keystone restart
}
SOME_CONFIG(){
[sql]
connection = mysql://keystone:keystone@localhost/keystone
[identity]
driver = keystone.identity.backends.sql.Identity

SERVICE_TENANT=$(get_id keystone tenant-create --name=service --description "Service Tenant")
GLANCE_USER=$(get_id keystone user-create --name=glance --pass=****)
keystone user-role-add --user-id $GLANCE_USER --role-id $ADMIN_ROLE --tenant-id $SERVICE_TENANT
NOVA_USER=$(get_id keystone user-create --name=nova --pass=Passw0rd --tenant-id $SERVICE_TENANT)
keystone user-role-add --user-id $NOVA_USER --role-id $ADMIN_ROLE --tenant-id $SERVICE_TENANT

KEYSTONE_SERVICE=$(get_id keystone service-create --name=keystone --type=identity --description="Keystone Identity Service")
if [[ -z "$DISABLE_ENDPOINTS" ]];then
keystone endpoint-create --region RegionOne --service-id $KEYSTONE_SERVICE --publicurl "http://NC_IP:5000/v2.0"  --adminurl "http://NC_IP:35357/v2.0" --internalurl "http://NC_IP:5000/v2.0
fi
}

}























