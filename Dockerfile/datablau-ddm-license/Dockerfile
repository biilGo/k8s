#基础镜像
FROM 192.168.2.7:80/datablau/openjdk:17

#创作者
MAINTAINER Datablau

#设置变量
ENV DDM_LIC_HOME=/opt/datablau-ddm-license
ENV LOCALAPPDATA=/opt/datablau-ddm-license
ENV datablau_docker_host ddmlic.datablau.svc.cluster.local

COPY ./startup.sh /opt
COPY ./app /opt
RUN chmod 775 /opt/startup.sh
CMD ["/bin/sh", "-c", "/opt/startup.sh"]
