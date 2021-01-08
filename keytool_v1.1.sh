#!/bin/bash
# 2021-1-4 11:17:18
# author: 丁佑强
COMPLEX() {
# 这些是之前简约配置tomcat ssl的命令，有需要复杂输入的地方
keytool -genkey -v -alias tomcat -keyalg RSA -keystore tomcat.keystore -validity 36500
keytool -genkey -v -alias mykey -keyalg RSA -storetype PKCS12 -keystore mykey.p12
keytool -export -alias mykey -keystore mykey.p12 -storetype PKCS12 -storepass 123456 -rfc -file mykey.cer
keytool -import -v -file mykey.cer -keystore tomcat.keystore
keytool -list -keystore tomcat.keystore
keytool -keystore tomcat.keystore -export -alias tomcat -file tomcat.cer
}

# 简洁地配置的话，如下方输入执行脚本
BRIEF() {
# http://www.blogjava.net/itvincent/articles/330988.html
  SERVER_GEN_CERT() {
# 顾名思义
	keytool -genkey -keyalg RSA -dname "cn=localhost,ou=sango,o=none,l=china,st=beijing,c=cn" -alias server -keypass password -keystore server.jks -storepass password -validity 3650
	keypass password -keystore server.jks -storepass password -validity 3650
	keytool -genkey -keyalg RSA -dname "cn=localhost,ou=sango,o=none,l=china,st=beijing,c=cn" -alias server -keypass password -keystore server.jks -storepass password -validity 3650 
  }
  CLIENT_GEN_CERT() {
	keytool -genkey -keyalg RSA -dname "cn=sango,ou=sango,o=none,l=china,st=beijing,c=cn" -alias custom -storetype PKCS12 -keypass password -keystore custom.p12 -storepass password -validity 3650
  } 
  #SERVER_GEN_CERT
  #CLIENT_GEN_CERT
  SERVER_NEED_TO_TRUST_CLIENT_CERT() {
	keytool -export -alias custom -file custom.cer -keystore custom.p12 -storepass password -storetype PKCS12 -rfc
	keytool -export -alias custom -file custom.cer -keystore custom.p12 -storepass password -storetype PKCS12 -rfc
	keytool -import -v -alias custom -file custom.cer -keystore server.jks -storepass password
  } 
  CHECK_CERT() {
	keytool -list -v -keystore server.jks -storepass password
  }
  # SERVER_NEED_TO_TRUST_CLIENT_CERT
  # CHECK_CERT
  TOMCAT_SSL_CONFIGURE() {
# 这段是不能执行的
<Connector port="8443" protocol="HTTP/1.1" SSLEnabled="true" 
  maxThreads="150" scheme="https" secure="true"
  clientAuth="true" sslProtocol="TLS" #注意下面这两段都有clientAuth=true的设置
  keystoreFile="$WHERE_IS_YOURKEYSTORE" keystorePass="$KEYSTORE_PASSWORD"
  truststoreFile="$WHERE_IS_YOURKEYSTORE" truststorePass="password"
/>
<Connector port="8443" protocol="HTTP/1.1" SSLEnabled="true"
  maxThreads="150" scheme="https" secure="true"
  clientAuth="true" sslProtocol="TLS"
  keystoreFile="$WHERE_IS_YOURKEYSTORE" keystorePass="$KEYSTORE_PASSWORD"
  truststoreFile="$WHERE_IS_YOURKEYSTORE" truststorePass="password"
/>
  }
  IMPORT_CLIENT_CERT_TO_BROWSER() {
	# 文档这里没有说明，应该就是windows端操作了
  }
 JAVA_CODE () { # 看不懂这段东西，双向认证文档很多都有这种代码
	DefaultHttpClient httpclient = new DefaultHttpClient();

        KeyStore trustStore = KeyStore.getInstance(KeyStore.getDefaultType());  
        FileInputStream instream = new FileInputStream(new File("D:/server.jks"));
        try {
            trustStore.load(instream, "password".toCharArray());
        } finally {
            instream.close();
        }
       
        SSLSocketFactory socketFactory = new SSLSocketFactory(trustStore,"password",trustStore);
        Scheme sch = new Scheme("https", socketFactory, 443);
        httpclient.getConnectionManager().getSchemeRegistry().register(sch);

        HttpGet httpget = new HttpGet("https://localhost:8443/");

        System.out.println("executing request" + httpget.getRequestLine());
       
        HttpResponse response = httpclient.execute(httpget);
        HttpEntity entity = response.getEntity();

        System.out.println("----------------------------------------");
        System.out.println(response.getStatusLine());
        if (entity != null) {
            System.out.println("Response content length: " + entity.getContentLength());
        }
        if (entity != null) {
            entity.consumeContent();
        }
        httpclient.getConnectionManager().shutdown();     
  }
}














