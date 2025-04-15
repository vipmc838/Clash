#!/bin/bash

# 版本检查和环境准备
apk update
apk add --no-cache curl wget bash openssl ca-certificates openrc

# 确认安装或卸载操作
if [ "$1" == "uninstall" ]; then
  echo "🧹 正在卸载 Hysteria2..."
  rc-update del hysteria && service hysteria stop
  rm -rf /etc/hysteria /usr/local/bin/hysteria /etc/init.d/hysteria
  echo "✅ Hysteria2 卸载完成！"
  exit 0
fi

# ===== 手动输入端口和密码（如未设置） =====
if [ -z "$PORT" ]; then
  read -p "请输入监听端口（如 30008）: " PORT
fi

if [ -z "$PASSWORD" ]; then
  read -p "请输入连接密码: " PASSWORD
fi

# 检查输入是否合法
if [ -z "$PORT" ] || [ -z "$PASSWORD" ]; then
  echo "❌ 错误：端口和密码不能为空，安装终止。"
  exit 1
fi

# ===== 生成配置文件 =====
echo_hysteria_config_yaml() {
  cat << EOF
listen: :$PORT

# 使用自签名证书
tls:
  cert: /etc/hysteria/server.crt
  key: /etc/hysteria/server.key

auth:
  type: password
  password: $PASSWORD

masquerade:
  type: proxy
  proxy:
    url: https://bing.com/
    rewriteHost: true
EOF
}

# ===== 自启动配置 =====
echo_hysteria_autoStart() {
  cat << EOF
#!/sbin/openrc-run

name="hysteria"
command="/usr/local/bin/hysteria"
command_args="server --config /etc/hysteria/config.yaml"
pidfile="/var/run/\${name}.pid"
command_background="yes"

depend() {
  need networking
}
EOF
}

# ===== 安装 hysteria2 =====
wget -O /usr/local/bin/hysteria https://github.com/vipmc838/Clash/raw/refs/heads/main/hysteria-linux-amd64 --no-check-certificate
chmod +x /usr/local/bin/hysteria

# ===== 证书配置 =====
mkdir -p /etc/hysteria
openssl req -x509 -nodes -newkey ec:<(openssl ecparam -name prime256v1) -keyout /etc/hysteria/server.key -out /etc/hysteria/server.crt -subj "/CN=bing.com" -days 36500

# ===== 写配置、自启动 =====
echo_hysteria_config_yaml > /etc/hysteria/config.yaml
echo_hysteria_autoStart > /etc/init.d/hysteria
chmod +x /etc/init.d/hysteria
rc-update add hysteria
service hysteria start

# ===== 获取公网 IP =====
SERVER_IP=$(wget -qO- http://ip-api.com/line?fields=query || echo "无法获取外部 IP 地址")

# ===== 输出连接信息 =====
echo "------------------------------------------------------------------------"
echo "✅ hysteria2 已安装并启动成功"
echo "端口：$PORT"
echo "密码：$PASSWORD"
echo "配置文件：/etc/hysteria/config.yaml"
echo "已设置为开机启动，可用以下命令管理服务："
echo "启动:    service hysteria start"
echo "重启:    service hysteria restart"
echo "状态:    service hysteria status"
echo "------------------------------------------------------------------------"
echo "🎯 客户端连接（适用于 V2RayN / Clash）："
echo "hy2://${PASSWORD}@${SERVER_IP}:${PORT}?sni=bing.com&insecure=1#Hysteria2"
echo "------------------------------------------------------------------------"
echo "🧹 若需卸载，可执行以下命令："
echo "rc-update del hysteria && service hysteria stop"
echo "rm -rf /etc/hysteria /usr/local/bin/hysteria /etc/init.d/hysteria"
echo "------------------------------------------------------------------------"
