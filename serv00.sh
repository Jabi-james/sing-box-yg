#!/bin/bash
re="\033[0m"
red="\033[1;91m"
green="\e[1;32m"
yellow="\e[1;33m"
purple="\e[1;35m"
red() { echo -e "\e[1;91m$1\033[0m"; }
green() { echo -e "\e[1;32m$1\033[0m"; }
yellow() { echo -e "\e[1;33m$1\033[0m"; }
purple() { echo -e "\e[1;35m$1\033[0m"; }
reading() { read -p "$(red "$1")" "$2"; }
USERNAME=$(whoami | tr '[:upper:]' '[:lower:]')
HOSTNAME=$(hostname)
devil www add ${USERNAME}.serv00.net php > /dev/null 2>&1
FILE_PATH="${HOME}/domains/${USERNAME}.serv00.net/public_html"
WORKDIR="${HOME}/domains/${USERNAME}.serv00.net/logs"
[ -d "$WORKDIR" ] || (mkdir -p "$WORKDIR" && chmod 777 "$WORKDIR")

read_ip() {
cat ip.txt
reading "Please enter any one of the three IPs above (it is recommended to press Enter to automatically select an available IP by default): " IP
if [[ -z "$IP" ]]; then
IP=$(grep -m 1 "Available" ip.txt | awk -F ':' '{print $1}')
if [ -z "$IP" ]; then
IP=$(okip)
if [ -z "$IP" ]; then
IP=$(head -n 1 ip.txt | awk -F ':' '{print $1}')
fi
fi
fi
green "The IP you selected is: $IP"
}

read_uuid() {
        reading "Please enter a unified uuid password (it is recommended to press Enter to default to random): " UUID
        if [[ -z "$UUID" ]]; then
	   UUID=$(uuidgen -r)
        fi
	green "Your uuid is: $UUID"
}

read_reym() {
yellow "Method 1: Enter to use CF domain name, support proxyip + non-standard port reverse IP function (recommended)"
yellow "Method 2: Enter s to use Serv00's own domain name, do not support proxyip function (recommended)"
yellow "Method 3: Support other domain names, pay attention to comply with reality domain name rules"
reading "Please enter the reality domain name [Please select Enter or s or enter the domain name】: " reym
        if [[ -z "$reym" ]]; then
           reym=www.speedtest.net
	elif [[ "$reym" == "s" || "$reym" == "S" ]]; then
           reym=$USERNAME.serv00.net
        fi
	green "Your reality domain name is: $reym"
}

check_port () {
port_list=$(devil port list)
tcp_ports=$(echo "$port_list" | grep -c "tcp")
udp_ports=$(echo "$port_list" | grep -c "udp")

if [[ $tcp_ports -ne 2 || $udp_ports -ne 1 ]]; then
    red "The number of ports does not meet the requirement and is being adjusted..."

    if [[ $tcp_ports -gt 2 ]]; then
        tcp_to_delete=$((tcp_ports - 2))
        echo "$port_list" | awk '/tcp/ {print $1, $2}' | head -n $tcp_to_delete | while read port type; do
            devil port del $type $port
            green "Deleted TCP port: $port"
        done
    fi

    if [[ $udp_ports -gt 1 ]]; then
        udp_to_delete=$((udp_ports - 1))
        echo "$port_list" | awk '/udp/ {print $1, $2}' | head -n $udp_to_delete | while read port type; do
            devil port del $type $port
            green "Deleted UDP port: $port"
        done
    fi

    if [[ $tcp_ports -lt 2 ]]; then
        tcp_ports_to_add=$((2 - tcp_ports))
        tcp_ports_added=0
        while [[ $tcp_ports_added -lt $tcp_ports_to_add ]]; do
            tcp_port=$(shuf -i 10000-65535 -n 1) 
            result=$(devil port add tcp $tcp_port 2>&1)
            if [[ $result == *"succesfully"* ]]; then
                green "TCP port has been added: $tcp_port"
                if [[ $tcp_ports_added -eq 0 ]]; then
                    tcp_port1=$tcp_port
                else
                    tcp_port2=$tcp_port
                fi
                tcp_ports_added=$((tcp_ports_added + 1))
            else
                yellow "port $tcp_port Unavailable, try another port..."
            fi
        done
    fi

    if [[ $udp_ports -lt 1 ]]; then
        while true; do
            udp_port=$(shuf -i 10000-65535 -n 1) 
            result=$(devil port add udp $udp_port 2>&1)
            if [[ $result == *"succesfully"* ]]; then
                green "UDP port added: $udp_port"
                break
            else
                yellow "Port $udp_port is not available, try another port..."
            fi
        done
    fi
green "The port has been adjusted. The ssh connection will be disconnected. Please reconnect ssh and re-execute the script"    devil binexec on >/dev/null 2>&1
    kill -9 $(ps -o ppid= -p $$) >/dev/null 2>&1
else
    tcp_ports=$(echo "$port_list" | awk '/tcp/ {print $1}')
    tcp_port1=$(echo "$tcp_ports" | sed -n '1p')
    tcp_port2=$(echo "$tcp_ports" | sed -n '2p')
    udp_port=$(echo "$port_list" | awk '/udp/ {print $1}')

purple "Current TCP ports: $tcp_port1 and $tcp_port2"
purple "Current UDP port: $udp_port"
fi

export vless_port=$tcp_port1
export vmess_port=$tcp_port2
export hy2_port=$udp_port
green "your vless-reality port: $vless_port"
green "your vmess-ws port (set Argo fixed domain name port): $vmess_port"
green "your hysteria2 port: $hy2_port"
sleep 2
}

install_singbox() {
if [[ -e $WORKDIR/list.txt ]]; then
yellow "Sing-box has been installed. Please select 2 to uninstall first, then install" && exit
fi
yellow "To ensure node availability, it is recommended not to set the port on the Serv00 web page. The script will randomly generate a valid port"
sleep 2
        cd $WORKDIR
	echo
	read_ip
 	echo
        read_reym
	echo
	read_uuid
        echo
        check_port
	echo
        sleep 2
        argo_configure
	echo
        download_and_run_singbox
	cd
	echo
	servkeep
        cd $WORKDIR
        echo
        get_links
	cd
}

uninstall_singbox() {
  reading "\Are you sure you want to uninstall？【y/n】: " choice
    case "$choice" in
       [Yy])
	  bash -c 'ps aux | grep $(whoami) | grep -v "sshd\|bash\|grep" | awk "{print \$2}" | xargs -r kill -9 >/dev/null 2>&1' >/dev/null 2>&1
          rm -rf domains serv00.sh serv00keep.sh
	  crontab -l | grep -v "serv00keep" >rmcron
          crontab rmcron >/dev/null 2>&1
          rm rmcron
          clear
          green "已完全卸载"
          ;;
        [Nn]) exit 0 ;;
    	*) red "Invalid selection, please enter y or n" && menu ;;
    esac
}

kill_all_tasks() {
reading "\Clean up all processes and clear all installed content. The ssh connection will be exited. Are you sure you want to continue cleaning?？【y/n】: " choice
  case "$choice" in
    [Yy]) 
    bash -c 'ps aux | grep $(whoami) | grep -v "sshd\|bash\|grep" | awk "{print \$2}" | xargs -r kill -9 >/dev/null 2>&1' >/dev/null 2>&1
    rm -rf domains serv00.sh serv00keep.sh
    crontab -l | grep -v "serv00keep" >rmcron
    crontab rmcron >/dev/null 2>&1
    rm rmcron
    find ~ -type f -exec chmod 644 {} \; 2>/dev/null
    find ~ -type d -exec chmod 755 {} \; 2>/dev/null
    find ~ -type f -exec rm -f {} \; 2>/dev/null
    find ~ -type d -empty -exec rmdir {} \; 2>/dev/null
    find ~ -exec rm -rf {} \; 2>/dev/null
    killall -9 -u $(whoami)
    ;;
    *) menu ;;
  esac
}

# Generating argo Config
argo_configure() {
  while true; do
yellow "Method 1: Argo temporary tunnel (no domain name required, recommended)"
yellow "Method 2: Argo fixed tunnel (domain name required, CF needs to be set to extract token)"
echo -e "${red}Note: ${purple}When using token for Argo fixed tunnel, you need to set the tunnel port in the cloudflare backend, which must be consistent with the tcp port $vmess_port of vmess-ws)${re}"
reading "Enter g to use Argo fixed tunnel, press Enter to skip to use Argo temporary tunnel [Please select g or press Enter]: " argo_choice
if [[ "$argo_choice" != "g" && "$argo_choice" != "G" && -n "$argo_choice" ]]; then
red "Invalid choice, please enter g or press Enter"
        continue
    fi
    if [[ "$argo_choice" == "g" || "$argo_choice" == "G" ]]; then
reading "Please enter the argo fixed tunnel domain name: " ARGO_DOMAIN
green "Your argo fixed tunnel domain name is: $ARGO_DOMAIN"
reading "Please enter the argo fixed tunnel key (when you paste the token, it must start with ey): " ARGO_AUTH
green "Your argo fixed tunnel key is: $ARGO_AUTH"
    else
        green "Using Argo Temporary Tunnels"
    fi
    break
done

  if [[ $ARGO_AUTH =~ TunnelSecret ]]; then
    echo $ARGO_AUTH > tunnel.json
    cat > tunnel.yml << EOF
tunnel: $(cut -d\" -f12 <<< "$ARGO_AUTH")
credentials-file: tunnel.json
protocol: http2

ingress:
  - hostname: $ARGO_DOMAIN
    service: http://localhost:$vmess_port
    originRequest:
      noTLSVerify: true
  - service: http_status:404
EOF
  fi
}

# Download Dependency Files
download_and_run_singbox() {
  ARCH=$(uname -m) && DOWNLOAD_DIR="." && mkdir -p "$DOWNLOAD_DIR" && FILE_INFO=()
  if [ "$ARCH" == "arm" ] || [ "$ARCH" == "arm64" ] || [ "$ARCH" == "aarch64" ]; then
      FILE_INFO=("https://github.com/eooce/test/releases/download/arm64/sb web" "https://github.com/eooce/test/releases/download/arm64/bot13 bot")
  elif [ "$ARCH" == "amd64" ] || [ "$ARCH" == "x86_64" ] || [ "$ARCH" == "x86" ]; then
      FILE_INFO=("https://github.com/yonggekkk/Cloudflare_vless_trojan/releases/download/serv00/sb web" "https://github.com/yonggekkk/Cloudflare_vless_trojan/releases/download/serv00/server bot")
  else
      echo "Unsupported architecture: $ARCH"
      exit 1
  fi
declare -A FILE_MAP
generate_random_name() {
    local chars=abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890
    local name=""
    for i in {1..6}; do
        name="$name${chars:RANDOM%${#chars}:1}"
    done
    echo "$name"
}

download_with_fallback() {
    local URL=$1
    local NEW_FILENAME=$2

    curl -L -sS --max-time 2 -o "$NEW_FILENAME" "$URL" &
    CURL_PID=$!
    CURL_START_SIZE=$(stat -c%s "$NEW_FILENAME" 2>/dev/null || echo 0)
    
    sleep 1
    CURL_CURRENT_SIZE=$(stat -c%s "$NEW_FILENAME" 2>/dev/null || echo 0)
    
    if [ "$CURL_CURRENT_SIZE" -le "$CURL_START_SIZE" ]; then
        kill $CURL_PID 2>/dev/null
        wait $CURL_PID 2>/dev/null
        wget -q -O "$NEW_FILENAME" "$URL"
        echo -e "\e[1;32mDownloading $NEW_FILENAME by wget\e[0m"
    else
        wait $CURL_PID
        echo -e "\e[1;32mDownloading $NEW_FILENAME by curl\e[0m"
    fi
}

for entry in "${FILE_INFO[@]}"; do
    URL=$(echo "$entry" | cut -d ' ' -f 1)
    RANDOM_NAME=$(generate_random_name)
    NEW_FILENAME="$DOWNLOAD_DIR/$RANDOM_NAME"
    
    if [ -e "$NEW_FILENAME" ]; then
        echo -e "\e[1;32m$NEW_FILENAME already exists, Skipping download\e[0m"
    else
        download_with_fallback "$URL" "$NEW_FILENAME"
    fi
    
    chmod +x "$NEW_FILENAME"
    FILE_MAP[$(echo "$entry" | cut -d ' ' -f 2)]="$NEW_FILENAME"
done
wait

output=$(./"$(basename ${FILE_MAP[web]})" generate reality-keypair)
private_key=$(echo "${output}" | awk '/PrivateKey:/ {print $2}')
public_key=$(echo "${output}" | awk '/PublicKey:/ {print $2}')
echo "${private_key}" > private_key.txt
echo "${public_key}" > public_key.txt

openssl ecparam -genkey -name prime256v1 -out "private.key"
openssl req -new -x509 -days 3650 -key "private.key" -out "cert.pem" -subj "/CN=$USERNAME.serv00.net"

nb=$(hostname | cut -d '.' -f 1 | tr -d 's')
if [ "$nb" == "14" ]; then
ytb='"jnn-pa.googleapis.com",'
fi
hy1p=$(sed -n '1p' hy2ip.txt)
hy2p=$(sed -n '2p' hy2ip.txt)
hy3p=$(sed -n '3p' hy2ip.txt)
  cat > config.json << EOF
{
  "log": {
    "disabled": true,
    "level": "info",
    "timestamp": true
  },
    "inbounds": [
    {
       "tag": "hysteria-in",
       "type": "hysteria2",
       "listen": "$hy1p",
       "listen_port": $hy2_port,
       "users": [
         {
             "password": "$UUID"
         }
     ],
     "masquerade": "https://www.bing.com",
     "ignore_client_bandwidth":false,
     "tls": {
         "enabled": true,
         "alpn": [
             "h3"
         ],
         "certificate_path": "cert.pem",
         "key_path": "private.key"
        }
    },
        {
       "tag": "hysteria-in",
       "type": "hysteria2",
       "listen": "$hy2p",
       "listen_port": $hy2_port,
       "users": [
         {
             "password": "$UUID"
         }
     ],
     "masquerade": "https://www.bing.com",
     "ignore_client_bandwidth":false,
     "tls": {
         "enabled": true,
         "alpn": [
             "h3"
         ],
         "certificate_path": "cert.pem",
         "key_path": "private.key"
        }
    },
        {
       "tag": "hysteria-in",
       "type": "hysteria2",
       "listen": "$hy3p",
       "listen_port": $hy2_port,
       "users": [
         {
             "password": "$UUID"
         }
     ],
     "masquerade": "https://www.bing.com",
     "ignore_client_bandwidth":false,
     "tls": {
         "enabled": true,
         "alpn": [
             "h3"
         ],
         "certificate_path": "cert.pem",
         "key_path": "private.key"
        }
    },
    {
        "tag": "vless-reality-vesion",
        "type": "vless",
        "listen": "::",
        "listen_port": $vless_port,
        "users": [
            {
              "uuid": "$UUID",
              "flow": "xtls-rprx-vision"
            }
        ],
        "tls": {
            "enabled": true,
            "server_name": "$reym",
            "reality": {
                "enabled": true,
                "handshake": {
                    "server": "$reym",
                    "server_port": 443
                },
                "private_key": "$private_key",
                "short_id": [
                  ""
                ]
            }
        }
    },
{
      "tag": "vmess-ws-in",
      "type": "vmess",
      "listen": "::",
      "listen_port": $vmess_port,
      "users": [
      {
        "uuid": "$UUID"
      }
    ],
    "transport": {
      "type": "ws",
      "path": "$UUID-vm",
      "early_data_header_name": "Sec-WebSocket-Protocol"
      }
    }
 ],
    "outbounds": [
     {
        "type": "wireguard",
        "tag": "wg",
        "server": "162.159.192.200",
        "server_port": 4500,
        "local_address": [
                "172.16.0.2/32",
                "2606:4700:110:8f77:1ca9:f086:846c:5f9e/128"
        ],
        "private_key": "wIxszdR2nMdA7a2Ul3XQcniSfSZqdqjPb6w6opvf5AU=",
        "peer_public_key": "bmXOC+F1FxEMF9dyiK2H5/1SUtzH0JuVo51h2wPfgyo=",
        "reserved": [
            126,
            246,
            173
        ]
    },
    {
      "type": "direct",
      "tag": "direct"
    },
    {
      "type": "block",
      "tag": "block"
    }
  ],
   "route": {
    "rules": [
    {
     "domain": [
     $ytb
     "oh.my.god"
      ],
     "outbound": "wg"
    }
    ],
    "final": "direct"
    }  
}
EOF

if [ -e "$(basename "${FILE_MAP[web]}")" ]; then
   echo "$(basename "${FILE_MAP[web]}")" > sb.txt
   sbb=$(cat sb.txt)
    nohup ./"$sbb" run -c config.json >/dev/null 2>&1 &
    sleep 5
if pgrep -x "$sbb" > /dev/null; then
    green "$sbb The main process has been started"
else
for ((i=1; i<=5; i++)); do
red "$sbb The main process has not been started, restarting... (Number of attempts: $i)"
pkill -x "$sbb"
nohup ./"$sbb" run -c config.json >/dev/null 2>&1 &
sleep 5
if pgrep -x "$sbb" > /dev/null; then
purple "$sbb The main process has been successfully restarted"
        break
    fi
    if [[ $i -eq 5 ]]; then
        red "$sbb Master process restart faile"
    fi
done
fi
fi

if [ -e "$(basename "${FILE_MAP[bot]}")" ]; then
   echo "$(basename "${FILE_MAP[bot]}")" > ag.txt
   agg=$(cat ag.txt)
    rm -rf boot.log
    if [[ $ARGO_AUTH =~ ^[A-Z0-9a-z=]{120,250}$ ]]; then
      #args="tunnel --edge-ip-version auto --no-autoupdate --protocol http2 run --token ${ARGO_AUTH}"
      args="tunnel --no-autoupdate run --token ${ARGO_AUTH}"
    elif [[ $ARGO_AUTH =~ TunnelSecret ]]; then
      args="tunnel --edge-ip-version auto --config tunnel.yml run"
    else
     #args="tunnel --edge-ip-version auto --no-autoupdate --protocol http2 --logfile boot.log --loglevel info --url http://localhost:$vmess_port"
     args="tunnel --url http://localhost:$vmess_port --no-autoupdate --logfile boot.log --loglevel info"
    fi
    nohup ./"$agg" $args >/dev/null 2>&1 &
    sleep 10
if pgrep -x "$agg" > /dev/null; then
    green "$agg Argo process has started"
else
red "$agg Argo process has not started, restarting..."
    pkill -x "$agg"
    nohup ./"$agg" "${args}" >/dev/null 2>&1 &
    sleep 5
    purple "$agg The Argo process has been restarted"
fi
fi
sleep 2
if ! pgrep -x "$(cat sb.txt)" > /dev/null; then
red "The main process has not started. Check the following situations one by one"
yellow "1. Is the web page permission enabled?"
yellow "2. Delete all ports in the web page background and let the script automatically generate random available ports"
yellow "3. Select 5 to reset"
yellow "4. Is the current Serv00 server crashed? Try again later"
red "5. After trying all the above, I will just lie down and let the process keep it alive. I will check again later"
sleep 6
fi
}

get_argodomain() {
  if [[ -n $ARGO_AUTH ]]; then
    echo "$ARGO_DOMAIN" > gdym.log
    echo "$ARGO_DOMAIN"
  else
    local retry=0
    local max_retries=6
    local argodomain=""
    while [[ $retry -lt $max_retries ]]; do
    ((retry++)) 
    argodomain=$(cat boot.log 2>/dev/null | grep -a trycloudflare.com | awk 'NR==2{print}' | awk -F// '{print $2}' | awk '{print $1}')
      if [[ -n $argodomain ]]; then
        break
      fi
      sleep 2
    done  
    if [ -z ${argodomain} ]; then
    argodomain="Argo temporary domain name acquisition failed temporarily, Argo node is temporarily unavailable"
    fi
    echo "$argodomain"
  fi
}

get_links(){
argodomain=$(get_argodomain)
echo -e "\e[1;32mArgo域名：\e[1;35m${argodomain}\e[0m\n"
ISP=$(curl -sL --max-time 5 https://speed.cloudflare.com/meta | awk -F\" '{print $26}' | sed -e 's/ /_/g' || echo "0")
get_name() { if [ "$HOSTNAME" = "s1.ct8.pl" ]; then SERVER="CT8"; else SERVER=$(echo "$HOSTNAME" | cut -d '.' -f 1); fi; echo "$SERVER"; }
NAME="$ISP-$(get_name)"
rm -rf jh.txt
vl_link="vless://$UUID@$IP:$vless_port?encryption=none&flow=xtls-rprx-vision&security=reality&sni=$reym&fp=chrome&pbk=$public_key&type=tcp&headerType=none#$NAME-reality"
echo "$vl_link" >> jh.txt
vmws_link="vmess://$(echo "{ \"v\": \"2\", \"ps\": \"$NAME-vmess-ws\", \"add\": \"$IP\", \"port\": \"$vmess_port\", \"id\": \"$UUID\", \"aid\": \"0\", \"scy\": \"auto\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"\", \"path\": \"/$UUID-vm?ed=2048\", \"tls\": \"\", \"sni\": \"\", \"alpn\": \"\", \"fp\": \"\"}" | base64 -w0)"
echo "$vmws_link" >> jh.txt
vmatls_link="vmess://$(echo "{ \"v\": \"2\", \"ps\": \"$NAME-vmess-ws-tls-argo\", \"add\": \"icook.hk\", \"port\": \"8443\", \"id\": \"$UUID\", \"aid\": \"0\", \"scy\": \"auto\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"$argodomain\", \"path\": \"/$UUID-vm?ed=2048\", \"tls\": \"tls\", \"sni\": \"$argodomain\", \"alpn\": \"\", \"fp\": \"\"}" | base64 -w0)"
echo "$vmatls_link" >> jh.txt
vma_link="vmess://$(echo "{ \"v\": \"2\", \"ps\": \"$NAME-vmess-ws-argo\", \"add\": \"icook.hk\", \"port\": \"8880\", \"id\": \"$UUID\", \"aid\": \"0\", \"scy\": \"auto\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"$argodomain\", \"path\": \"/$UUID-vm?ed=2048\", \"tls\": \"\"}" | base64 -w0)"
echo "$vma_link" >> jh.txt
hy2_link="hysteria2://$UUID@$IP:$hy2_port?sni=www.bing.com&alpn=h3&insecure=1#$NAME-hy2"
echo "$hy2_link" >> jh.txt
url=$(cat jh.txt 2>/dev/null)
baseurl=$(echo -e "$url" | base64 -w 0)

cat > sing_box.json <<EOF
{
  "log": {
    "disabled": false,
    "level": "info",
    "timestamp": true
  },
  "experimental": {
    "clash_api": {
      "external_controller": "127.0.0.1:9090",
      "external_ui": "ui",
      "external_ui_download_url": "",
      "external_ui_download_detour": "",
      "secret": "",
      "default_mode": "Rule"
       },
      "cache_file": {
            "enabled": true,
            "path": "cache.db",
            "store_fakeip": true
        }
    },
    "dns": {
        "servers": [
            {
                "tag": "proxydns",
                "address": "tls://8.8.8.8/dns-query",
                "detour": "select"
            },
            {
                "tag": "localdns",
                "address": "h3://223.5.5.5/dns-query",
                "detour": "direct"
            },
            {
                "tag": "dns_fakeip",
                "address": "fakeip"
            }
        ],
        "rules": [
            {
                "outbound": "any",
                "server": "localdns",
                "disable_cache": true
            },
            {
                "clash_mode": "Global",
                "server": "proxydns"
            },
            {
                "clash_mode": "Direct",
                "server": "localdns"
            },
            {
                "rule_set": "geosite-cn",
                "server": "localdns"
            },
            {
                 "rule_set": "geosite-geolocation-!cn",
                 "server": "proxydns"
            },
             {
                "rule_set": "geosite-geolocation-!cn",         
                "query_type": [
                    "A",
                    "AAAA"
                ],
                "server": "dns_fakeip"
            }
          ],
           "fakeip": {
           "enabled": true,
           "inet4_range": "198.18.0.0/15",
           "inet6_range": "fc00::/18"
         },
          "independent_cache": true,
          "final": "proxydns"
        },
      "inbounds": [
    {
      "type": "tun",
           "tag": "tun-in",
	  "address": [
      "172.19.0.1/30",
	  "fd00::1/126"
      ],
      "auto_route": true,
      "strict_route": true,
      "sniff": true,
      "sniff_override_destination": true,
      "domain_strategy": "prefer_ipv4"
    }
  ],
  "outbounds": [
    {
      "tag": "select",
      "type": "selector",
      "default": "auto",
      "outbounds": [
        "auto",
        "vless-$NAME",
        "vmess-$NAME",
        "hy2-$NAME",
"vmess-tls-argo-$NAME",
"vmess-argo-$NAME"
      ]
    },
    {
      "type": "vless",
      "tag": "vless-$NAME",
      "server": "$IP",
      "server_port": $vless_port,
      "uuid": "$UUID",
      "packet_encoding": "xudp",
      "flow": "xtls-rprx-vision",
      "tls": {
        "enabled": true,
        "server_name": "$reym",
        "utls": {
          "enabled": true,
          "fingerprint": "chrome"
        },
      "reality": {
          "enabled": true,
          "public_key": "$public_key",
          "short_id": ""
        }
      }
    },
{
            "server": "$IP",
            "server_port": $vmess_port,
            "tag": "vmess-$NAME",
            "tls": {
                "enabled": false,
                "server_name": "www.bing.com",
                "insecure": false,
                "utls": {
                    "enabled": true,
                    "fingerprint": "chrome"
                }
            },
            "packet_encoding": "packetaddr",
            "transport": {
                "headers": {
                    "Host": [
                        "www.bing.com"
                    ]
                },
                "path": "/$UUID-vm",
                "type": "ws"
            },
            "type": "vmess",
            "security": "auto",
            "uuid": "$UUID"
        },

    {
        "type": "hysteria2",
        "tag": "hy2-$NAME",
        "server": "$IP",
        "server_port": $hy2_port,
        "password": "$UUID",
        "tls": {
            "enabled": true,
            "server_name": "www.bing.com",
            "insecure": true,
            "alpn": [
                "h3"
            ]
        }
    },
{
            "server": "icook.hk",
            "server_port": 8443,
            "tag": "vmess-tls-argo-$NAME",
            "tls": {
                "enabled": true,
                "server_name": "$argodomain",
                "insecure": false,
                "utls": {
                    "enabled": true,
                    "fingerprint": "chrome"
                }
            },
            "packet_encoding": "packetaddr",
            "transport": {
                "headers": {
                    "Host": [
                        "$argodomain"
                    ]
                },
                "path": "/$UUID-vm",
                "type": "ws"
            },
            "type": "vmess",
            "security": "auto",
            "uuid": "$UUID"
        },
{
            "server": "icook.hk",
            "server_port": 8880,
            "tag": "vmess-argo-$NAME",
            "tls": {
                "enabled": false,
                "server_name": "$argodomain",
                "insecure": false,
                "utls": {
                    "enabled": true,
                    "fingerprint": "chrome"
                }
            },
            "packet_encoding": "packetaddr",
            "transport": {
                "headers": {
                    "Host": [
                        "$argodomain"
                    ]
                },
                "path": "/$UUID-vm",
                "type": "ws"
            },
            "type": "vmess",
            "security": "auto",
            "uuid": "$UUID"
        },
    {
      "tag": "direct",
      "type": "direct"
    },
    {
      "tag": "auto",
      "type": "urltest",
      "outbounds": [
        "vless-$NAME",
        "vmess-$NAME",
        "hy2-$NAME",
"vmess-tls-argo-$NAME",
"vmess-argo-$NAME"
      ],
      "url": "https://www.gstatic.com/generate_204",
      "interval": "1m",
      "tolerance": 50,
      "interrupt_exist_connections": false
    }
  ],
  "route": {
      "rule_set": [
            {
                "tag": "geosite-geolocation-!cn",
                "type": "remote",
                "format": "binary",
                "url": "https://cdn.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@sing/geo/geosite/geolocation-!cn.srs",
                "download_detour": "select",
                "update_interval": "1d"
            },
            {
                "tag": "geosite-cn",
                "type": "remote",
                "format": "binary",
                "url": "https://cdn.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@sing/geo/geosite/geolocation-cn.srs",
                "download_detour": "select",
                "update_interval": "1d"
            },
            {
                "tag": "geoip-cn",
                "type": "remote",
                "format": "binary",
                "url": "https://cdn.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@sing/geo/geoip/cn.srs",
                "download_detour": "select",
                "update_interval": "1d"
            }
        ],
    "auto_detect_interface": true,
    "final": "select",
    "rules": [
      {
      "inbound": "tun-in",
      "action": "sniff"
      },
      {
      "protocol": "dns",
      "action": "hijack-dns"
      },
      {
      "port": 443,
      "network": "udp",
      "action": "reject"
      },
      {
        "clash_mode": "Direct",
        "outbound": "direct"
      },
      {
        "clash_mode": "Global",
        "outbound": "select"
      },
      {
        "rule_set": "geoip-cn",
        "outbound": "direct"
      },
      {
        "rule_set": "geosite-cn",
        "outbound": "direct"
      },
      {
      "ip_is_private": true,
      "outbound": "direct"
      },
      {
        "rule_set": "geosite-geolocation-!cn",
        "outbound": "select"
      }
    ]
  },
    "ntp": {
    "enabled": true,
    "server": "time.apple.com",
    "server_port": 123,
    "interval": "30m",
    "detour": "direct"
  }
}
EOF

cat > clash_meta.yaml <<EOF
port: 7890
allow-lan: true
mode: rule
log-level: info
unified-delay: true
global-client-fingerprint: chrome
dns:
  enable: true
  listen: :53
  ipv6: true
  enhanced-mode: fake-ip
  fake-ip-range: 198.18.0.1/16
  default-nameserver: 
    - 223.5.5.5
    - 8.8.8.8
  nameserver:
    - https://dns.alidns.com/dns-query
    - https://doh.pub/dns-query
  fallback:
    - https://1.0.0.1/dns-query
    - tls://dns.google
  fallback-filter:
    geoip: true
    geoip-code: CN
    ipcidr:
      - 240.0.0.0/4

proxies:
- name: vless-reality-vision-$NAME               
  type: vless
  server: $IP                           
  port: $vless_port                                
  uuid: $UUID   
  network: tcp
  udp: true
  tls: true
  flow: xtls-rprx-vision
  servername: $reym                 
  reality-opts: 
    public-key: $public_key                      
  client-fingerprint: chrome                  

- name: vmess-ws-$NAME                         
  type: vmess
  server: $IP                       
  port: $vmess_port                                     
  uuid: $UUID       
  alterId: 0
  cipher: auto
  udp: true
  tls: false
  network: ws
  servername: www.bing.com                    
  ws-opts:
    path: "/$UUID-vm"                             
    headers:
      Host: www.bing.com                     

- name: hysteria2-$NAME                            
  type: hysteria2                                      
  server: $IP                               
  port: $hy2_port                                
  password: $UUID                          
  alpn:
    - h3
  sni: www.bing.com                               
  skip-cert-verify: true
  fast-open: true

- name: vmess-tls-argo-$NAME                         
  type: vmess
  server: icook.hk                        
  port: 8443                                     
  uuid: $UUID       
  alterId: 0
  cipher: auto
  udp: true
  tls: true
  network: ws
  servername: $argodomain                    
  ws-opts:
    path: "/$UUID-vm"                             
    headers:
      Host: $argodomain

- name: vmess-argo-$NAME                         
  type: vmess
  server: icook.hk                        
  port: 8880                                     
  uuid: $UUID       
  alterId: 0
  cipher: auto
  udp: true
  tls: false
  network: ws
  servername: $argodomain                   
  ws-opts:
    path: "/$UUID-vm"                             
    headers:
      Host: $argodomain 

proxy-groups:
- name: Balance
  type: load-balance
  url: https://www.gstatic.com/generate_204
  interval: 300
  strategy: round-robin
  proxies:
    - vless-reality-vision-$NAME                              
    - vmess-ws-$NAME
    - hysteria2-$NAME
    - vmess-tls-argo-$NAME
    - vmess-argo-$NAME

- name: Auto
  type: url-test
  url: https://www.gstatic.com/generate_204
  interval: 300
  tolerance: 50
  proxies:
    - vless-reality-vision-$NAME                              
    - vmess-ws-$NAME
    - hysteria2-$NAME
    - vmess-tls-argo-$NAME
    - vmess-argo-$NAME
    
- name: Select
  type: select
  proxies:
    - Balance                                         
    - Auto
    - DIRECT
    - vless-reality-vision-$NAME                              
    - vmess-ws-$NAME
    - hysteria2-$NAME
    - vmess-tls-argo-$NAME
    - vmess-argo-$NAME
rules:
  - GEOIP,LAN,DIRECT
  - GEOIP,CN,DIRECT
  - MATCH,Select
  
EOF

sleep 2
[ -d "$FILE_PATH" ] || mkdir -p "$FILE_PATH"
echo "$baseurl" > ${FILE_PATH}/${USERNAME}_v2sub.txt
cat clash_meta.yaml > ${FILE_PATH}/${USERNAME}_clashmeta.txt
cat sing_box.json > ${FILE_PATH}/${USERNAME}_singbox.txt
V2rayN_LINK="https://${USERNAME}.serv00.net/${USERNAME}_v2sub.txt"
Clashmeta_LINK="https://${USERNAME}.serv00.net/${USERNAME}_clashmeta.txt"
Singbox_LINK="https://${USERNAME}.serv00.net/${USERNAME}_singbox.txt"
cat > list.txt <<EOF
=================================================================================================

1. The Vless-reality sharing link is as follows:
$vl_link

Note: If the reality domain name entered previously is a CF domain name, the following functions will be activated:
It can be applied to create a CF vless/trojan node in the https://github.com/yonggekkk/Cloudflare_vless_trojan project
1. The Proxyip (with port) information is as follows:
Method 1 Global application: Set variable name: proxyip Set variable value: $IP:$vless_port
Method 2: Single-node application: path is changed to: /pyip=$IP:$vless_port
TLS of CF node can be turned on or off
The area where CF node lands on CF website is: $IP area

2. Non-standard port reverse IP information is as follows:
Client preferred IP address is: $IP, port: $vless_port
TLS of CF node must be turned on
CF node lands on non-CF website is: $IP area

Note: If serv00 IP is blocked, proxyip is still valid, but non-standard port reverse IP for client address and port will not be available
Note: Some big guys may scan Serv00's reverse IP as their shared IP library or sell it, please be careful to set the reality domain name to CF domain name
-------------------------------------------------------------------------------------------------

II. Vmess-ws sharing link three forms are as follows:

1. Vmess-ws main node sharing link is as follows:
(This node does not support CDN by default. If it is set to CDN back to the source (domain name required): the client address can modify the preferred IP/domain name by itself, and the 7 80 series ports can be changed at will. It can still be used even if blocked!)
$vmws_link

Argo domain name: ${argodomain}
If the above Argo temporary domain name is not generated, the following 2 and 3 Argo nodes will be unavailable (open the Argo fixed/temporary domain name webpage, and display HTTP ERROR 404 means it is available normally)

2. Vmess-ws-tls_Argo sharing link is as follows:
(This node is a CDN preferred IP node. The client address can modify the preferred IP/domain name by itself. The 6 443 series ports can be changed at will. It can still be used even if it is blocked!)
$vmatls_link

3. The Vmess-ws_Argo sharing link is as follows:
(This node is a CDN preferred IP node. The client address can modify the preferred IP/domain name by itself. The 7 80 series ports can be changed at will. It can still be used even if it is blocked!)
$vma_link
-------------------------------------------------------------------------------------------------

3. The HY2 sharing link is as follows:
$hy2_link
-------------------------------------------------------------------------------------------------

4. The aggregated general subscription sharing link of the above five nodes is as follows:
$V2rayN_LINK

The aggregated general sharing code of the above five nodes:
$baseurl
-------------------------------------------------------------------------------------------------

5. To view the subscription profiles of Sing-box and Clash-meta, please enter the main menu and select 4

Clash-meta subscription sharing link:
$Clashmeta_LINK

Sing-box subscription sharing link:
$Singbox_LINK
-------------------------------------------------------------------------------------------------

=================================================================================================

EOF
cat list.txt
sleep 2
rm -rf sb.log core tunnel.yml tunnel.json fake_useragent_0.2.0.json
}

showlist(){
if [[ -e $WORKDIR/list.txt ]]; then
green "Check the node and proxyip/non-standard port reverse ip information"
cat $WORKDIR/list.txt
else
red "sing-box is not installed" && exit
fi
}

showsbclash(){
if [[ -e $WORKDIR/sing_box.json ]]; then
green "The Sing_box configuration file is as follows, which can be uploaded to the subscription client for use:"
yellow "Among them, the Argo node is the CDN preferred IP node. The server address can be modified by the preferred IP/domain name. It can still be used even if it is blocked!"
sleep 2
cat $WORKDIR/sing_box.json
echo
echo
green "The Clash_meta configuration file is as follows, which can be uploaded to the subscription client for use:"
yellow "Among them, the Argo node is the CDN preferred IP node. The server address can be modified by the preferred IP/domain name. It can still be used even if it is blocked!"
sleep 2
cat $WORKDIR/clash_meta.yaml
echo
else
red "未安装sing-box" && exit
fi
}

servkeep() {
#green "Start installing Cron process keepalive"
curl -sSL https://raw.githubusercontent.com/yonggekkk/sing-box-yg/main/serv00keep.sh -o serv00keep.sh && chmod +x serv00keep.sh
sed -i '' -e "14s|''|'$UUID'|" serv00keep.sh
sed -i '' -e "17s|''|'$vless_port'|" serv00keep.sh
sed -i '' -e "18s|''|'$vmess_port'|" serv00keep.sh
sed -i '' -e "19s|''|'$hy2_port'|" serv00keep.sh
sed -i '' -e "20s|''|'$IP'|" serv00keep.sh
sed -i '' -e "21s|''|'$reym'|" serv00keep.sh
if [ ! -f "$WORKDIR/boot.log" ]; then
sed -i '' -e "15s|''|'${ARGO_DOMAIN}'|" serv00keep.sh
sed -i '' -e "16s|''|'${ARGO_AUTH}'|" serv00keep.sh
fi
#if ! crontab -l 2>/dev/null | grep -q 'serv00keep'; then
#if [ -f "$WORKDIR/boot.log" ] || grep -q "trycloudflare.com" "$WORKDIR/boot.log" 2>/dev/null; then
#check_process="! ps aux | grep '[c]onfig' > /dev/null || ! ps aux | grep [l]ocalhost > /dev/null"
#else
#check_process="! ps aux | grep '[c]onfig' > /dev/null || ! ps aux | grep [t]oken > /dev/null"
#fi
#(crontab -l 2>/dev/null; echo "*/10 * * * * if $check_process; then /bin/bash serv00keep.sh; fi") | crontab -
#fi
#green "After installation, it is executed every 10 minutes by default. You can modify the keep-alive execution interval by running crontab -e" && sleep 2
#echo
green "开始安装网Page process keep alive"
keep_path="$HOME/domains/${USERNAME}.${USERNAME}.serv00.net/public_nodejs"
[ -d "$keep_path" ] || mkdir -p "$keep_path"
curl -sL https://raw.githubusercontent.com/yonggekkk/sing-box-yg/main/app.js -o "$keep_path"/app.js
sed -i '' "28s/name/$USERNAME/g" "$keep_path"/app.js
devil www del ${USERNAME}.${USERNAME}.serv00.net > /dev/null 2>&1
devil www add ${USERNAME}.serv00.net php > /dev/null 2>&1
devil www add ${USERNAME}.${USERNAME}.serv00.net nodejs /usr/local/bin/node18 > /dev/null 2>&1
ln -fs /usr/local/bin/node18 ~/bin/node > /dev/null 2>&1
ln -fs /usr/local/bin/npm18 ~/bin/npm > /dev/null 2>&1
mkdir -p ~/.npm-global
npm config set prefix '~/.npm-global'
echo 'export PATH=~/.npm-global/bin:~/bin:$PATH' >> $HOME/.bash_profile && source $HOME/.bash_profile
rm -rf $HOME/.npmrc > /dev/null 2>&1
cd "$keep_path"
npm install basic-auth express dotenv axios --silent > /dev/null 2>&1
rm $HOME/domains/${USERNAME}.${USERNAME}.serv00.net/public_nodejs/public/index.html > /dev/null 2>&1
devil www restart ${USERNAME}.${USERNAME}.serv00.net
rm -rf $HOME/domains/${USERNAME}.${USERNAME}.serv00.net/logs/*
green "Installation complete, keep the web page alive：http://${USERNAME}.${USERNAME}.serv00.net/up ，Open it once and it will automatically keep alive every 3 minutes by default" && sleep 2
}

okip(){
    IP_LIST=($(devil vhost list | awk '/^[0-9]+/ {print $1}'))
    API_URL="https://status.eooce.com/api"
    IP=""
    THIRD_IP=${IP_LIST[2]}
    RESPONSE=$(curl -s --max-time 2 "${API_URL}/${THIRD_IP}")
    if [[ $(echo "$RESPONSE" | jq -r '.status') == "Available" ]]; then
        IP=$THIRD_IP
    else
        FIRST_IP=${IP_LIST[0]}
        RESPONSE=$(curl -s --max-time 2 "${API_URL}/${FIRST_IP}")
        
        if [[ $(echo "$RESPONSE" | jq -r '.status') == "Available" ]]; then
            IP=$FIRST_IP
        else
            IP=${IP_LIST[1]}
        fi
    fi
    echo "$IP"
    }

#Main Menu
menu() {
   clear
   echo "============================================================"
  purple "Modified from Serv00|ct8 Lao Wang sing-box installation script"
green "Yongge Github project: github.com/yonggekkk"
green "One-click three protocols coexist: vless-reality, Vmess-ws (Argo), hysteria2"
green "Current script version: V25.1.27 shortcut: bash serv00.sh"
echo "============================================================="
green "1. Install sing-box"
echo "------------------------------------------------------------"
red "2. Uninstall sing-box"
echo "------------------------------------------------------------"
green "3. View: each node sharing/sing-box and clash-meta subscription link/CF node proxyip"
echo "------------------------------------------------------------"
green "4. View: sing-box and clash-meta configuration files"
echo "------------------------------------------------------------"
yellow "5. Reset and clean up all service processes (system initialization)"
echo "------------------------------------------------------------"
red "0. Exit script"
   echo   "============================================================"
nb=$(echo "$HOSTNAME" | cut -d '.' -f 1 | tr -d 's')
ym=("$HOSTNAME" "cache$nb.serv00.com" "web$nb.serv00.com")
rm -rf $WORKDIR/ip.txt $WORKDIR/hy2ip.txt
for ip in "${ym[@]}"; do
dig @8.8.8.8 +time=2 +short $ip >> $WORKDIR/hy2ip.txt
sleep 1  
done
for ym in "${ym[@]}"; do
response=$(curl -sL --connect-timeout 5 --max-time 7 "https://ss.botai.us.kg/api/getip?host=$ym")
if [[ -z "$response" || "$response" == *unknown* ]]; then
for ip in "${ym[@]}"; do
dig @8.8.8.8 +time=2 +short $ip >> $WORKDIR/ip.txt
sleep 1  
done
else
echo "$response" | while IFS='|' read -r ip status; do
if [[ $status == "Accessible" ]]; then
echo "$ip: Available"  >> $WORKDIR/ip.txt
else
echo "$ip: Blocked (Argo and CDN back-to-origin nodes, proxyip are still valid)"  >> $WORKDIR/ip.txt
fi	
done
fi
done
snb=$(hostname | awk -F '.' '{print $1}')
green "Serv00 Server Name：$snb"
green "The currently available IP addresses are as follows："
cat $WORKDIR/ip.txt
echo
if [[ -e $WORKDIR/list.txt ]]; then
green "sing-box installed"
ps aux | grep '[c]onfig' > /dev/null && green "The main process is running normally" || yellow "The main process is starting... You can enter the script again after 1 minute to view it"
if [ -f "$WORKDIR/boot.log" ] && grep -q "trycloudflare.com" "$WORKDIR/boot.log" 2>/dev/null && ps aux | grep '[t]unnel --url' > /dev/null; then
argosl=$(cat "$WORKDIR/boot.log" 2>/dev/null | grep -a trycloudflare.com | awk 'NR==2{print}' | awk -F// '{print $2}' | awk '{print $1}')
checkhttp=$(curl -o /dev/null -s -w "%{http_code}\n" "https://$argosl")
[ "$checkhttp" -eq 404 ] && check="Domain name is valid" || check="Domain name may be invalid"
green "Current Argo temporary domain name：$argosl  $check"
fi
if [ -f "$WORKDIR/boot.log" ] && ! ps aux | grep '[t]unnel --url' > /dev/null; then
yellow "The current Argo temporary domain name does not exist. The background will continue to generate a valid temporary domain name. You can enter the script again later to view it"
fi
if ps aux | grep '[t]unnel --no' > /dev/null; then
argogd=$(cat $WORKDIR/gdym.log 2>/dev/null)
checkhttp=$(curl --max-time 2 -o /dev/null -s -w "%{http_code}\n" "https://$argogd")
[ "$checkhttp" -eq 404 ] && check="Domain name is valid" || check="Domain name may be invalid"
green "Current Argo fixed domain name：$argogd $check"
fi
if [ ! -f "$WORKDIR/boot.log" ] && ! ps aux | grep '[t]unnel --no' > /dev/null; then
yellow "Current Argo fixed domain name：$(cat $WORKDIR/gdym.log 2>/dev/null)，Failed to enable. Please check whether the relevant parameters are entered correctly"
fi
green "Keep alive webpage: http://${USERNAME}.${USERNAME}.serv00.net/up, open it once, and it will keep alive automatically every 3 minutes by default"
#if ! crontab -l 2>/dev/null | grep -q 'serv00keep'; then #if [ -f "$WORKDIR/boot.log" ] || grep -q "trycloudflare.com" "$WORKDIR/boot.log" 2>/dev/null; then #check_process="! ps aux | grep '[c]onfig' > /dev/null || ! ps aux | grep [l]ocalhost > /dev/null" #else #check_process="! ps aux | grep '[c]onfig' > /dev/null || ! ps aux | grep [t]oken > /dev/null" #fi #(crontab -l 2>/dev/null; echo "*/2 * * * * if $check_process; then /bin/bash serv00keep.sh; fi") | crontab -
#purple "Found that Serv00 has started a big move, and Cron keep alive has been reset and cleared"
#purple "Currently Cron keep alive has been successfully repaired. Open http://${USERNAME}. ${USERNAME}.serv00.net/up can also be kept alive in real time"
#purple "The main process and Argo process are starting... You can enter the script again after 1 minute to check"
#else
#green "Cron keep alive is running normally. Open http://${USERNAME}.${USERNAME}.serv00.net/up to keep it alive in real time.
#fi
else
red "sing-box is not installed, please select 1 to install"
fi
curl -sSL https://raw.githubusercontent.com/yonggekkk/sing-box-yg/main/serv00.sh -o serv00.sh && chmod +x serv00.sh
echo "========================================================="
reading "Please enter your choice [0-5]: " choice
echo ""
case "${choice}" in
1) install_singbox ;;
2) uninstall_singbox ;;
3) showlist ;;
4) showsbclash ;;
5) kill_all_tasks ;;
0) exit 0 ;;
*) red "Invalid option, please enter 0 to 5" ;;
    esac
}
menu
