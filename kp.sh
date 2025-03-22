#!/bin/bash
# Schedule setting: */10 * * * * /bin/bash /root/kp.sh Run every 10 minutes
# Add rules to serv00 variables:
# Keep alive? cron and multi-function web page, you can choose one or use them together
# RES (required): n means not to reset the deployment every time, y means to reset the deployment every time. REP (required): n means not to reset the random port (three ports are left blank), y means to reset the port (three ports are left blank). SSH_USER (required) indicates the serv00 account name. SSH_PASS (required) indicates the serv00 password. REALITY indicates the reality domain name (leaving it blank indicates the official domain name of serv00: your serv00 account name.serv00.net). SUUID indicates uuid (leaving it blank indicates a random uuid). TCP1_PORT indicates the tcp port of vless (leaving it blank indicates a random tcp port). TCP2_PORT indicates the tcp port of vmess (leaving it blank indicates a random tcp port). UDP_PORT indicates the udp port of hy2 (leave it blank for a random udp port). HOST (required) indicates the domain name of the serv00 server. ARGO_DOMAIN indicates the argo fixed domain name (leave it blank for a temporary domain name). ARGO_AUTH indicates the argo fixed domain name token (leave it blank for a temporary domain name).
# Required variables: RES, REP, SSH_USER, SSH_PASS, HOST
# Note that []"",: do not delete these symbols randomly, align them according to the rules
# One {serv00 server} per line, one service is also acceptable, with , at the end, and no , at the end of the last server
ACCOUNTS='[
{"RES":"n", "REP":"n", "SSH_USER":"Your serv00 account name", "SSH_PASS":"Your serv00 account password", "REALITY":"Your serv00 account name.serv00.net", "SUUID":"Self-set UUID", "TCP1_PORT":"vless TCP port", "TCP2_PORT":"vmess TCP port", "UDP_PORT":"hy2 UDP port", "HOST":"s1.serv00.com", "ARGO_DOMAIN":"", "ARGO_AUTH":""},
{"RES":"y", "REP":"y", "SSH_USER":"123456", "SSH_PASS":"7890000", "REALITY":"time.is", "SUUID":"73203ee6-b3fa-4a3d-b5df-6bb2f55073ad", "TCP1_PORT":"", "TCP2_PORT":"", "UDP_PORT":"", "HOST":"s16.serv00.com", "ARGO_DOMAIN":"Your argo fixed domain name", "ARGO_AUTH":"eyJhIjoiOTM3YzFjYWI88552NTFiYTM4ZTY0ZDQzRmlNelF0TkRBd1pUQTRNVEJqTUdVeCJ9"}
]'
run_remote_command() {
local RES=$1
local REP=$2
local SSH_USER=$3
local SSH_PASS=$4
local REALITY=${5}
local SUUID=$6
local TCP1_PORT=$7
local TCP2_PORT=$8
local UDP_PORT=$9
local HOST=${10}
local ARGO_DOMAIN=${11}
local ARGO_AUTH=${12}
  if [ -z "${ARGO_DOMAIN}" ]; then
    echo "Argo domain name is empty, apply for Argo temporary domain name"
else
echo "Argo has set a fixed domain name：${ARGO_DOMAIN}"
  fi
  remote_command="export reym=$REALITY UUID=$SUUID vless_port=$TCP1_PORT vmess_port=$TCP2_PORT hy2_port=$UDP_PORT reset=$RES resport=$REP ARGO_DOMAIN=${ARGO_DOMAIN} ARGO_AUTH=${ARGO_AUTH} && bash <(curl -Ls https://raw.githubusercontent.com/yonggekkk/sing-box-yg/main/serv00keep.sh)"
  echo "Executing remote command on $HOST as $SSH_USER with command: $remote_command"
  sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no "$SSH_USER@$HOST" "$remote_command"
}
if  cat /etc/issue /proc/version /etc/os-release 2>/dev/null | grep -q -E -i "openwrt"; then
opkg update
opkg install sshpass curl jq
else
    if [ -f /etc/debian_version ]; then
        package_manager="apt-get install -y"
        apt-get update >/dev/null 2>&1
    elif [ -f /etc/redhat-release ]; then
        package_manager="yum install -y"
    elif [ -f /etc/fedora-release ]; then
        package_manager="dnf install -y"
    elif [ -f /etc/alpine-release ]; then
        package_manager="apk add"
    fi
    $package_manager sshpass curl jq cron >/dev/null 2>&1 &
fi
echo "*****************************************************"
echo "*****************************************************"
echo "Automatic remote deployment of Serv00 three-in-one protocol script [VPS + soft router]"
echo "version ：V25.2.26"
echo "*****************************************************"
echo "*****************************************************"
              count=0  
           for account in $(echo "${ACCOUNTS}" | jq -c '.[]'); do
              count=$((count+1))
              RES=$(echo $account | jq -r '.RES')
              REP=$(echo $account | jq -r '.REP')              
              SSH_USER=$(echo $account | jq -r '.SSH_USER')
              SSH_PASS=$(echo $account | jq -r '.SSH_PASS')
              REALITY=$(echo $account | jq -r '.REALITY')
              SUUID=$(echo $account | jq -r '.SUUID')
              TCP1_PORT=$(echo $account | jq -r '.TCP1_PORT')
              TCP2_PORT=$(echo $account | jq -r '.TCP2_PORT')
              UDP_PORT=$(echo $account | jq -r '.UDP_PORT')
              HOST=$(echo $account | jq -r '.HOST')
              ARGO_DOMAIN=$(echo $account | jq -r '.ARGO_DOMAIN')
              ARGO_AUTH=$(echo $account | jq -r '.ARGO_AUTH') 
          if sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no "$SSH_USER@$HOST" -q exit; then
            echo "🎉Congratulations! ✅The [$count]th server has been successfully connected! 🚀Server address: $HOST, account name：$SSH_USER"   
          if [ -z "${ARGO_DOMAIN}" ]; then
           check_process="ps aux | grep '[c]onfig' > /dev/null && ps aux | grep [l]ocalhost:$TCP2_PORT > /dev/null"
            else
           check_process="ps aux | grep '[c]onfig' > /dev/null && ps aux | grep '[t]oken $ARGO_AUTH' > /dev/null"
           fi
          if ! sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no "$SSH_USER@$HOST" "$check_process" || [[ "$RES" =~ ^[Yy]$ ]]; then
            echo "⚠️Detect that the main process or argo process is not started, or perform a reset" 
            echo "⚠️Start repairing or resetting deployment now... Please wait"
             output=$(run_remote_command "$RES" "$REP" "$SSH_USER" "$SSH_PASS" "${REALITY}" "$SUUID" "$TCP1_PORT" "$TCP2_PORT" "$UDP_PORT" "$HOST" "${ARGO_DOMAIN}" "${ARGO_AUTH}")
            echo "Remote command execution results：$output"
          else
            echo "🎉Congratulations! ✅All processes are detected to be running normally "
            SSH_USER_LOWER=$(echo "$SSH_USER" | tr '[:upper:]' '[:lower:]')
            sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no "$SSH_USER@$HOST" "
            echo \"The configuration is shown below：\"
            cat $HOME/domains/${SSH_USER_LOWER}.serv00.net/logs/list.txt
            echo \"====================================================\""
            fi
           else
            echo "===================================================="
            echo "💥Tragic! ❌Connection to the [$count]th server failed! 🚀Server address: $HOST, account name: $SSH_USER"
            echo "⚠️The account name, password, or server name may be entered incorrectly, or the current server is under maintenance"  
            echo "===================================================="
           fi
            done
