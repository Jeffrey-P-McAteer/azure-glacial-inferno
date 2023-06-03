
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

ipmitool chassis bootdev bios # to force a boot to bios on `reboot`

ipmitool sensor
ipmitool sensor thresh FAN1 lower 300 300 400


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

pacstrap -K /mnt base linux linux-firmware python base-devel git ipmitool vim sudo

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
pacman -Sy zsh vim sudo python iwd
systemctl enable iwd.service


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











