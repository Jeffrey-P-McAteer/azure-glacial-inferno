#!/usr/bin/env bash

set -e

if ! which ipmiview ; then
  yay -S ipmiview
fi

if ! ( ip address | grep -q 169.254.10.10 ) ; then
  sudo ip address add 169.254.10.10/16 broadcast + dev enp7s0u1u2
fi

# https://www.supermicro.com/manuals/other/ipmiview20.pdf
# export _JAVA_OPTIONS=-Djdk.gtk.version=2
export _JAVA_AWT_WM_NONREPARENTING=1

exec ipmiview 169.254.100.1

