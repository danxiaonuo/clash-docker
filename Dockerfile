##########################################
#         构建可执行二进制文件             #
##########################################
# 指定构建的基础镜像
ARG BUILD_NGINX_IMAGE=danxiaonuo/nginx:latest
ARG BUILD_YACD_IMAGE=haishanh/yacd:latest

# 指定创建的基础镜像
FROM ${BUILD_NGINX_IMAGE} as nginx
FROM ${BUILD_YACD_IMAGE} as yacd

FROM alpine:latest as down

# 作者描述信息
MAINTAINER danxiaonuo
# 时区设置
ARG TZ=Asia/Shanghai
ENV TZ=$TZ
# 语言设置
ARG LANG=C.UTF-8
ENV LANG=$LANG


# 构建依赖
ARG BUILD_DEPS="\
      git \
      wget \
      curl \
      jq \
      tar \
      xz \
      make"
ENV BUILD_DEPS=$BUILD_DEPS

# ***** 安装依赖 *****
RUN set -eux && \
   # 修改源地址
   sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories && \
   # 更新源地址并更新系统软件
   apk update && apk upgrade && \
   # 安装依赖包
   apk add --no-cache --clean-protected $BUILD_DEPS && \
   rm -rf /var/cache/apk/* && \
   # 更新时区
   ln -sf /usr/share/zoneinfo/${TZ} /etc/localtime && \
   # 更新时间
   echo ${TZ} > /etc/timezone

# 运行下载
RUN set -eux \
    && export CLASH_DOWN=$(curl -s https://api.github.com/repos/MetaCubeX/mihomo/releases | jq -r .[].assets[].browser_download_url | grep -i Alpha | grep -i gz | grep -i linux-amd64-compatible-alpha | head -n 1) \
    && wget --no-check-certificate -O /tmp/clash.gz $CLASH_DOWN \
    && cd /tmp && gzip -d clash.gz \
    && wget --no-check-certificate -O /Country.mmdb https://github.com/Dreamacro/maxmind-geoip/releases/latest/download/Country.mmdb
    

# ##############################################################################

##########################################
#         构建基础镜像                    #
##########################################
# 
# 指定创建的基础镜像
FROM ubuntu:jammy

# 作者描述信息
MAINTAINER danxiaonuo
# 时区设置
ARG TZ=Asia/Shanghai
ENV TZ=$TZ
# 语言设置
ARG LANG=zh_CN.UTF-8
ENV LANG=$LANG

# 环境设置
ARG DEBIAN_FRONTEND=noninteractive
ENV DEBIAN_FRONTEND=$DEBIAN_FRONTEND

# 工作目录
ARG NGINX_DIR=/data/nginx
ENV NGINX_DIR=$NGINX_DIR
# NGINX环境变量
ARG PATH=/data/nginx/sbin:$PATH
ENV PATH=$PATH

# GO环境变量
ARG GO_VERSION=1.22.3
ENV GO_VERSION=$GO_VERSION
ARG GOROOT=/opt/go
ENV GOROOT=$GOROOT
ARG GOPATH=/opt/golang
ENV GOPATH=$GOPATH

# luajit2
# https://github.com/openresty/luajit2
ARG LUAJIT_VERSION=2.1-20231117
ENV LUAJIT_VERSION=$LUAJIT_VERSION
ARG LUAJIT_LIB=/usr/local/lib
ENV LUAJIT_LIB=$LUAJIT_LIB
ARG LUAJIT_INC=/usr/local/include/luajit-2.1
ENV LUAJIT_INC=$LUAJIT_INC
ARG LD_LIBRARY_PATH=/usr/local/lib/:$LD_LIBRARY_PATH
ENV LD_LIBRARY_PATH=$LD_LIBRARY_PATH

# lua-resty-core
# https://github.com/openresty/lua-resty-core
ARG LUA_RESTY_CORE_VERSION=0.1.27
ENV LUA_RESTY_CORE_VERSION=$LUA_RESTY_CORE_VERSION
ARG LUA_LIB_DIR=/usr/local/share/lua/5.1
ENV LUA_LIB_DIR=$LUA_LIB_DIR

# YACD
ENV YACD_DEFAULT_BACKEND "http://127.0.0.1:9090"

ARG NGINX_BUILD_DEPS="\
    libssl-dev \
    zlib1g-dev \
    libpcre3-dev \
    libxml2-dev \
    libxslt1-dev \
    libgd-dev \
    libgeoip-dev"
ENV NGINX_BUILD_DEPS=$NGINX_BUILD_DEPS

# 安装依赖包
ARG PKG_DEPS="\
    zsh \
    bash \
    bash-doc \
    bash-completion \
    dnsutils \
    iproute2 \
    net-tools \
    sysstat \
    ncat \
    git \
    vim \
    jq \
    lrzsz \
    tzdata \
    curl \
    wget \
    axel \
    lsof \
    zip \
    unzip \
    tar \
    rsync \
    iputils-ping \
    telnet \
    procps \
    libaio1 \
    numactl \
    xz-utils \
    gnupg2 \
    psmisc \
    libmecab2 \
    debsums \
    locales \
    iptables \
    python2 \
    python3 \
    python3-dev \
    python3-pip \
    language-pack-zh-hans \
    fonts-droid-fallback \
    fonts-wqy-zenhei \
    fonts-wqy-microhei \
    fonts-arphic-ukai \
    fonts-arphic-uming \
    ca-certificates \
    supervisor"
ENV PKG_DEPS=$PKG_DEPS

# 拷贝clash
COPY --from=down /tmp/clash /usr/bin/clash
COPY ["./conf/clash/config.yaml", "/root/.config/clash/"]

# 拷贝nginx
COPY --from=nginx /usr/local/lib /usr/local/lib
COPY --from=nginx /usr/local/share/lua /usr/local/share/lua
COPY --from=nginx /data/nginx /data/nginx

# 拷贝yacd
COPY --from=yacd /usr/share/nginx/html /www

# 拷贝文件
COPY ["./docker-entrypoint.sh", "/usr/bin/"]
COPY ["./conf/nginx/ssl", "/ssl"]
COPY ["./conf/nginx/vhost/default.conf", "/data/nginx/conf/vhost/default.conf"]
COPY ["./conf/supervisor", "/etc/supervisor"]

# ***** 安装依赖 *****
RUN set -eux && \
   # 更新源地址
   sed -i s@http://*.*ubuntu.com@https://mirrors.aliyun.com@g /etc/apt/sources.list && \
   sed -i 's?# deb-src?deb-src?g' /etc/apt/sources.list && \
   # 解决证书认证失败问题
   touch /etc/apt/apt.conf.d/99verify-peer.conf && echo >>/etc/apt/apt.conf.d/99verify-peer.conf "Acquire { https::Verify-Peer false }" && \
   # 更新系统软件
   DEBIAN_FRONTEND=noninteractive apt-get update -qqy && apt-get upgrade -qqy && \
   # 安装依赖包
   DEBIAN_FRONTEND=noninteractive apt-get -y --no-install-recommends install $PKG_DEPS $NGINX_BUILD_DEPS && \
   DEBIAN_FRONTEND=noninteractive apt-get -y --no-install-recommends autoremove --purge && \
   DEBIAN_FRONTEND=noninteractive apt-get -y --no-install-recommends autoclean && \
   rm -rf /var/lib/apt/lists/* && \
   # 更新时区
   ln -sf /usr/share/zoneinfo/${TZ} /etc/localtime && \
   # 更新时间
   echo ${TZ} > /etc/timezone && \
   # 更改为zsh
   sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" || true && \
   sed -i -e "s/bin\/ash/bin\/zsh/" /etc/passwd && \
   sed -i -e 's/mouse=/mouse-=/g' /usr/share/vim/vim*/defaults.vim && \
   locale-gen zh_CN.UTF-8 && localedef -f UTF-8 -i zh_CN zh_CN.UTF-8 && locale-gen && \
   /bin/zsh

# ***** 安装golang *****
RUN set -eux && \
    wget --no-check-certificate https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz -O /tmp/go${GO_VERSION}.linux-amd64.tar.gz && \
    cd /tmp/ && tar zxvf go${GO_VERSION}.linux-amd64.tar.gz -C /opt && \
    export GOROOT=/opt/go && \
    export GOPATH=/opt/golang && \
    export PATH=$PATH:$GOROOT/bin:$GOPATH/bin && \
    mkdir -pv $GOPATH/bin && \
    ln -sfd /opt/go/bin/* /usr/bin/

# ***** 升级 setuptools 版本 *****
RUN set -eux && \
    wget --no-check-certificate https://bootstrap.pypa.io/pip/2.7/get-pip.py -O /tmp/get-pip.py && \
    python2 /tmp/get-pip.py && \
    pip3 config set global.index-url http://mirrors.aliyun.com/pypi/simple/ && \
    pip3 config set install.trusted-host mirrors.aliyun.com && \
    pip3 install --upgrade pip setuptools wheel pycryptodome lxml cython beautifulsoup4 requests && \
    rm -r /root/.cache && rm -rf /tmp/*
    
# ***** 检查依赖并授权 *****
RUN set -eux && \
    # 创建用户和用户组
    addgroup --system --quiet nginx && \
    adduser --quiet --system --disabled-login --ingroup nginx --home /data/nginx --no-create-home nginx && \
    chmod a+x /usr/bin/docker-entrypoint.sh /usr/bin/clash && \
    chown --quiet -R nginx:nginx /www && chmod -R 775 /www && \
    ln -sf /dev/stdout /data/nginx/logs/access.log && \
    ln -sf /dev/stderr /data/nginx/logs/error.log && \
    # smoke test
    # ##############################################################################
    ln -sf ${NGINX_DIR}/sbin/* /usr/sbin/ && \
    nginx -V && \
    nginx -t && \
    rm -rf /var/lib/apt/lists/* /tmp/*

# ***** 工作目录 *****
WORKDIR /root

# ***** 入口 *****
ENTRYPOINT ["docker-entrypoint.sh"]

# 自动检测服务是否可用
HEALTHCHECK --interval=30s --timeout=3s CMD curl --fail http://localhost/ || exit 1
