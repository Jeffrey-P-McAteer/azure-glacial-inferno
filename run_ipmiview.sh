#!/usr/bin/env bash

set -e

if ! which ipmiview ; then
  yay -S ipmiview
fi

cat <<EOF
Setup notes for the host (also see https://portal.nutanix.com/page/documents/kbs/details?targetId=kA0600000008db6CAA )
 - Boot Arch Live
 - pacman -Sy ipmitool
 - ipmitool lan set 1 ipsrc static
 - ipmitool lan set 1 ipaddr 169.254.100.1
 - ipmitool lan set 1 arp respond on
 - ipmitool lan set 1 snmp public
 - ipmitool lan set 1 auth ADMIN MD2,MD5,PASSWORD
 - ipmitool lan set 1 access on
 - ipmitool user list 1
 - ipmitool user set password 2
 - ipmitool user enable 2

EOF

if ! ( ip address | grep -q 169.254.10.10 ) ; then
  sudo ip address add 169.254.10.10/16 broadcast + dev enp7s0u1u2
fi

# https://www.supermicro.com/manuals/other/ipmiview20.pdf

exec ipmiview 169.254.100.1

