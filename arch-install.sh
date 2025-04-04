#!/bin/bash

set -e

DISK="/dev/sda"
HOSTNAME="archlinux"
USERNAME="paulo_"
LOCALE="en_US.UTF-8"
TIMEZONE="Africa/Maputo"
KEYMAP="us"

# 1. Temporary keyboard
loadkeys $KEYMAP

# 2. Partitioning
parted -s "$DISK" mklabel gpt
parted -s "$DISK" mkpart ESP fat32 1MiB 512MiB
parted -s "$DISK" set 1 esp on
parted -s "$DISK" mkpart primary btrfs 512MiB -100GiB
parted -s "$DISK" mkpart primary ntfs -100GiB 100%

# 3. Formating
mkfs.fat -F32 "${DISK}1"
mkfs.btrfs -f "${DISK}2"
mkfs.ntfs -f "${DISK}3" -L Dados

# 4. Mounting
mount "${DISK}2" /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
umount /mnt

mount -o noatime,compress=zstd,subvol=@ "${DISK}2" /mnt
mkdir -p /mnt/{boot/efi,home,ntfs_dados}
mount -o noatime,compress=zstd,subvol=@home "${DISK}2" /mnt/home
mount "${DISK}1" /mnt/boot/efi
mount "${DISK}3" /mnt/ntfs_dados

# 5. Base instalation + GNOME (Wayland), whitout browser
pacstrap /mnt base base-devel linux-firmware broadcom-wl sudo btrfs-progs nano networkmanager grub efibootmgr dosfstools os-prober mtools zram-generator gnome gdm git tilix pipewire pipewire-pulse pipewire-alsa wireplumber flatpak

# 6. fstab
genfstab -U /mnt >> /mnt/etc/fstab

# 7. Chroot for configuration
arch-chroot /mnt /bin/bash <<EOF
ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
hwclock --systohc
echo "$LOCALE UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=$LOCALE" > /etc/locale.conf
echo "KEYMAP=$KEYMAP" > /etc/vconsole.conf
echo "$HOSTNAME" > /etc/hostname

# Sudoers
echo "%wheel ALL=(ALL:ALL) ALL" >> /etc/sudoers

# User
useradd -m -G wheel -s /bin/bash $USERNAME
echo -e "123\n123" | passwd
echo -e "123\n123" | passwd $USERNAME

# GRUB
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

# ZRAM config
cat <<ZRAM > /etc/systemd/zram-generator.conf
[zram0]
zram-size = ram
compression-algorithm = zstd
ZRAM

# Services
systemctl enable NetworkManager
systemctl enable gdm
systemctl enable bluetooth.service || true

# Flatpak Flathub
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

EOF

# 8. Installing the official Liquorix script
arch-chroot /mnt /bin/bash <<EOF
curl -s 'https://liquorix.net/install-liquorix.sh' | sudo bash
EOF

# 9. Installing Brave Browser
arch-chroot /mnt /bin/bash <<EOF
runuser -l $USERNAME -c "
cd ~
yay -S brave-bin --noconfirm
"
EOF

# 10. Set liquorix as default kernel in GRUB
arch-chroot /mnt /bin/bash <<EOF
sed -i 's/^GRUB_DEFAULT=.*/GRUB_DEFAULT=0/' /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg
EOF

# 11. End
echo "✅ Installation complete with GNOME + Wayland + PipeWire + Brave + Liquorix! You can reboot now."
