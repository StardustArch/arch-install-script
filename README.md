
# StardustArch (Hyprland + Nix)

![Arch Linux](https://img.shields.io/badge/Arch%20Linux-1793D1?logo=arch-linux&logoColor=white) ![Nix](https://img.shields.io/badge/Nix-5277C3?logo=nixos&logoColor=white) ![Hyprland](https://img.shields.io/badge/Hyprland-00A4CC?logo=linux&logoColor=white)

A reproducible Arch Linux environment managed by **Pacman** (System layer) and **Nix Home Manager** (User layer).

Featuring a custom **Dynamic Theme System** (Aizome, Nord, Gruvbox) that instantly syncs Wallpaper, Waybar, Rofi, GTK and QT.

## Features

* **Hybrid Architecture:**
    * **System Core:** Drivers, Hyprland, and Waybar installed via `pacman` for stability.
    * **User Space:** Shell, Neovim, and CLI tools managed via `Nix` for portability.
* **Automated Bootstrap:** `archinstall` JSON configurations for a hands-off base installation.
* **Theme Engine:** Custom scripts (`wall-manager`) to switch themes and wallpapers on the fly.
* **Gaming Ready:** Pre-configured with GameMode, MangoHud, and Steam optimizations.

## 📂 Repository Structure

```text
├── bootstrap/           # JSON configs for the Arch ISO installer
│   ├── UserConfig.json  # Minimal profile & Btrfs layout (Diskless)
│   └── UserCredentials.json # User setup (stardust)
├── nix/                 # Nix Home Manager configurations
│   ├── flake.nix        # Flake entry point
│   └── home.nix         # User packages, Aliases & Dotfiles logic
├── hypr/                # Hyprland configs (sourced by Nix)
├── kitty/               # Kitty terminal configs (sourced by Nix)
├── rofi/                # Rofi menus & theme configs (sourced by Nix)
├── swaync/              # Notification center configs (sourced by Nix)
├── waybar/              # Waybar status bar configs (sourced by Nix)
├── setup_install.sh     # Main post-install automation script
└── README.md

```

---

## Installation Guide


> **⚠️ CRITICAL WARNING:** The username defined in `bootstrap/UserCredentials.json` (default: `stardust`) **MUST MATCH** the username configured in:
> * `nix/flake.nix`
> * `nix/home.nix`
> * `setup_install.sh`
>
>
### Phase 1: Base System (The ISO)

1.  **Boot & Connect:**
    * Boot into the Arch Linux ISO.
    * Ensure you have internet access (check with `ping -c 3 google.com`).

2.  **Download Configs:**
    Fetch the configuration files directly from the repository to the temporary RAM (`/tmp`).

    ```bash
      cd /tmp
      curl -O https://raw.githubusercontent.com/StardustArch/arch-install-script/main/bootstrap/UserConfig.json
      curl -O https://raw.githubusercontent.com/StardustArch/arch-install-script/main/bootstrap/UserCredentials.json
    ```

3.  **Run Installer:**
    Execute the automated installer pointing to the downloaded files:

    ```bash
    archinstall --config /tmp/UserConfig.json --creds /tmp/UserCredentials.json
    ```

4. **Select Disk:**
* Go to **"Disk Configuration"**.
* Select your target drive (e.g., `/dev/nvme0n1`).
* Select **Btrfs** (recommended).
* **Install**.


5. **Reboot:**
Once finished, reboot into your new system and login as `<your_user_name>`.
---

### Phase 2: User Setup (The Magic)

1. **Clone the Repository:**
```bash
git clone https://github.com/StardustArch/arch-install-script.git
cd ~/arch-install-script

```


2. **Run the Installer:**
This script will install Hyprland, initialize Nix, and set up your dotfiles.
```bash
chmod +x setup_install.sh
./setup_install.sh

```


3. **Finalize:**
Once the script finishes, **reboot** one last time.

---

## 🎨 Theme Management

This setup uses a custom logic to sync themes across the entire system.

### Changing Themes

Use the shortcut `Super + T` to open the Theme Picker, or run via terminal:

```bash
# Available themes: nord, aizome, gruvbox
set-theme aizome

```

**What happens when you switch?**

1. **Nix:** Rebuilds GTK/QT configs.
2. **Wallpaper:** Changes to a random image from the theme folder.
3. **Waybar/Rofi:** Reloads CSS colors.
4. **VS Code:** Updates the color theme automatically.

### Wallpapers

* **Picker:** Press `Super + W` to select a wallpaper visually via Rofi.
* **Random:** Press `Super + Shift + W` to cycle a random wallpaper from the current theme.

---

## ⌨️ Keybindings

This setup relies on a dedicated configuration file for keybindings. Instead of listing hundreds of shortcuts here, you can view the live configuration directly on your system.

**To view all keybindings:**
```bash
cat ~/.config/hypr/keybinds.conf
```
---

## 🛠️ Shell Aliases (Power Tools)

The Zsh environment is boosted with these shortcuts for productivity:

| Alias | Command | Description |
| :--- | :--- | :--- |
| `ls` / `ll` | `eza` | Modern directory listing with icons |
| `cat` | `bat` | File preview with syntax highlighting |
| `update` | `pacman -Syu` | Sync and update system base |
| `conf` | `cd ~/arch-install-script` | Quick jump to this repository |
| **`hms`** | `home-manager switch...` | **Apply Nix changes** (Rebuild system) |
| `hmu` | `nix flake update...` | Update Nix dependencies & apply |
| `nclean` | `nix-collect-garbage` | Clean old Nix generations (Free space) |

---

<div align="center">
<sub>Built with ❤️ by StardustArch</sub>
</div>
