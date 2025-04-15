#基础镜像
FROM 192.168.2.7:80/datablau/openjdk:17
#创作者
MAINTAINER Datablau

ADD datablau-buildin-plugins*.tar /opt/datablau-base/
COPY ./startup.sh /opt
COPY ./datablau-*.jar /opt
RUN chmod 775 /opt/startup.sh && \
    mkdir /opt/datablau-plugins
CMD ["/bin/sh", "-c", "/opt/startup.sh"]
