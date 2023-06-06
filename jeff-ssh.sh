#!/bin/sh

set -e

if ! ( ip address | grep -q 169.254.10.10 ) ; then
  sudo ip address add 169.254.10.10/16 broadcast + dev enp7s0u1u2
fi

HOST=169.254.100.2
#HOST=$(lanipof '00:1e:a6:00:63:22')

echo "HOST=$HOST"

exec ssh -i /j/ident/azure_glacial_inferno_jeffrey jeffrey@$HOST


