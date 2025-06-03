#!/bin/bash

# 版本检查和环境准备
apk update
apk add --no-cache curl wget bash openssl ca-certificates

# ===== 手动输入信息 =====
read -p "请输入 爪云分配的外网域名（如 southeast-1.clawcloudrun.com）: " SERVER_DOMAIN
read -p "请输入内网监听端口（如 30008，用于配置文件）: " INNER_PORT
read -p "请输入外网连接端口（爪云分配的udp端口，用于客户端连接）: " OUTER_PORT
read -p "请输入连接密码: " PASSWORD

# 校验输入
if [ -z "$SERVER_DOMAIN" ] || [ -z "$INNER_PORT" ] || [ -z "$OUTER_PORT" ] || [ -z "$PASSWORD" ]; then
  echo "❌ 错误：所有字段都不能为空，安装终止。"
  exit 1
fi

# ===== 安装 Hysteria2 可执行文件 =====
wget -O /usr/local/bin/hysteria https://download.hysteria.network/app/latest/hysteria-linux-amd64 --no-check-certificate
chmod +x /usr/local/bin/hysteria

# ===== 创建配置目录与证书 =====
mkdir -p /etc/hysteria
openssl req -x509 -nodes -newkey ec:<(openssl ecparam -name prime256v1) \
  -keyout /etc/hysteria/server.key \
  -out /etc/hysteria/server.crt \
  -subj "/CN=bing.com" -days 36500

# ===== 写入配置文件 =====
cat > /etc/hysteria/config.yaml <<EOF
listen: :$INNER_PORT

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

# ===== 显示连接信息 =====
echo "------------------------------------------------------------------------"
echo "✅ Hysteria2 已安装并使用 nohup 启动"
echo "监听端口（内网）：$INNER_PORT"
echo "对外端口：$OUTER_PORT"
echo "密码：$PASSWORD"
echo "配置文件路径：/etc/hysteria/config.yaml"
echo "------------------------------------------------------------------------"
echo "🎯 客户端连接（V2RayN / Clash）："
echo "hy2://${PASSWORD}@${SERVER_DOMAIN}:${OUTER_PORT}?sni=bing.com&insecure=1#claw.cloud-hy2"
echo "------------------------------------------------------------------------"
echo "🧹 若需卸载："
echo "killall hysteria"
echo "rm -rf /etc/hysteria /usr/local/bin/hysteria"
echo "------------------------------------------------------------------------"
