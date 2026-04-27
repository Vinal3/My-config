#!/usr/bin/env bash

SUB="https://vpnxray.ru/sub/86e4735790ed4920"
DIR=~/clash
CFG=$DIR/config.yaml

echo "Downloading subscription..."
RAW=$(curl -s $SUB)

echo
echo "Servers:"

i=1
declare -a arr

while read line; do

    [[ -z "$line" ]] && continue

    name="server $i"

    echo "$i) $name"

    arr[$i]="$line"

    ((i++))

done <<< "$RAW"


echo
read -p "Choose: " num

LINK=${arr[$num]}

if [[ -z "$LINK" ]]; then
    echo "Wrong choice"
    exit
fi

echo
echo "Selected:"
echo "$LINK"


uuid=$(echo $LINK | cut -d@ -f1 | cut -d/ -f3)
host=$(echo $LINK | cut -d@ -f2 | cut -d: -f1)
port=$(echo $LINK | cut -d: -f3 | cut -d? -f1)
pbk=$(echo $LINK | sed 's/.*pbk=\([^&]*\).*/\1/')
sid=$(echo $LINK | sed 's/.*sid=\([^&]*\).*/\1/')
sni=$(echo $LINK | sed 's/.*sni=\([^&]*\).*/\1/')
fp=$(echo $LINK | sed 's/.*fp=\([^&]*\).*/\1/')


cat > $CFG <<EOF
mixed-port: 7890
mode: rule
log-level: info

tun:
  enable: true
  stack: gvisor
  auto-route: true
  auto-detect-interface: true

dns:
  enable: true
  enhanced-mode: fake-ip

proxies:
  - name: VPN
    type: vless
    server: $host
    port: $port
    uuid: $uuid
    network: tcp
    tls: true
    udp: true
    servername: $sni
    flow: xtls-rprx-vision
    client-fingerprint: $fp
    reality-opts:
      public-key: $pbk
      short-id: $sid

proxy-groups:
  - name: Proxy
    type: select
    proxies:
      - VPN

rules:
  - MATCH,Proxy
EOF


echo
echo "Stopping old mihomo..."
sudo pkill mihomo 2>/dev/null

sleep 1

echo "Starting mihomo..."
sudo mihomo -d $DIR
