#!/bin/sh

set -e

if [ -z "$GOOGLE_DDNS_USER" ] || [ -z "$GOOGLE_DDNS_PASS" ] ; then
  echo "Run with the environment variables GOOGLE_DDNS_USER and GOOGLE_DDNS_PASS set!"
  exit 1
fi

# First get our public IPV4 address
pub_ipv4_services=(
  'icanhazip.com'
  'api.ipify.org'
  'ipinfo.io/ip'
  'ipecho.net/plain'
)
for pub_ipv4_service in ${pub_ipv4_services[@]}; do
  OUR_IPV4=$(curl --silent -4 --max-time 12 "$pub_ipv4_service" || true)
  # echo "OUR_IPV4=$OUR_IPV4 from $pub_ipv4_service"
  if ! [ -z "$OUR_IPV4" ] ; then
   break
  fi
done

echo "OUR_IPV4=$OUR_IPV4"

HOSTNAME_TO_UPDATE=azure-glacial-inferno.jmcateer.com
UPDATE_URL="https://${GOOGLE_DDNS_USER}:${GOOGLE_DDNS_PASS}@domains.google.com/nic/update?hostname=${HOSTNAME_TO_UPDATE}&myip=${OUR_IPV4}"
curl --silent --insecure "$UPDATE_URL"

