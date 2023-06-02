
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
ls /sys/firmware/efi/efivars

fdisk /dev/sda
# GPT partition possible!
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

# Misc packages
pacman -Sy zsh vim sudo python iwd
systemctl enable iwd.service


# Create a 'jeffrey' account
useradd -m -G wheel,video,disk -s /usr/bin/zsh jeffrey








