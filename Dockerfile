FROM alpine:3.15.4

ARG NG_VERSION=1.20.2
ARG MODULE_VERSION=0.0.2

RUN set -x \
  && apk update \
  && apk add --no-cache tzdata curl gcc libc-dev patch pcre-dev zlib-dev make openssl-dev \
  && cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
  && curl -o /tmp/nginx.tar.gz http://nginx.org/download/nginx-${NG_VERSION}.tar.gz \
  && curl -L -o /tmp/ng_proxy_module.tar.gz https://github.com/chobits/ngx_http_proxy_connect_module/archive/refs/tags/v${MODULE_VERSION}.tar.gz \
  && cd /tmp \
  && tar -zvxf nginx.tar.gz \
  && tar -zvxf ng_proxy_module.tar.gz \
  && cd nginx-$NG_VERSION \
  && patch -p1 < ../ngx_http_proxy_connect_module-${MODULE_VERSION}/patch/proxy_connect_rewrite_1018.patch \
  && ./configure --prefix=/opt/nginx --sbin-path=/usr/local/bin/nginx --conf-path=/etc/nginx/nginx.conf \
     --pid-path=/var/run/nginx.pid --lock-path=/var/lock/nginx.lock \
     --error-log-path=/var/log/nginx/error.log --http-log-path=/var/log/nginx/access.log \
     --add-module=../ngx_http_proxy_connect_module-${MODULE_VERSION} --with-http_ssl_module \
  && make && make install \
  && ln -sf /dev/stdout /var/log/nginx/access.log \
  && ln -sf /dev/stderr /var/log/nginx/error.log \
  && rm -rf /var/lib/apt/lists/* \
  && rm /var/cache/apk/* \
  && rm -rf /tmp/*

ADD 50x.html /opt/nginx/html/50x.html
ADD nginx.conf /etc/nginx/nginx.conf

EXPOSE 1080

ENTRYPOINT ["nginx", "-g", "daemon off;"]
