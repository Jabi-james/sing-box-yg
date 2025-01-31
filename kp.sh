#!/bin/bash
# Schedule setting: */10 * * * * /bin/bash /root/kp.sh Run every 10 minutes
# serv00 variable addition rules:
# Recommendation: To ensure node availability, it is recommended not to set the port on the Serv00 webpage. The script will randomly generate a valid port. The first run will interrupt SSH. Please set RES to n and then execute
# RES (required): n means not to reset the deployment each time, and y means to reset the deployment each time. SSH_USER (required) indicates the serv00 account name. SSH_PASS (required) indicates the serv00 password. REALITY indicates the reality domain name (leave it blank to indicate the official domain name of serv00: your serv00 account name.serv00.net). SUUID indicates uuid (leave it blank to indicate a random uuid). TCP1_PORT indicates the tcp port of vless (leave it blank to indicate a random tcp port). TCP2_PORT indicates the tcp port of vmess (leave it blank to indicate a random tcp port). UDP_PORT indicates the udp port of hy2 (leave blank for a random udp port). HOST (required) indicates the domain name for logging into the serv00 server. ARGO_DOMAIN indicates the argo fixed domain name (leave blank for a temporary domain name). ARGO_AUTH indicates the argo fixed domain name token (leave blank for a temporary domain name).
# Required variables: RES, SSH_USER, SSH_PASS, HOST
# Note []",: Do not delete these symbols randomly, align them according to the rules
# One {serv00 server} per line, one service is also OK, use, at the end to separate, the last server does not need to be separated by,
ACCOUNTS='[
{"RES":"n", "SSH_USER":"your serv00 account name", "SSH_PASS":"your serv00 account password", "REALITY":"your serv00 account name.serv00.net", "SUUID":"self-set UUID", "TCP1_PORT":"vless tcp port", "TCP2_PORT":"vmess tcp port", "UDP_PORT":"hy2 udp port", "HOST":"s1.serv00.com", "ARGO_DOMAIN":"", "ARGO_AUTH":""},
{"RES":"y", "SSH_USER":"123456", "SSH_PASS":"7890000", "REALITY":"time.is", "SUUID":"73203ee6-b3fa-4a3d-b5df-6bb2f55073ad", "TCP1_PORT":"55254", "TCP2_PORT":"55255", "UDP_PORT":"55256", "HOST":"s16.serv00.com", "ARGO_DOMAIN":"Your argo fixed domain name", "ARGO_AUTH":"eyJhIjoiOTM3YzFjYWI88552NTFiYTM4ZTY0ZDQzRmlNelF0TkRBd1pUQTRNVEJqTUdVeCJ9"} ]' run_remote_command() { localRES=$1 local SSH_USER=$2 local SSH_PASS=$3 local REALITY=$4
local SUUID=$5
local TCP1_PORT=$6
local TCP2_PORT=$7
local UDP_PORT=$8
local HOST=$9
local ARGO_DOMAIN=${10}
local ARGO_AUTH=${11}
if [ -z "${ARGO_DOMAIN}" ]; then
echo "Argo domain name is empty, apply for Argo temporary domain name"
else
echo "Argo has set a fixed domain name: ${ARGO_DOMAIN}"
fi
remote_command="export reym=$REALITY UUID=$SUUID vless_port=$TCP1_PORT vmess_port=$TCP2_PORT hy2_port=$UDP_PORT reset=$RES ARGO_DOMAIN=${ARGO_DOMAIN} ARGO_AUTH=${ARGO_AUTH} && bash <(curl -Ls https://raw.githubusercontent.com/yonggekkk/sing-box-yg/main/serv00keep.sh)" echo "Executing remote command on $HOST as $SSH_USER with command: $remote_command" sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no "$SSH_USER@$HOST" "$remote_command" } if cat /etc/issue /proc/version /etc/os-release 2>/dev/null | grep -q -E -i "openwrt"; then opkg update opkg install sshpass curl jq else if [ -f /etc/debian_version ]; then package_manager="apt-get install -y" apt-get update >/dev/null 2>&1 elif [ -f /etc/redhat-release ]; then package_manager="yum install -y"
elif [ -f /etc/fedora-release ]; then
package_manager="dnf install -y"
elif [ -f /etc/alpine-release ]; then
package_manager="apk add"
fi
$package_manager sshpass curl jq cron >/dev/null 2>&1 &
fi
echo "********************************************************"
echo "********************************************************"
echo "Yongge Github Project: github.com/yonggekkk"
echo "Yongge Blogger Blog: ygkkk.blogspot.com"
echo "Yongge YouTube Channel: www.youtube.com/@ygkkk"
echo "Automatically deploy Serv00 three-in-one protocol script remotely [VPS + soft router]"
echo "Version: V25.1.22"
echo "*****************************************************"
echo "********************************************************"
count=0
for account in $(echo "${ACCOUNTS}" | jq -c '.[]'); do
count=$((count+1))
RES=$(echo $account | jq -r '.RES')
SSH_USER=$(echo $account | jq -r '.SSH_USER')
SSH_PASS=$(echo $account | jq -r '.SSH_PASS')
done
