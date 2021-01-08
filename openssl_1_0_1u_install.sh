#!/bin/bash

# --------------zlib------------------------------
cd /usr/local/src
wget http://www.zlib.net/zlib-1.2.11.tar.gz
tar xf zlib-1.2.11.tar.gz
cd  zlib-1.2.11 && ./configure --shared && make -j4 && make install -j4
cp  zutil.h  /usr/local/include
cp  zutil.c  /usr/local/include

# -------------openssl-----------------------
cd  /usr/local/src
wget https://www.openssl.org/source/old/1.0.1/openssl-1.0.1u.tar.gz
yum -y install zlib
tar zxf openssl-1.0.1u.tar.gz
cd openssl-1.0.1u
./config shared zlib && make -j4 && make install -j4
mv  /usr/bin/openssl  /usr/bin/openssl.bak
mv /usr/include/openssl  /usr/include/openssl.bak
ln -s /usr/local/ssl/bin/openssl  /usr/bin/openssl
ln -s /usr/local/ssl/include/openssl  /usr/include/openssl
echo "/usr/local/ssl/lib" >> /etc/ld.so.conf
ldconfig -v 
openssl version -a 
