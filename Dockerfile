##########################################
#         构建可执行二进制文件             #
##########################################
# 指定构建的基础镜像
FROM golang:alpine AS builder

# 作者描述信息
MAINTAINER danxiaonuo
# 时区设置
ARG TZ=Asia/Shanghai
ENV TZ=$TZ
# 语言设置
ARG LANG=C.UTF-8
ENV LANG=$LANG

# 镜像变量
ARG DOCKER_IMAGE=danxiaonuo/clash
ENV DOCKER_IMAGE=$DOCKER_IMAGE
ARG DOCKER_IMAGE_OS=golang
ENV DOCKER_IMAGE_OS=$DOCKER_IMAGE_OS
ARG DOCKER_IMAGE_TAG=alpine
ENV DOCKER_IMAGE_TAG=$DOCKER_IMAGE_TAG

# 构建依赖
ARG BUILD_DEPS="\
      git \
      wget \
      curl \
      jq \
      make"
ENV BUILD_DEPS=$BUILD_DEPS

# ***** 安装依赖 *****
RUN set -eux \
   # 修改源地址
   && sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories  \
   # 更新源地址并更新系统软件
   && apk update && apk upgrade \
   # 安装依赖包
   && apk add -U --update $BUILD_DEPS \
   # 更新时区
   && ln -sf /usr/share/zoneinfo/${TZ} /etc/localtime \
   # 更新时间
   && echo ${TZ} > /etc/timezone

# 运行下载
RUN set -eux \
    && export CLASH_DOWN=$(curl -s https://api.github.com/repos/Dreamacro/clash/releases | jq -r .[].assets[].browser_download_url| grep -i 'premium'| grep -i 'clash-linux-amd64') \
    && wget --no-check-certificate -O /tmp/clash.gz $CLASH_DOWN \
    && cd /tmp && gzip -d clash.gz && mv clash / \
    && wget --no-check-certificate -O /Country.mmdb https://github.com/Dreamacro/maxmind-geoip/releases/latest/download/Country.mmdb
# ##############################################################################


##########################################
#         构建基础镜像                    #
##########################################
# 
# 指定创建的基础镜像
FROM alpine:latest

# 作者描述信息
MAINTAINER danxiaonuo
# 时区设置
ARG TZ=Asia/Shanghai
ENV TZ=$TZ
# 语言设置
ARG LANG=C.UTF-8
ENV LANG=$LANG

ARG PKG_DEPS="\
      zsh \
      bash \
      bind-tools \
      ipset \
      iproute2 \
      git \
      vim \
      tzdata \
      curl \
      wget \
      lsof \
      zip \
      unzip \
      ca-certificates"
ENV PKG_DEPS=$PKG_DEPS

# dumb-init
# https://github.com/Yelp/dumb-init
ARG DUMBINIT_VERSION=1.2.5
ENV DUMBINIT_VERSION=$DUMBINIT_VERSION


# ***** 安装依赖 *****
RUN set -eux \
   # 修改源地址
   && sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories \
   # 更新源地址并更新系统软件
   && apk update && apk upgrade \
   # 安装依赖包
   && apk add -U --update $PKG_DEPS \
   # 更新时区
   && ln -sf /usr/share/zoneinfo/${TZ} /etc/localtime \
   # 更新时间
   &&  echo ${TZ} > /etc/timezone \
   # 更改为zsh
   &&  sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" || true \
   &&  sed -i -e "s/bin\/ash/bin\/zsh/" /etc/passwd \
   &&  sed -i -e 's/mouse=/mouse-=/g' /usr/share/vim/vim*/defaults.vim \
   &&  /bin/zsh

# 拷贝clash
COPY --from=builder /Country.mmdb /root/.config/clash/
COPY --from=builder /clash /usr/bin/clash
COPY ["./conf/clash/config.yaml", "/root/.config/clash/"]

# 安装dumb-init
RUN set -eux \
    && wget --no-check-certificate https://github.com/Yelp/dumb-init/releases/download/v${DUMBINIT_VERSION}/dumb-init_${DUMBINIT_VERSION}_x86_64 -O /usr/bin/dumb-init \
    && chmod +x /usr/bin/dumb-init \
    && chmod +x /usr/bin/clash

# 容器信号处理
STOPSIGNAL SIGQUIT

# 入口
ENTRYPOINT ["dumb-init"]

# 运行clash
CMD ["clash","-d","/root/.config/clash/"]
