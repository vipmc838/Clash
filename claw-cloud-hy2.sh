#!/bin/bash

# 版本检查和环境准备
apk update
apk add --no-cache curl wget bash openssl ca-certificates

# 确认安装或卸载操作
if [ "$1" == "uninstall" ]; then
  echo "🧹 正在卸载 Hysteria2..."
  pkill -f 'hysteria server' >/dev/null 2>&1
  rm -rf /etc/hysteria /usr/local/bin/hysteria
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
mkdir -p /etc/hysteria

cat > /etc/hysteria/config.yaml << EOF
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

# ===== 安装 hysteria2 =====
wget -O /usr/local/bin/hysteria https://github.com/vipmc838/Clash/raw/refs/heads/main/hysteria-linux-amd64 --no-check-certificate
chmod +x /usr/local/bin/hysteria

# ===== 证书配置 =====
openssl req -x509 -nodes -newkey ec:<(openssl ecparam -name prime256v1) \
  -keyout /etc/hysteria/server.key \
  -out /etc/hysteria/server.crt \
  -subj "/CN=bing.com" -days 36500

# ===== nohup 启动 =====
pkill -f 'hysteria server' >/dev/null 2>&1
nohup /usr/local/bin/hysteria server -c /etc/hysteria/config.yaml >/dev/null 2>&1 &

# ===== 获取名域（公网 IPv4 解析到的域名）=====
DOMAIN=$(wget -qO- http://ip-api.com/json | grep -oP '"reverse"\s*:\s*"\K[^"]+' || echo "无法获取名域")

# ===== 输出连接信息 =====
echo "------------------------------------------------------------------------"
echo "✅ hysteria2 已安装并启动成功"
echo "端口：$PORT"
echo "密码：$PASSWORD"
echo "配置文件：/etc/hysteria/config.yaml"
echo "已使用 nohup 后台启动，可用以下命令管理进程："
echo "启动:    nohup /usr/local/bin/hysteria server -c /etc/hysteria/config.yaml >/dev/null 2>&1 &"
echo "停止:    pkill -f 'hysteria server'"
echo "------------------------------------------------------------------------"
echo "🎯 客户端连接（适用于 V2RayN / Clash）："
echo "hy2://${PASSWORD}@${DOMAIN}:${PORT}?sni=bing.com&insecure=1#Hysteria2"
echo "------------------------------------------------------------------------"
echo "🧹 若需卸载，可执行以下命令："
echo "$0 uninstall"
echo "------------------------------------------------------------------------"
