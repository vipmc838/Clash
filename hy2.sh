#!/bin/bash

apk update
apk add --no-cache curl wget bash openssl ca-certificates openrc

# 生成 base64 随机密码（24字符左右）
generate_base64_password() {
  head -c 18 /dev/urandom | base64
}

GENPASS="$(generate_base64_password)"

echo_hysteria_config_yaml() {
  cat << EOF
listen: :30008


#有域名，使用CA证书
#acme:
#  domains:
#    - test.heybro.bid #你的域名，需要先解析到服务器ip
#  email: xxx@gmail.com

#使用自签名证书
tls:
  cert: /etc/hysteria/server.crt
  key: /etc/hysteria/server.key

auth:
  type: password
  password: $GENPASS

masquerade:
  type: proxy
  proxy:
    url: https://bing.com/
    rewriteHost: true
EOF
}

echo_hysteria_autoStart(){
  cat << EOF
#!/sbin/openrc-run

name="hysteria"

command="/usr/local/bin/hysteria"
command_args="server --config /etc/hysteria/config.yaml"

pidfile="/var/run/${name}.pid"

command_background="yes"

depend() {
        need networking
}

EOF
}


wget -O /usr/local/bin/hysteria https://github.com/vipmc838/Clash/raw/refs/heads/main/hysteria-linux-amd64  --no-check-certificate
chmod +x /usr/local/bin/hysteria

mkdir -p /etc/hysteria/

openssl req -x509 -nodes -newkey ec:<(openssl ecparam -name prime256v1) -keyout /etc/hysteria/server.key -out /etc/hysteria/server.crt -subj "/CN=bing.com" -days 36500

#写配置文件
echo_hysteria_config_yaml > "/etc/hysteria/config.yaml"

#写自启动
echo_hysteria_autoStart > "/etc/init.d/hysteria"
chmod +x /etc/init.d/hysteria
#启用自启动
rc-update add hysteria

service hysteria start

#启动hy2
#/usr/local/bin/hysteria  server --config /etc/hysteria/config.yaml &

# 获取 IP
SERVER_IP=$(wget -qO- http://ip-api.com/line?fields=query || echo "无法获取外部 IP 地址")

# 输出连接
echo "------------------------------------------------------------------------"
echo "✅ hysteria2 已安装并启动成功"
echo "端口：30008"
echo "密码：$GENPASS"
echo "配置文件：/etc/hysteria/config.yaml"
echo "已设置为开机启动，可用以下命令管理服务："
echo "启动:    service hysteria start"
echo "重启:    service hysteria restart"
echo "状态:    service hysteria status"
echo "------------------------------------------------------------------------"
echo "🎯 客户端连接（适用于V2RayN / Clash）："
echo "hy2://${GENPASS}@${SERVER_IP}:30008?sni=bing.com&insecure=1#Hysteria2"
echo "------------------------------------------------------------------------"
