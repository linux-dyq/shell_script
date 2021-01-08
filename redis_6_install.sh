#!/bin/bash
# 2020-12-18 09:12:01
# 官网 脚本

SRC_DIR='/usr/local/'
REDIS_VER='6.0.9'
cd $SRC_DIR


yum -y install centos-release-scl
yum -y install devtoolset-9-gcc devtoolset-9-gcc-c++ devtoolset-9-binutils
scl enable devtoolset-9 bash
wget https://download.redis.io/releases/redis-$REDIS_VER\.tar.gz
tar xzf redis-$REDIS_VER\.tar.gz
cd redis-$REDIS_VER
make

#ln -s $SRC_DIR/redis-$REDIS_VER/src/mkreleasehdr.sh /usr/bin/
ln -s $SRC_DIR/redis-$REDIS_VER/src/redis-check-aof /usr/bin/
ln -s $SRC_DIR/redis-$REDIS_VER/src/redis-server /usr/bin/
ln -s $SRC_DIR/redis-$REDIS_VER/src/redis-trib.rb /usr/bin/
ln -s $SRC_DIR/redis-$REDIS_VER/src/redis-cli /usr/bin/
#ln -s $SRC_DIR/redis-$REDIS_VER/src/modules /usr/bin/
ln -s $SRC_DIR/redis-$REDIS_VER/src/redis-sentinel /usr/bin/
ln -s $SRC_DIR/redis-$REDIS_VER/src/redis-benchmark /usr/bin/
ln -s $SRC_DIR/redis-$REDIS_VER/src/redis-check-rdb /usr/bin/

cp  redis.conf redis.conf.bak

sed -i '/^bind/d' redis.conf
echo 'bind 0.0.0.0' >> redis.conf
sed -i 's/daemonize no/daemonize yes/g'  redis.conf
redis-server redis.conf
#rm -f /usr/bin/mkreleasehdr.sh 
#rm -f /usr/bin/redis-check-aof 
#rm -f /usr/bin/redis-server 
#rm -f /usr/bin/redis-trib.rb 
#rm -f /usr/bin/redis-cli 
#rm -f /usr/bin/modules 
#rm -f /usr/bin/redis-sentinel 
#rm -f /usr/bin/redis-benchmark 
#rm -f /usr/bin/redis-check-rdb 
