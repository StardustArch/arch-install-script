-- Convertido de keybinds.conf em 2026-11-13; original em hypr-backup-2026-11-13/

return function(hl)
	local mod = "SUPER"
	local terminal = "kitty"
	local menu = "rofi -show drun -show-icons"

	-- ==========================================
	-- ATALHOS
	-- ==========================================
	hl.bind(mod .. " + Return", hl.dsp.exec("[tile] " .. terminal))
	hl.bind(mod .. " + C",      hl.dsp.killactive())
	hl.bind(mod .. " + M",      hl.dsp.exit())
	hl.bind(mod .. " + E",      hl.dsp.exec("dolphin"))
	hl.bind(mod .. " + V",      hl.dsp.togglefloating())
	hl.bind(mod .. " + SPACE",  hl.dsp.exec(menu))

	hl.bind(mod .. " + left",   hl.dsp.movefocus("l"))
	hl.bind(mod .. " + right",  hl.dsp.movefocus("r"))
	hl.bind(mod .. " + up",     hl.dsp.movefocus("u"))
	hl.bind(mod .. " + down",   hl.dsp.movefocus("d"))

	-- Internet (Network Manager TUI)
	hl.bind(mod .. " + N", hl.dsp.exec(terminal .. " --title \"Network Manager\" -e nmtui"))

	-- Bluetooth (Bluetuith)
	hl.bind(mod .. " + B", hl.dsp.exec(terminal .. " --title \"Bluetooth Manager\" -e bluetuith"))

	-- ==========================================
	-- SCREENSHOTS (Nix Tools)
	-- ==========================================
	-- bind = , Print, exec, grim -g "$(slurp)" - | wl-copy
	hl.bind("Print", hl.dsp.exec("grim -g \"$(slurp)\" - | wl-copy"))

	-- Shift + Print: Swappy
	hl.bind("SHIFT + Print", hl.dsp.exec("grim -g \"$(slurp)\" - | swappy -f -"))

	-- ==========================================
	-- CLIPBOARD (Com Rofi)
	-- Super + V: histórico
	hl.bind(mod .. " + V", hl.dsp.exec("cliphist list | rofi -dmenu -p \"Clipboard\" | cliphist decode | wl-copy"))

	-- ==========================================
	-- WALLPAPERS & TEMAS
	-- ==========================================
	hl.bind(mod .. " + W", hl.dsp.exec("wall-manager select"))
	hl.bind("SUPER + SHIFT + W", hl.dsp.exec("wall-manager static"))
	hl.bind(mod .. " + T", hl.dsp.exec("wall-manager switch"))

	-- ==========================================
	-- GESTÃO DE JANELAS
	-- ==========================================
	hl.bind(mod .. " + P", hl.dsp.pseudo())
	hl.bind(mod .. " + J", hl.dsp.togglesplit())
	hl.bind(mod .. " + F", hl.dsp.fullscreen())

	-- ==========================================
	-- ÁUDIO (teclas multimídia)
	-- ==========================================
	hl.bind("", "XF86AudioRaiseVolume", hl.dsp.exec("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"))
	hl.bind("", "XF86AudioLowerVolume", hl.dsp.exec("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"))
	hl.bind("", "XF86AudioMute",        hl.dsp.exec("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"))

	-- ==========================================
	-- WORKSPACES
	-- ==========================================
	for i = 1, 10 do
		local ws = tostring(i == 10 and 10 or i)
		hl.bind(mod .. " + " .. ws, hl.dsp.workspace(ws))
		hl.bind(mod .. " + SHIFT + " .. ws, hl.dsp.movetoworkspace(ws))
	end

	-- Scroll workspaces
	hl.bind(mod .. " + mouse_down", hl.dsp.workspace("e+1"))
	hl.bind(mod .. " + mouse_up",   hl.dsp.workspace("e-1"))

	-- ==========================================
	-- SCRATCHPAD / SPECIAL WORKSPACE
	-- ==========================================
	hl.bind(mod .. " + S", hl.dsp.togglespecialworkspace("magic"))
	hl.bind("SUPER + SHIFT + S", hl.dsp.movetoworkspace("special:magic"))

	-- ==========================================
	-- TODO: GameMode (Super + F1) REMOVIDO — suporte a gaming eliminado do ambiente
	-- original: bind = $mainMod, F1, exec, ~/.config/hypr/scripts/gamemode.sh
end
