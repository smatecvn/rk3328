#!/bin/bash
REQ=/etc/netplan/request.json
CFG=/etc/netplan/01-netcfg.yaml

inotifywait -m -e close_write "$REQ" | while read path action file; do
    IP=$(jq -r .ip $REQ)
    GW=$(jq -r .gw $REQ)
    NS=$(jq -r '.ns | join(", ")' $REQ)

    cat > $CFG <<EOF
network:
  version: 2
  renderer: networkd
  ethernets:
    eth0:
      dhcp4: no
      addresses:
        - ${IP}
      routes:
        - to: default
          via: ${GW}
      nameservers:
        addresses: [${NS}]
EOF
    ip addr flush dev eth0
    netplan apply
done
