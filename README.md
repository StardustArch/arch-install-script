
# Arch Linux Installer Script

![Arch Linux Logo](https://archlinux.org/static/logos/archlinux-logo-dark-1200dpi.b42bd35d5916.png)

Automated installation script for a minimal Arch Linux setup with GNOME, PipeWire, Brave Browser, and Liquorix kernel.

## ✨ Features

- **Desktop Environment**: GNOME with Wayland
- **Audio**: PipeWire (replaces PulseAudio)
- **Browser**: Brave (installed via AUR)
- **Kernel**: Liquorix (optimized for desktop/gaming)
- **Memory**: ZRAM configuration
- **Apps**: Flatpak with Flathub repository

## 🛠 Requirements

- Minimal Arch Linux system or live USB
- Root access or sudo privileges
- Active internet connection
- At least 20GB disk space (recommended)

## 🚀 Quick Start

```bash
git clone https://github.com/StardustArch/arch-install-script.git
cd arch-install-script
chmod +x arch-install.sh
sudo ./arch-install.sh
```

## 🔧 Customization

Edit these variables in the script before running:

```bash
# System configuration
HOSTNAME="archlinux"
USERNAME="user"
TIMEZONE="Africa/Maputo"
KEYMAP="us"
LANG="en_US.UTF-8"
DEFAULT_PASSWORD="123"(You can change it)

# Disk configuration
DISK="/dev/sda"
EFI_SIZE="512M"
SWAP_SIZE= RAM_SIZE
DATA_SIZE="100G"
ROOT/HOME_SIZE=REST_OF_DISK_SPACE
```

## 📂 Partition Scheme

| Partition   | Filesystem | Size  | Mount Point     | Subvolume      |
|-------------|------------|-------|-----------------|----------------|
| /dev/sda1   | FAT32      | 512M  | /boot/efi       | N/A            |
| /dev/sda2   | Btrfs      | Remainder  | /               | @              |
| /dev/sda2   | Btrfs      | Remainder  | /home           | @home          |
| /dev/sda3   | NTFS       | 100G  | /mnt/ntfs_dados | N/A            |

### Explanation:

1. **/dev/sda1**: 512MB EFI (ESP) partition, formatted in **FAT32** and mounted at `/boot/efi` for system boot. It has no subvolume.
2. **/dev/sda2**: Btrfs partition, which occupies the remaining space after creating the other partitions:
- **@**: Subvolume for the root system (`/`).
- **@home**: Subvolume for the `/home` directory.
3. **/dev/sda3**: Data partition in **NTFS**, 100GB in size, mounted at `/mnt/ntfs_data` for storing files. It has no subvolume.

## 📦 Included Packages

### Core System
- base base-devel linux-firmware
- btrfs-progs networkmanager grub efibootmgr
- sudo nano git reflector

### Desktop Environment
- gnome gnome-tweaks gdm
- pipewire pipewire-pulse wireplumber
- xdg-user-dirs xdg-utils

### Additional Software
- brave-bin (from AUR)
- linux-liquorix linux-liquorix-headers
- flatpak flathub

## ⚙️ Post-Installation

After reboot:
1. Connect to network using GNOME settings
2. Install additional Flatpak apps:
   ```bash
   flatpak install flathub com.discordapp.Discord
   flatpak install flathub com.spotify.Client
   ```

## 🛠 Troubleshooting

### Common Issues
1. **No internet connection**:
   ```bash
   systemctl enable --now NetworkManager
   ```

2. **Audio not working**:
   ```bash
   systemctl enable --now pipewire pipewire-pulse
   ```

3. **Brave not installing**:
   Ensure yay is installed and try manually:
   ```bash
   yay -S brave-bin
   ```

## 📜 License

MIT License - Free to use and modify
