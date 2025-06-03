#!/bin/bash

# 版本检查和环境准备
apk update
apk add --no-cache curl wget bash openssl ca-certificates

# ===== 手动输入端口和密码 =====
read -p "请输入监听端口（如 30008）: " PORT
read -p "请输入连接密码: " PASSWORD

# 校验输入
if [ -z "$PORT" ] || [ -z "$PASSWORD" ]; then
  echo "❌ 错误：端口和密码不能为空，安装终止。"
  exit 1
fi

# ===== 安装 Hysteria2 可执行文件 =====
wget -O /usr/local/bin/hysteria https://github.com/vipmc838/Clash/raw/refs/heads/main/hysteria-linux-amd64 --no-check-certificate
chmod +x /usr/local/bin/hysteria

# ===== 创建配置目录与证书 =====
mkdir -p /etc/hysteria
openssl req -x509 -nodes -newkey ec:<(openssl ecparam -name prime256v1) \
  -keyout /etc/hysteria/server.key \
  -out /etc/hysteria/server.crt \
  -subj "/CN=bing.com" -days 36500

# ===== 写入配置文件 =====
cat > /etc/hysteria/config.yaml <<EOF
listen: :$PORT

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

# ===== 以 nohup 启动 =====
nohup /usr/local/bin/hysteria server -c /etc/hysteria/config.yaml >/dev/null 2>&1 &

# ===== 获取公网 IP（域名方式）=====
SERVER_DOMAIN=$(curl -s --max-time 5 ifconfig.me || echo "无法获取名域")

# ===== 显示连接信息 =====
echo "------------------------------------------------------------------------"
echo "✅ Hysteria2 已安装并使用 nohup 启动"
echo "端口：$PORT"
echo "密码：$PASSWORD"
echo "配置文件：/etc/hysteria/config.yaml"
echo "------------------------------------------------------------------------"
echo "🎯 客户端连接（V2RayN / Clash）："
echo "hy2://${PASSWORD}@${SERVER_DOMAIN}:${PORT}?sni=bing.com&insecure=1#Hysteria2"
echo "------------------------------------------------------------------------"
echo "🧹 若需卸载："
echo "killall hysteria"
echo "rm -rf /etc/hysteria /usr/local/bin/hysteria"
echo "------------------------------------------------------------------------"
