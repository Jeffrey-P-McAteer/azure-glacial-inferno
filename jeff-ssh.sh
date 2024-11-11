#!/bin/sh

set -e

if [ -z "$ETH_DEV" ]; then
  ETH_DEV=$(ip a | grep ': enp' | tail -1 | cut -d':' -f2 | tr -d '[:space:]')
fi
echo "ETH_DEV=$ETH_DEV"

if ! ( ip address | grep -q 169.254.10.10 ) ; then
  sudo ip address add 169.254.10.10/16 broadcast + dev $ETH_DEV
fi

HOST=169.254.100.2
#HOST=$(lanipof '00:1e:a6:00:63:22')

echo "HOST=$HOST"

echo "Forwarding 127.0.0.1:9000"

exec ssh \
  -i /j/ident/azure_glacial_inferno_jeffrey \
  -L 127.0.0.1:9000:127.0.0.1:9000 \
   jeffrey@$HOST


