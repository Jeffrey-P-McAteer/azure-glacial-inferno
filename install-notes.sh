
exit 1 # Don't run this, it's a "script" for syntax highlighting

# Internets!
iwctl station wlan0 connect "Network Name"

# If we need to get into BIOS for any config
pacman -Sy ipmitool

ipmitool lan set 1 ipsrc static
ipmitool lan set 1 ipaddr 169.254.100.1
ipmitool lan set 1 arp respond on
ipmitool lan set 1 snmp public
ipmitool lan set 1 auth ADMIN MD2,MD5,PASSWORD
ipmitool lan set 1 access on
ipmitool user list 1
ipmitool user set password 2
ipmitool user enable 2

# We're going to share LAN1 w/ the host for IPMI stuff.
ipmitool raw 0x30 0x70 0x0c 1 1
# Static IPs for this network (169.254.0.0/16 ):
#  - laptop will be 169.254.10.10
#  - IPMI BMC is 169.254.100.1
#  - Host is 169.254.100.2

ipmitool chassis bootdev bios # to force a boot to bios on `reboot`

ipmitool sensor
ipmitool sensor thresh FAN1 lower 300 300 400

# Enable fan manual mode
ipmitool raw 0x30 0x70 0x66 0x01 0x00 0x[01-64]
# Set fan % as a fraction of 0xNN/0xff
ipmitool raw 0x30 0x91 0x5A 0x03 0x00 0x40
#                         ^ fan number
#                              ^ percentage
# NOTE2: X10 boards operate differently. Some raw commands are different, and their %age fan speed is 0-100, not 0-255.

for fan in 0x00 0x01 0x02 0x03 0x04 0x05 0x06 0x07 0x08 0x09 0x0a 0x0b 0x0c 0x0d 0x0e 0x0f 0x10 ; do ipmitool raw 0x30 0x70 0x66 0x01 0x00 $fan ; done

for fan in 0x00 0x01 0x02 0x03 0x04 0x05 0x06 0x07 0x08 0x09 0x0a 0x0b 0x0c 0x0d 0x0e 0x0f 0x10 ; do ipmitool raw 0x30 0x91 0x5A 0x03 $fan 0x40 ; done

# 0x0a seems pretty quiet for my board
for fan in 0x00 0x01 0x02 0x03 0x04 0x05 0x06 0x07 0x08 0x09 0x0a 0x0b 0x0c 0x0d 0x0e 0x0f 0x10 ; do ipmitool raw 0x30 0x91 0x5A 0x03 $fan 0x0a ; done


# Install!

# Ensure EFI
#ls /sys/firmware/efi/efivars

fdisk /dev/sda
#### GPT partition possible!
# Ended up using MBR/DOS disk + installing GRUB
# 2gb FAT boot
# remaining BTRFS root

mkfs.fat -F 32 /dev/sda1
mkfs.btrfs -f /dev/sda2


mount /dev/sda2 /mnt
mount --mkdir /dev/sda1 /mnt/boot

pacstrap -K /mnt base linux linux-firmware python base-devel git ipmitool vim sudo lm_sensors

genfstab -U /mnt >> /mnt/etc/fstab

arch-chroot /mnt

# In the new OS!

ln -sf /usr/share/zoneinfo/America/New_York /etc/localtime

vim /etc/locale.gen

locale-gen

vim /etc/locale.conf
# LANG=en_US.UTF-8

echo 'azure-glacial-inferno' > /etc/hostname

mkinitcpio -P

# Set root PW
passwd

# Install Bootloader
bootctl install
systemctl enable systemd-boot-update.service

cat > /boot/loader/loader.conf <<EOF
#console-mode keep
console-mode max
timeout 6
default arch.conf
EOF

cat > /boot/loader/entries/arch.conf <<EOF
title Azure Glacial Inferno
linux /vmlinuz-linux
initrd /intel-ucode.img
initrd /initramfs-linux.img
options root=PARTUUID=TODO-run-blkid rootfstype=btrfs add_efi_memmap mitigations=off pti=off intel_pstate=passive
EOF



# Misc packages
pacman -Sy zsh vim sudo python iwd dhcpcd
systemctl enable iwd.service
systemctl enable dhcpcd.service


# Create a 'jeffrey' account
useradd -m -G wheel,video,disk -s /usr/bin/zsh jeffrey

# Install yay
(
  su jeffrey
  cd /opt
  git clone https://aur.archlinux.org/yay.git
  cd yay
  makepkg -si
)

# Now install more packages! (some from AUR now)
yay -Sy nvidia cuda opencl-nvidia
yay -Sy ocl-icd
yay -Sy intel-ucode

yay -Sy openssh nginx-mainline
sudo systemctl enable sshd.service
sudo systemctl enable nginx.service

# xpra GUI stuff, select pipewire + wireplumber for audio stuff
yay -Sy xorg lxqt breeze-icons xpra


yay -Sy oh-my-zsh-git

yay -S freeipmi pkgconf clang cargo
# ^ picked rustup for rust provider
# for https://github.com/chenxiaolong/ipmi-fan-control
(
  cd /opt
  git clone https://github.com/chenxiaolong/ipmi-fan-control
  cd ipmi-fan-control
  cargo build --release
  
  # see https://github.com/chenxiaolong/ipmi-fan-control/blob/master/config.sample.toml
  vim /etc/ipmi-fan-control.toml

  /opt/ipmi-fan-control/target/release/ipmi-fan-control 

  sudo vim /etc/systemd/system/ipmi-fan-control.service <<EOF
[Unit]
Description=Run ipmi-fan-control service

[Service]
ExecStart=/opt/ipmi-fan-control/target/release/ipmi-fan-control 

[Install]
WantedBy=multi-user.target
EOF
  sudo systemctl enable ipmi-fan-control.service

)

yay -S lm_sensors
sudo sensors-detect

# More firmware blobs!
yay -S mkinitcpio-firmware



cat > /etc/systemd/network/eno1.network <<EOF
[Match]
Name=eno1

[Network]
Address=169.254.100.2/16
#Gateway=169.254.100.1
#DNS=192.168.1.1
EOF

# GPU drivers for the old cards!
yay -R nvidia
yay -S linux-headers nvidia-470xx-dkms cuda







