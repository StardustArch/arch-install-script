-- Convertido de autostart.conf em 2026-11-13; original em hypr-backup-2026-11-13/

return function(hl)
	-- ==========================================
	-- hyprland.start event (equivalente a exec-once)
	-- Fonte: Hyprland Wiki (0.55+) — autostart via hl.on("hyprland.start", ...)
	-- ==========================================
	hl.on("hyprland.start", function()
		-- 1. Autenticação (polkit)
		hl.exec_once("/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1")

		-- 2. Wallpaper & Temas (script do Nix/Home Manager)
		hl.exec_once(os.getenv("HOME") .. "/.nix-profile/bin/wall-manager static")

		-- 3. Interface do Sistema
		hl.exec_once("waybar")
		hl.exec_once("swaync")
		hl.exec_once("hypridle")

		-- 4. Clipboard
		hl.exec_once("wl-paste --type text --watch cliphist store")
		hl.exec_once("wl-paste --type image --watch cliphist store")

		-- 5. Cursor (tema Bibata no arranque)
		hl.exec_once("hyprctl setcursor Bibata-Modern-Ice 24")
	end)
end
