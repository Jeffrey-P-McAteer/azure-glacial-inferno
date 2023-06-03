
# Azure-Glacial-Inferno

Management utility for the `azure-glacial-inferno` server.

Does not perform maitenence, but does warn/syslog about anomolies and re-starts anything out of line (disconnected network, drive mounts, whatever.).


## Azure-Glacial-Inferno design

 - Arch Linux
 - BTRFS root drive
 - 32-or-so-GB swap
 - SSH server
 - NginX w/ user certs
    - How dynamic can we make this? a `/agi-users/` folder of `.pem` files?
 - Xpra behind nginx
    - One session per user cert under `/agi-users/`
    - For the GUI... ~~KDE~~ LXQt! https://wiki.archlinux.org/title/LXQt
 - Also, run a mumble server for all connected users: https://www.mumble.info/
    - User voice in/over, plus bg/shared music player (submit .mp3 files, YT urls, etc)
    - Can we enable audio out on login?
    - Also possibly some desktop GUI to render speaker icons?
 - user cert-ed WebDAV server for users to move files around
    - http://nginx.org/en/docs/http/ngx_http_dav_module.html

## Non-standard directories

 - `/docs/*`
    - Folder with markdown write-ups of how to do common operations + research notes.
 - `/azure-glacial-inferno`
    - This repository! Will have systemd service pointing to run `/azure-glacial-inferno/target/release/azure-glacial-inferno` as primary management watchdog.
 - `/users/<username>.toml`
    - Read by `azure-glacial-inferno` the rust tool, contains user-specific config such as profile pic (for mumble automata), ssh public key, and nginx user cert pub key.
    - Polled + information is distributed to the various subsystems that use it every `90s`.
 - `/mnt/*`
    - Internal disks from the JBOD not-a-raid controller. Shoud meet size + speed needs, eg one is `240gb` ssd, other is `2tb` hdd.
    - Names to follow.


## Background reading

 - https://github.com/chenxiaolong/ipmi-fan-control
 
## Debugging notes

```bash
# boot an installed system
qemu-system-x86_64 -bios /usr/share/edk2-ovmf/x64/OVMF_CODE.fd -drive format=raw,file=/dev/sdd -m 4G -enable-kvm

# chroot to a foreign installed system
sudo mount /dev/sdd2 /tmp/agi && sudo mount /dev/sdd1 /tmp/agi/boot && sudo arch-chroot /tmp/agi ; sudo umount /tmp/agi/boot ; sudo umount /tmp/agi

```




