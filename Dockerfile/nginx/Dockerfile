#基础镜像
FROM nginx:latest

#创作者
MAINTAINER datablau
 
#创建容器文件夹
RUN mkdir -p /data/log/nginx /opt/nginx/app
 
#拷贝相关前端程序
COPY app/ /opt/nginx/app/
#ADD conf/nginx.conf /etc/nginx/nginx.conf
 
#容器内赋权
RUN chown nginx:nginx -R /data/log/nginx
RUN chown nginx:nginx -R /opt/nginx
 
#端口
EXPOSE 18080
 
#启动程序
ENTRYPOINT nginx -g "daemon off;"
