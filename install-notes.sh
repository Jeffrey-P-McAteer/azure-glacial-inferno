
exit 1 # Don't run this, it's a "script" for syntax highlighting

iwctl station wlan0 connect "Network Name"

fdisk /dev/sda
# GPT partition possible!
# 2gb FAT boot
# remaining BTRFS root

mkfs.fat -F 32 /dev/sda1
mkfs.btrfs /dev/sda2






