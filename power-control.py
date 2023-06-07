#!/usr/bin/env python

import os
import sys
import subprocess
import time
import asyncio
import traceback
import shutil


try:
  import kasa
except:
  traceback.print_exc()
  subprocess.run([
    sys.executable, '-m', 'pip', 'install', '--user', 'python-kasa'
  ])
  import kasa


try:
  import pyipmi
except:
  traceback.print_exc()
  subprocess.run([
    sys.executable, '-m', 'pip', 'install', '--user', 'python-ipmi'
  ])
  import pyipmi


from kasa import SmartStrip
import pyipmi
import pyipmi.interfaces


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

def establish_pyipmi_sess(ipmi_bmc_ip):
  try:
    interface = pyipmi.interfaces.create_interface(interface='rmcp',
                                         slave_address=0x81,
                                         host_target_address=0x20,
                                         keep_alive_interval=1)
    ipmi = pyipmi.create_connection(interface)
    ipmi.session.set_session_type_rmcp(host=ipmi_bmc_ip, port=623)
    ipmi.session.set_auth_type_user(username='ADMIN', password=os.environ['IPMI_PASSWORD'])

    ipmi.target = pyipmi.Target(ipmb_address=0x20)

    ipmi.session.establish()

    return ipmi
  except:
    traceback.print_exc()
    return None

async def main():
  kasa_powerstrip_mac_addr = '48:22:54:30:05:78'
  ipmi_bmc_ip = '169.254.100.1'

  print(f'{kasa_powerstrip_mac_addr} is at {ip_from_mac(kasa_powerstrip_mac_addr)}')

  p = SmartStrip(ip_from_mac(kasa_powerstrip_mac_addr))

  await p.update()

  for plug in p.children:
    print(f"{plug.alias}: {plug.is_on}")

  if 'off' in sys.argv:

    if 'IPMI_PASSWORD' in os.environ:
      print(f'Asking BMC to power down nicely...')
      try:
        ipmi = establish_pyipmi_sess(ipmi_bmc_ip)
        ipmi.chassis_control_soft_shutdown()
      except:
        traceback.print_exc()
      
      # Poll for 40s for power down...
      for _ in range(0, 10):
        time.sleep(4)
        try:
          ipmi = establish_pyipmi_sess(ipmi_bmc_ip)
          if ipmi is None:
            continue

          print(f'ipmi.get_device_id() = {ipmi.get_device_id()}')

          # Is it powered off?
          chassis_status = ipmi.get_chassis_status()
          print(f'chassis_status.power_on = {chassis_status.power_on}')

          if not chassis_status.power_on:
            break # continue!

        except:
          traceback.print_exc()

      print(f'Telling BMC to power down...')
      try:
        ipmi = establish_pyipmi_sess(ipmi_bmc_ip)
        ipmi.chassis_control_power_down()
      except:
        traceback.print_exc()
      
      time.sleep(2)

    else:
      print(f'WARNING: cannot ask BMC over IPMI to power off nicely because the environment variable IPMI_PASSWORD is not defined.')
      time.sleep(0.5)
    
    print('Turning server power sockets off...')
    for plug in p.children:
      if 'AGI' in plug.alias:
        await plug.turn_off()

  elif 'on' in sys.argv:

    print('Turning server power sockets on...')
    for plug in p.children:
      if 'AGI' in plug.alias:
        await plug.turn_on()

    if 'IPMI_PASSWORD' in os.environ:
      # Ask ipmi_bmc_ip if it's on...
      while True:
        print(f'Polling for BMC at {ipmi_bmc_ip}')
        time.sleep(1)
        try:
          ipmi = establish_pyipmi_sess(ipmi_bmc_ip)
          if ipmi is None:
            continue

          print(f'ipmi.get_device_id() = {ipmi.get_device_id()}')

          # Is it powered on?
          chassis_status = ipmi.get_chassis_status()
          print(f'chassis_status.power_on = {chassis_status.power_on}')

          ipmi.chassis_control_power_up()
          
          break

        except:
          traceback.print_exc()
    else:
      print(f'WARNING: not booting using IPMI because the environment variable IPMI_PASSWORD is not defined.')
      time.sleep(0.5)




if __name__ == "__main__":
  asyncio.run(main())

