#!/bin/bash

GREEN="\033[1;32m"
YELLOW="\033[1;33m"
BLUE="\033[1;34m"
CYAN="\033[1;36m"
RED="\033[1;31m"
BOLD="\033[1m"
RESET="\033[0m"

# ===== 安装依赖（静默）=====
apk update >/dev/null 2>&1
apk add --no-cache curl wget bash openssl ca-certificates >/dev/null 2>&1

# ===== 输入参数 =====
read -p "请输入 爪云分配的外网域名（如 southeast-1.clawcloudrun.com）: " SERVER_DOMAIN
read -p "请输入内网监听端口（如 30008，用于配置文件）: " IN_PORT
read -p "请输入外网连接端口（爪云分配的udp端口，用于客户端连接）: " OUT_PORT
read -p "请输入连接密码UUID: " PASSWORD

if [ -z "$SERVER_DOMAIN" ] || [ -z "$IN_PORT" ] || [ -z "$OUT_PORT" ] || [ -z "$PASSWORD" ]; then
  echo -e "${RED}❌ 错误：所有字段不能为空，安装终止。${RESET}"
  exit 1
fi

# ===== 下载 Hysteria2 主程序（静默）=====
wget -q -O /usr/local/bin/hysteria https://download.hysteria.network/app/latest/hysteria-linux-amd64
chmod +x /usr/local/bin/hysteria

# ===== 自签证书（静默）=====
mkdir -p /etc/hysteria
openssl req -x509 -nodes -newkey ec:<(openssl ecparam -name prime256v1) \
  -keyout /etc/hysteria/server.key \
  -out /etc/hysteria/server.crt \
  -subj "/CN=bing.com" -days 36500 >/dev/null 2>&1

# ===== 写入配置文件 =====
cat > /etc/hysteria/config.yaml <<EOF
listen: :$IN_PORT

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

# ===== 启动服务（后台静默）=====
nohup /usr/local/bin/hysteria server -c /etc/hysteria/config.yaml >/dev/null 2>&1 &

# ===== 获取公网IP及国家码 =====
SERVER_IP=$(curl -s https://api.ipify.org)
COUNTRY_CODE=$(curl -s https://ipapi.co/${SERVER_IP}/country/ || echo "XX")

# ===== 显示最终信息 =====
echo -e "\n${GREEN}------------------------------------------------------------------------${RESET}"
echo -e "✅ ${BOLD}Hysteria2 安装成功并已后台运行${RESET}"
echo -e "监听端口（内网）：${YELLOW}${IN_PORT}${RESET}"
echo -e "对外端口（UDP）：${YELLOW}${OUT_PORT}${RESET}"
echo -e "密码：${YELLOW}${PASSWORD}${RESET}"
echo -e "${GREEN}------------------------------------------------------------------------${RESET}"
echo -e "🎯 ${BOLD}客户端连接配置：${RESET}"
echo -e "${CYAN}hy2://${PASSWORD}@${SERVER_DOMAIN}:${OUT_PORT}?sni=bing.com&insecure=1#claw.cloud-hy2-${COUNTRY_CODE}${RESET}"
echo -e "${GREEN}------------------------------------------------------------------------${RESET}"
echo -e "🧹 卸载方法："
echo -e "killall hysteria"
echo -e "rm -rf /etc/hysteria /usr/local/bin/hysteria"
echo -e "${GREEN}------------------------------------------------------------------------${RESET}"
