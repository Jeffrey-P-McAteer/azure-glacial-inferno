#!/usr/bin/env python

import os
import sys
import subprocess
import time
import asyncio
import traceback

try:
  import kasa
except:
  traceback.print_exc()
  subprocess.run([
    sys.executable, '-m', 'pip', 'install', '--user', 'python-kasa'
  ])
  import kasa


def ip_from_mac(mac_addr):
  cache_file = f'/tmp/.py-ip-mac-cache/{mac_addr}'
  if not os.path.exists( os.path.dirname(cache_file) ):
    os.makedirs(os.path.dirname(cache_file), exist_ok=True)

  if os.path.exists(cache_file):
    # try to return cache if modified <15 min ago
    cache_min = 15
    cache_age_s = int(time.time()) - os.path.getmtime(cache_file)
    if cache_age_s < cache_min * 60:
      with open(cache_file, 'r') as fd:
        content = fd.read()
        if len(content) > 2:
          return content.strip()

  # Cache is old/empty, ping everything!
  our_subnet = subprocess.check_output("ip route | grep '\\.0/' | awk '{print $1}' | tail -n 1", shell=True)
  if not isinstance(our_subnet, str):
    our_subnet = our_subnet.decode('utf-8')
  our_subnet = our_subnet.strip()

  print(f'Scanning {our_subnet} for {mac_addr}')

  # Spawn fping
  fping_proc = subprocess.Popen([
    'fping', '-c1', '-t250', '-q', '-g', our_subnet
  ], stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

  ip_neigh_out = ''
  while len(ip_neigh_out) < 2:
    time.sleep(0.5)
    # Check ip neighbor show
    try:
      ip_neigh_out = subprocess.check_output(f"ip neighbor show | grep -i '{mac_addr}'", shell=True)
      if not isinstance(ip_neigh_out, str):
        ip_neigh_out = ip_neigh_out.decode('utf-8')
      ip_neigh_out = ip_neigh_out.strip()
    except:
      pass
      ip_neigh_out = ''

  ip_neigh_ip_addr = subprocess.check_output(f"ip neighbor show | grep -i '{mac_addr}' | awk '{{print $1}}' | head -n 1", shell=True)
  if not isinstance(ip_neigh_ip_addr, str):
    ip_neigh_ip_addr = ip_neigh_ip_addr.decode('utf-8')
  ip_neigh_ip_addr = ip_neigh_ip_addr.strip()

  try:
    fping_proc.kill()
  except:
    pass

  try:
    with open(cache_file, 'w') as fd:
      fd.write(f'{ip_neigh_ip_addr}')
  except:
    pass

  return ip_neigh_ip_addr




async def main():
  from kasa import SmartStrip

  kasa_powerstrip_mac_addr = '48:22:54:30:05:78'

  print(f'{kasa_powerstrip_mac_addr} is at {ip_from_mac(kasa_powerstrip_mac_addr)}')

  p = SmartStrip(ip_from_mac(kasa_powerstrip_mac_addr))

  await p.update()

  for plug in p.children:
    print(f"{plug.alias}: {plug.is_on}")

  if 'off' in sys.argv:
    print('Turning server ports off...')
    for plug in p.children:
      if 'AGI' in plug.alias:
        await plug.turn_off()

  elif 'on' in sys.argv:
    print('Turning server ports on...')
    for plug in p.children:
      if 'AGI' in plug.alias:
        await plug.turn_on()




if __name__ == "__main__":
  asyncio.run(main())

