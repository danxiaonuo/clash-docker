#!/bin/bash

# ulimit -SHc unlimited
# ulimit -SHu unlimited
# ulimit -SHs unlimited
# ulimit -SHl unlimited
# ulimit -SHi unlimited
# ulimit -SHq unlimited
# ulimit -SHn 655360

sed -i "s|http://127.0.0.1:9090|$YACD_DEFAULT_BACKEND|" /www/index.html

cat <<-EOF > /data/nginx/conf/vhost/default.conf
# 服务
server {

    # 指定监听端口
    listen 80;
    listen [::]:80;
    # 域名
    server_name _;
    # 指定编码
    charset utf-8;
    # SSL跳转 
    #if (\$ssl_protocol = "") {
    #    return 301 https://\$host\$request_uri;
    #}
    # 开启SSL
    # include /ssl/xiaonuo.live/xiaonuo.live.conf;
    # 启用流量控制
    # 限制当前站点最大并发数
    # limit_conn perserver 200;
    # 限制单个IP访问最大并发数
    # limit_conn perip 20;
    # 限制每个请求的流量上限（单位：KB）
    # limit_rate 512k;
    # 关联缓存配置
    # include cache.conf;
    # 关联php配置
    # include php.conf;
    # 开启rewrite
    # include /rewrite/default.conf;
    # 日志
    access_log logs/default.log combined;
    error_log logs/default.log error;
    # 路由
    location / {
             # 根目录
             root /www;
             # 站点索引设置
             index index.html index.htm default.htm default.html forum.php default.php index.php;
             # 日志
             access_log logs/xiaonuo.log combined;
             error_log logs/xiaonuo.log error;
    }
	location ~ assets\/.*\.(?:css|js|woff2?|svg|gif|map)$ {
        root /www;
        try_files $uri $uri/ /index.html;
        add_header Cache-Control "public, max-age=31536000, immutable";
    }
    # 所有静态文件由nginx直接读
    location ~ .*.(htm|html|gif|jpg|jpeg|png|bmp|swf|ioc|rar|zip|txt|flv|mid|doc|ppt|pdf|xls|mp3|wma|gz|svg|mp4|ogg|ogv|webm|htc|xml|woff)\$
    # 图片缓存时间设置
    {
       expires 0s;
    }
    # JS和CSS缓存时间设置
    location ~ .*.(js|css)?\$
    {
       expires 0s;
    }
		
    location ~ /\.
    {
       deny all;
    }
}
EOF

# 运行supervisord
exec /usr/bin/supervisord -c /etc/supervisor/supervisord.conf
