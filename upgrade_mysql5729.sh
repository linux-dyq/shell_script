#!/bin/bash
# 升级mysql小版本过程
SMALL_VERSION='5.7.29'
BIG_VERSION='5.7.31'
# ------------------------------------
cd  /root/
tar -zxvf mysql-$BIG_VERSION-linux-glibc2.12-x86_64.tar -C /opt/
mv  /opt/mysql-$BIG_VERSION-linux-glibc2.12-x86_64  /opt/mysql$BIG_VERSION
chown -R mysql:mysql mysql$BIG_VERSION
# ------------------------------------
#sudo service tomcat_8023_web stop
#sudo service tomcat_8013_web stop
# ------------------------------------
OLD_MYSQL_BASEDIR='/usr/local/mysql'
OLD_MYSQL_DATADIR='/usr/local/mysql/data'
MYSQL_SOCK='/tmp/mysql.sock'
$OLD_MYSQL_BASEDIR/bin/mysqladmin -uroot -S $MYSQL_SOCK shutdown
# ------------------------------------
BACK_DATA_DIR='/opt/backup'
mkdir -p $BACK_DATA_DIR
cp -pr  $OLD_MYSQL_BASEDIR  $BACK_DATA_DIR
# ------------------------------------
cd  /opt/mysql$BIG_VERSION && mkdir etc
cp  /etc/my.cnf  /opt/mysql$BIG_VERSION/etc/
cd  bin
./mysqld_safe  --defaults-file=../etc/my.cnf --datadir=$OLD_MYSQL_DATADIR --basedir=/opt/mysql$BIG_VERSION --user=root & 
./mysql_upgrade  -uroot -s --socket=/tmp/mysql.sock
PID=`ps -ef | grep -v upgrade | grep -v grep | grep mysql`
for i in $PID
do kill -9 $PID
done
./mysqld_safe  --defaults-file=../etc/my.cnf --datadir=$OLD_MYSQL_DATADIR --basedir=/opt/mysql$BIG_VERSION --user=root & 
