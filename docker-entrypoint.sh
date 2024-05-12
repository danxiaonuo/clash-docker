#!/bin/bash

# ulimit -SHc unlimited
# ulimit -SHu unlimited
# ulimit -SHs unlimited
# ulimit -SHl unlimited
# ulimit -SHi unlimited
# ulimit -SHq unlimited
# ulimit -SHn 655360

# 配置dae
export wan_int=$(ip route get 8.8.8.8 | awk 'NR==1 {print $5}')
mkdir -p /etc/dae/
cat <<-EOF > /etc/dae/config.dae
# 全局配置
global{
                # tproxy 监听的端口
                tproxy_port: ${tproxy_port}
                # 以保护 tproxy 端口免受未经请求的流量影响
                tproxy_port_protect: true
                # 从 dae 发送的流量将被设置为 SO_MARK
                so_mark_from_dae: 0
                # 日志级别：error, warn, info, debug, trace
                log_level: info
                # 在拉取订阅之前禁用等待网络
                disable_waiting_network: false
                # 要绑定的 LAN 接口
                lan_interface: ${wan_int},docker0                
                # 要绑定的 WAN 接口
                wan_interface: ${wan_int}
                # 自动配置 Linux 内核参数
                auto_config_kernel_parameter: true
                # 检测url地址
                tcp_check_url: 'http://cp.cloudflare.com,1.1.1.1,2606:4700:4700::1111'
                # HTTP 请求方法为 
                tcp_check_http_method: HEAD
                # 此 DNS 将用于检查节点的 UDP 连接
                udp_check_dns: 'dns.google.com:53,8.8.8.8,2001:4860:4860::8888'
                # 检测时间
                check_interval: 30s
                # 仅当 new_latency <= old_latency - tolerance 时，组才会切换节点
                check_tolerance: 50ms
                # 基于域的流量分割能力
                dial_mode: domain
                # 允许不安全的 TLS 证书
                allow_insecure: false
                # 等待发送第一个数据进行嗅探的超时时间
                sniffing_timeout: 100ms
                # TLS 实现
                tls_implementation: tls
                # uTLS 要模仿的客户端 Hello ID
                utls_imitate: chrome_auto
}

# 组
group{
        my_group{
                # 从每个连接的组中选择具有最小移动平均延迟的节点
                policy: min_moving_avg
        }
}

# 路由
routing{
        pname(smartdns) -> must_direct
        pname(clash) -> must_direct
        pname(systemd-resolved) -> must_direct
        domain(geosite:cn) -> direct
        ip(geoip:private) -> direct
        ip(geoip:cn) -> direct
        fallback: my_group
}

# 节点
node{
        local:'socks5://127.0.0.1:${socks_port}'
}
EOF
chmod 0640 /etc/dae/config.dae

# 运行supervisord
exec /usr/bin/supervisord -c /etc/supervisor/supervisord.conf
