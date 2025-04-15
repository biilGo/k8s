#!/bin/bash
 export HOST_PORT=12050
export HOST_IP=$(hostname -I | awk '{print $1}')
echo $HOST_IP
echo $HOST_PORT
echo $NACOS_ADDR
java \
--add-exports java.base/jdk.internal.loader=ALL-UNNAMED \
--add-exports java.base/jdk.internal.perf=ALL-UNNAMED \
--add-opens java.base/java.lang=ALL-UNNAMED \
-Duser.language=zh \
-Duser.country=CN \
-Dspring.cloud.nacos.username=$NACOS_USERNAME \
-Dspring.cloud.nacos.password=$NACOS_PASSWD \
-Djava.io.tmpdir=./ \
-Dspring.cloud.nacos.discovery.ip=$HOST_IP \
-Dspring.cloud.nacos.discovery.port=$HOST_PORT  \
-Dspring.cloud.nacos.discovery.group=DEFAULT_GROUP  \
-Dspring.cloud.nacos.config.group=$NACOS_NS  \
-Dspring.cloud.nacos.discovery.namespace=$NACOS_NS  \
-Dspring.cloud.nacos.discovery.server-addr=$NACOS_ADDR  \
-Dlogging.file.path=/opt -jar /opt/*.jar
