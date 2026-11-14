# StardustArch (Hyprland + Nix + Noctalia)

![Arch Linux](https://img.shields.io/badge/Arch%20Linux-1793D1?logo=arch-linux&logoColor=white) ![Nix](https://img.shields.io/badge/Nix-5277C3?logo=nixos&logoColor=white) ![Hyprland](https://img.shields.io/badge/Hyprland-00A4CC?logo=linux&logoColor=white) ![Noctalia](https://img.shields.io/badge/Noctalia-6C5CE7?logo=wayland&logoColor=white)

A reproducible Arch Linux environment managed by **Pacman** (System layer) and **Nix Home Manager** (User layer), with **Noctalia** as the unified Wayland desktop shell.

Featuring a custom **Dynamic Theme System** (Aizome, Nord, Gruvbox) that instantly syncs Wallpaper, Kitty, GTK, QT and Hyprland borders via **Noctalia** templates.

---

## ✨ Features

* **Hybrid Architecture:**
    * **System Core:** Drivers, Hyprland, Greetd, and Noctalia installed via `pacman` for stability.
    * **User Space:** Shell, Neovim, and CLI tools managed via `Nix` for portability.
* **Automated Bootstrap:** `archinstall` JSON configurations for a hands-off base installation.
* **Noctalia Desktop Shell:** Replaces Waybar, SwayNC, Rofi, hyprlock, hypridle, cliphist, and wall-manager with a single unified shell (bar, launcher, notifications, lockscreen, clipboard, wallpaper).
* **Hyprland 0.55+ Lua Config:** Configuration in Lua (no hyprlang), mirroring the CachyOS structure.
* **Greetd + tuigreet:** Minimal TTY greeter replacing SDDM.
* **Theme Palettes:** Aizome (Deep Blue), Nord (Arctic Frost), Gruvbox (Retro Groove) — synced across Kitty, GTK, QT, and Hyprland borders.

---

## 📂 Repository Structure

```text
├── bootstrap/           # JSON configs for the Arch ISO installer
│   ├── UserConfig.json  # Minimal profile & Btrfs layout
│   └── UserCredentials.json # User setup (username/password)
├── cachyos/             # Reference configs from CachyOS Hypr/Noctalia (NOT committed)
├── noctalia/            # Noctalia shell configuration
│   └── .config/noctalia/config.toml
├── nix/                 # Nix Home Manager configurations
│   ├── flake.nix        # Flake entry point (dynamic username)
│   └── home.nix         # User packages, Aliases & Dotfiles logic
├── hypr/                # Hyprland configs (Lua 0.55+)
│   ├── .config/hypr/
│   │   ├── hyprland.lua     # Entry point (loads all config modules)
│   │   ├── xdph.conf        # Screencopy config
│   │   ├── config/          # Lua modules: variables, colors, environment, monitors, inputs, decorations, animations, misc, workspaces, windowrules, autostart, binds
│   │   ├── wallpapers/      # Theme wallpapers (aizome, nord, gruvbox)
│   │   └── legacy/          # Old .conf and .lua files (archived, not used)
├── kitty/               # Kitty terminal config (includes Noctalia theme)
│   └── .config/kitty/kitty.conf
├── rofi/                # Rofi configs (legacy, kept for reference)
├── swaync/              # SwayNC configs (legacy, kept for reference)
├── waybar/              # Waybar configs (legacy, kept for reference)
├── setup_install.sh     # Main post-install automation script
└── README.md
```

---

## 🎨 Theme Palettes

Three palettes are maintained and synced across the system:

| Palette | Style | Best For |
|---------|-------|----------|
| **Aizome** | Deep Blue & Traditional | Default, focused dark blue |
| **Nord** | Arctic Frost | Cold, clean blues and grays |
| **Gruvbox** | Retro Groove | Warm, earthy tones |

Theme switching is handled by **Noctalia** (Super + Z → Settings → Templates) or via the Noctalia control center. Themes sync to:
* Hyprland borders and decorations
* Kitty terminal (`include current-theme.conf`)
* GTK3/GTK4 applications
* QT6 applications (via qt6ct)
* Wallpaper selection

---

## 🖥️ Installation Guide

### ⚠️ CRITICAL WARNING

The username defined in `bootstrap/UserCredentials.json` **MUST MATCH** the username you create during the Arch ISO installation. The Nix flake detects the username from the `$USER` environment variable at runtime.

### Phase 1: Base System (The ISO)

1. **Boot & Connect:**
   * Boot into the Arch Linux ISO.
   * Ensure you have internet access (`ping -c 3 google.com`).

2. **Download Configs:**
   Fetch the configuration files to temporary RAM (`/tmp`):

   ```bash
   cd /tmp
   curl -O https://raw.githubusercontent.com/StardustArch/arch-install-script/main/bootstrap/UserConfig.json
   curl -O https://raw.githubusercontent.com/StardustArch/arch-install-script/main/bootstrap/UserCredentials.json
   ```

3. **Run Installer:**
   Execute the automated installer:

   ```bash
   archinstall --config /tmp/UserConfig.json --creds /tmp/UserCredentials.json
   ```

4. **Select Disk:**
   * Go to **"Disk Configuration"**.
   * Select your target drive (e.g., `/dev/nvme0n1`).
   * Select **Btrfs** (recommended).
   * **Install**.

5. **Reboot:**
   Once finished, reboot into your new system and login as your chosen username.

### Phase 2: User Setup (The Magic)

1. **Clone the Repository:**

   ```bash
   git clone https://github.com/StardustArch/arch-install-script.git
   cd ~/arch-install-script
   ```

2. **Run the Installer:**
   This script installs Hyprland, Greetd, Noctalia, initializes Nix, and sets up your dotfiles.

   ```bash
   chmod +x setup_install.sh
   ./setup_install.sh
   ```

3. **Finalize:**
   Once the script finishes, **reboot** one last time. You will be greeted by **tuigreet** (Greetd) — log in and Hyprland with Noctalia will start automatically.

---

## 🖥️ Display Manager: Greetd + tuigreet

The system uses **Greetd** as the display manager with **tuigreet** as the greeter frontend (replacing SDDM).

* Config file: `/etc/greetd/config.toml`
* Greeter: `tuigreet --time --time-format '%H:%M | %a %h %d' --remember --remember-user-session --cmd 'uwsm start hyprland-uwsm.desktop'`
* Greeter user: `greeter`

To reconfigure the greeter, edit `/etc/greetd/config.toml` and restart the service:

```bash
sudo systemctl restart greetd
```

---

## 🐚 Noctalia Desktop Shell

Noctalia replaces the traditional patchwork of Waybar + SwayNC + Rofi + hyprlock + hypridle + cliphist + wall-manager with a single unified shell.

### What Noctalia Provides

| Component | Replaces |
|-----------|----------|
| Bar (workspaces, clock, media, tray, notifications) | Waybar |
| Launcher (app search) | Rofi / dmenu |
| Notifications & Control Center | SwayNC / mako |
| Lockscreen | hyprlock |
| Idle handling | hypridle |
| Clipboard history | cliphist |
| Wallpaper | wall-manager / swaybg |

### Keybindings (Noctalia IPC)

All Noctalia commands are invoked via `noctalia msg <command>` from Hyprland Lua keybinds:

| Key | Action |
|-----|--------|
| `Super + Space` | Open launcher |
| `Super + V` | Clipboard history |
| `Super + W` | Wallpaper picker |
| `Super + T` | Control Center |
| `Super + A` | Notifications |
| `Super + L` | Lock screen |
| `Super + Z` | Noctalia Settings |

### Noctalia Configuration

Main config: `noctalia/.config/noctalia/config.toml`

This TOML file controls the bar layout, widgets, theme, lockscreen, idle behavior, and more. It is deployed via Home Manager to `~/.config/noctalia/config.toml`.

---

## 🐱 Kitty Terminal

Kitty is configured to receive its theme dynamically from Noctalia:

* Config: `kitty/.config/kitty/kitty.conf`
* Includes `current-theme.conf` (generated by Noctalia's Kitty template)
* No hardcoded colors — all colors are injected by Noctalia at theme switch time

---

## ⌨️ Shell Aliases (Power Tools)

The Zsh environment includes these shortcuts:

| Alias | Command | Description |
|-------|---------|-------------|
| `ls` / `ll` | `eza` | Modern directory listing with icons |
| `cat` | `bat` | File preview with syntax highlighting |
| `update` | `pacman -Syu` | Sync and update system base |
| `conf` | `cd ~/arch-install-script` | Quick jump to this repository |
| **`hms`** | `home-manager switch...` | **Apply Nix changes** (Rebuild user space) |
| `hmu` | `nix flake update...` | Update Nix dependencies & apply |
| `nclean` | `nix-collect-garbage` | Clean old Nix generations |

---

## 🗑️ Removed / Deprecated Components

The following components were intentionally removed from the stack:

| Component | Reason | Replaced By |
|-----------|--------|-------------|
| SDDM | Heavy, Qt-based | Greetd + tuigreet |
| Waybar | Separate bar process | Noctalia Bar |
| SwayNC | Separate notification daemon | Noctalia Notifications |
| Rofi | Separate launcher | Noctalia Launcher |
| hyprlock | Separate lockscreen | Noctalia Lockscreen |
| hypridle | Separate idle handler | Noctalia Idle |
| cliphist | Separate clipboard manager | Noctalia Clipboard |
| wall-manager | Custom wallpaper script | Noctalia Wallpaper |
| GameMode / MangoHud / Gamescope | Gaming bloat | Removed (no gaming support) |
| Flatpak / Podman / Distrobox | Container bloat | Removed |

---

## 🔧 Troubleshooting

**Noctalia doesn't start on login:**
* Ensure Greetd is enabled: `sudo systemctl enable --now greetd`
* Check tuigreet config: `cat /etc/greetd/config.toml`
* Verify Noctalia is installed: `which noctalia`

**Theme doesn't sync to Kitty:**
* Verify Kitty includes the theme: `grep include ~/.config/kitty/kitty.conf`
* Restart Kitty after theme change in Noctalia Settings

**Hyprland Lua config errors:**
* Check Hyprland version: `hyprland --version` (must be 0.55+)
* Check Lua syntax: `hyprctl reload` and watch for errors in the terminal

**Cursor disappears on bare metal (works in VM):**
* Cause 1 — theme not installed: `bibata-cursor-theme` and `papirus-icon-theme` are now in the install list (`setup_install.sh`). Verify the directory exists: `ls /usr/share/icons/Bibata-Modern-Ice`.
* Cause 2 — hardware cursor failure on integrated Intel/AMD GPUs: `no_hardware_cursors = 1` was added to `hypr/.config/hypr/config/misc.lua` to force software-rendered cursors.
* Cause 3 — variables not exported before UWSM starts the compositor: `~/.config/uwsm/env` now exports `XCURSOR_THEME=Bibata-Modern-Ice` and `XCURSOR_SIZE=24` (deployed via Home Manager).
* Cause 4 — GTK cursor mismatch: `~/.config/gtk-3.0/4.0/settings.ini` now set `gtk-cursor-theme-name = Bibata-Modern-Ice`.
* Apply the cursor theme at startup: `hyprctl setcursor Bibata-Modern-Ice 24` runs on `hyprland.start` in `hypr/.config/hypr/config/autostart.lua`.

---

## 📜 License

MIT License — see [LICENSE](LICENSE) for details.

---

<div align="center">
<sub>Built with ❤️ by StardustArch</sub>
</div>