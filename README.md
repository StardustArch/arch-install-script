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
git clone https://github.com/your-username/arch-installer.git
cd arch-installer
sudo ./arch-installer.sh
🔧 Customization
Edit these variables in the script before running:

bash
Copy
# System configuration
HOSTNAME="archlinux"
USERNAME="user"
TIMEZONE="Africa/Maputo"
KEYMAP="us"
LANG="en_US.UTF-8"

# Disk configuration
DISK="/dev/sda"
EFI_SIZE="512M"
SWAP_SIZE="4G"
ROOT_SIZE="30G"
HOME_SIZE="50G"
DATA_SIZE="100G"
📂 Partition Scheme
Partition	Filesystem	Size	Mount Point
/dev/sda1	FAT32	512M	/boot
/dev/sda2	Btrfs	30G	/
/dev/sda3	Btrfs	50G	/home
/dev/sda4	NTFS	100G	/mnt/data
📦 Included Packages
Core System
base base-devel linux linux-firmware

btrfs-progs networkmanager grub efibootmgr

sudo nano git reflector

Desktop Environment
gnome gnome-tweaks gdm

pipewire pipewire-pulse wireplumber

xdg-user-dirs xdg-utils

Additional Software
brave-bin (from AUR)

linux-liquorix linux-liquorix-headers

flatpak flathub

⚙️ Post-Installation
After reboot:

Connect to network using GNOME settings

Install additional Flatpak apps:

bash
Copy
flatpak install flathub com.discordapp.Discord
flatpak install flathub com.spotify.Client
🛠 Troubleshooting
Common Issues
No internet connection:

bash
Copy
systemctl enable --now NetworkManager
Audio not working:

bash
Copy
systemctl enable --now pipewire pipewire-pulse
Brave not installing:
Ensure yay is installed and try manually:

bash
Copy
yay -S brave-bin
