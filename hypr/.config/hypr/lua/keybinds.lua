-- Convertido de keybinds.conf em 2026-11-13; original em hypr-backup-2026-11-13/

return function(hl)
	local mod = "SUPER"
	local terminal = "kitty"
	local menu = "rofi -show drun -show-icons"

	-- ==========================================
	-- ATALHOS
	-- ==========================================
	hl.bind(mod .. " + Return", "exec", "[tile] " .. terminal)
	hl.bind(mod .. " + C",      "killactive")
	hl.bind(mod .. " + M",      "exit")
	hl.bind(mod .. " + E",      "exec", "dolphin")
	hl.bind(mod .. " + V",      "togglefloating")
	hl.bind(mod .. " + SPACE",  "exec", menu)

	hl.bind(mod .. " + left",   "movefocus", "l")
	hl.bind(mod .. " + right",  "movefocus", "r")
	hl.bind(mod .. " + up",     "movefocus", "u")
	hl.bind(mod .. " + down",   "movefocus", "d")

	-- Internet (Network Manager TUI)
	hl.bind(mod .. " + N", "exec", terminal .. " --title \"Network Manager\" -e nmtui")

	-- Bluetooth (Bluetuith)
	hl.bind(mod .. " + B", "exec", terminal .. " --title \"Bluetooth Manager\" -e bluetuith")

	-- ==========================================
	-- SCREENSHOTS (Nix Tools)
	-- ==========================================
	-- bind = , Print, exec, grim -g "$(slurp)" - | wl-copy
	hl.bind("Print", "exec", "grim -g \"$(slurp)\" - | wl-copy")

	-- Shift + Print: Swappy
	hl.bind("SHIFT + Print", "exec", "grim -g \"$(slurp)\" - | swappy -f -")

	-- ==========================================
	-- CLIPBOARD (Com Rofi)
	-- Super + V: histórico
	hl.bind(mod .. " + V", "exec", "cliphist list | rofi -dmenu -p \"Clipboard\" | cliphist decode | wl-copy")

	-- ==========================================
	-- WALLPAPERS & TEMAS
	-- ==========================================
	hl.bind(mod .. " + W", "exec", "wall-manager select")
	hl.bind("SUPER + SHIFT + W", "exec", "wall-manager static")
	hl.bind(mod .. " + T", "exec", "wall-manager switch")

	-- ==========================================
	-- GESTÃO DE JANELAS
	-- ==========================================
	hl.bind(mod .. " + P", "pseudo")
	hl.bind(mod .. " + J", "togglesplit")
	hl.bind(mod .. " + F", "fullscreen")

	-- ==========================================
	-- ÁUDIO (teclas multimídia)
	-- ==========================================
	hl.bind("", "XF86AudioRaiseVolume", "exec", "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+")
	hl.bind("", "XF86AudioLowerVolume", "exec", "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-")
	hl.bind("", "XF86AudioMute",        "exec", "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle")

	-- ==========================================
	-- WORKSPACES
	-- ==========================================
	for i = 1, 10 do
		local ws = tostring(i == 10 and 10 or i)
		hl.bind(mod .. " + " .. ws, "workspace", ws)
		hl.bind(mod .. " + SHIFT + " .. ws, "movetoworkspace", ws)
	end

	-- Scroll workspaces
	hl.bind(mod .. " + mouse_down", "workspace", "e+1")
	hl.bind(mod .. " + mouse_up",   "workspace", "e-1")

	-- ==========================================
	-- SCRATCHPAD / SPECIAL WORKSPACE
	-- ==========================================
	hl.bind(mod .. " + S", "togglespecialworkspace", "magic")
	hl.bind("SUPER + SHIFT + S", "movetoworkspace", "special:magic")

	-- ==========================================
	-- TODO: GameMode (Super + F1) REMOVIDO — suporte a gaming eliminado do ambiente
	-- original: bind = $mainMod, F1, exec, ~/.config/hypr/scripts/gamemode.sh
end
