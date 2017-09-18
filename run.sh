#/bin/bash

#在git 的bash中执行 git自带openssl。如果要生成 p12文件，需要在原生的linux bash中执行，或者cwgwin中的bash
#生成的所有证书在 gen 文件夹下
#
if [ $# -eq 0 ]; then
   echo "usage: ./cmd.sh [server_ip]"
   exit
fi
server_ip=$1
#替换conf/extfile 中的SIP2 为参数中的ip地址
sed -Ei 's/SIP2/'$server_ip'/g' conf/extfile.cnf

#判断是否存在gen文件夹
if [  -d "gen" ]; then
  #如果存在则删除
  rm -r gen
fi
#创建gen文件夹
mkdir gen

#ca 根证书 
openssl genrsa -out gen/ca.pem 2048
openssl ecparam -genkey -name secp384r1 -out gen/ca.pem
openssl req -config conf/ca.cnf -newkey rsa:2048 -x509 -days 3650 -key gen/ca.pem -out gen/ca.crt 

#server 服务端 添加了extfile.cnf 
openssl genrsa -out gen/server.key 2048
openssl ecparam -genkey -name secp384r1 -out gen/server.key
openssl req -config conf/server.cnf -new -key gen/server.key -out gen/server_reqout.txt 
openssl x509 -req -in gen/server_reqout.txt -days 3650 -sha1 -CAcreateserial -CA gen/ca.crt -CAkey gen/ca.pem -out gen/server.crt -extfile conf/extfile.cnf


#client 客户端
openssl genrsa -out gen/client.key 2048
openssl ecparam -genkey -name secp384r1 -out gen/client.key
openssl req -config conf/client.cnf -new -key gen/client.key -out gen/client_reqout.txt 
openssl x509 -req -in gen/client_reqout.txt -days 3650 -sha1 -CAcreateserial -CA gen/ca.crt -CAkey gen/ca.pem -out gen/client.crt

# 生成p12文件，android 客户端使用。以下命令需要在linux 的bash或者 cygwin 中的bash 中执行，在git bash 中执行会挂起。
# 此处生成p12文件时需要密码，此密码和android 客户端证书的密码需要一致
echo "gen clien.p12 ......"
openssl pkcs12 -export -clcerts -in gen/client.crt -inkey gen/client.key -out gen/client.p12


#还原变量，以便下次再执行命令行程序时，可以在参数中重新设置ip地址。替换conf/extfile 中的ip地址为SIP2。 
sed -Ei 's/'$server_ip'/SIP2/g' conf/extfile.cnf