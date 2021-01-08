keytool -genkey -v -alias tomcat -keyalg RSA -keystore tomcat.keystore -validity 36500
keytool -genkey -v -alias mykey -keyalg RSA -storetype PKCS12 -keystore mykey.p12
keytool -export -alias mykey -keystore mykey.p12 -storetype PKCS12 -storepass 123456 -rfc -file mykey.cer
keytool -import -v -file mykey.cer -keystore tomcat.keystore
keytool -list -keystore tomcat.keystore
keytool -keystore tomcat.keystore -export -alias tomcat -file tomcat.cer
