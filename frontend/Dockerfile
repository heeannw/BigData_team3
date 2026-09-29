ARG NGINX_VERSION=1.30-alpine
FROM nginx:${NGINX_VERSION}

COPY nginx.conf /etc/nginx/conf.d/default.conf
# 배포 이미지에는 정적 파일을 포함한다. (개발 중에는 compose 가 public/ 을 마운트해 덮어씀)
COPY public/ /usr/share/nginx/html/

EXPOSE 80
