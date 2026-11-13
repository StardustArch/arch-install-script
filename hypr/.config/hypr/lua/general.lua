-- Convertido de hyprland.conf (seções general, decoration, animations, misc, input) em 2026-11-13; original em hypr-backup-2026-11-13/

return function(hl, colors)
	-- ==========================================
	-- MONITOR
	-- ==========================================
	-- monitor=,preferred,auto,1  (hyprlang)
	-- hl.monitor({ ... }) — parâmetros conforme hl.meta.lua
	-- TODO: substituir "eDP-1" pelo output real do seu hardware (ex: "HDMI-A-1", "DP-1")
	hl.monitor({
		output = "eDP-1",
	})

	-- ==========================================
	-- INPUT
	-- ==========================================
	hl.config({
		input = {
			kb_layout = "us",
		},
	})

	-- ==========================================
	-- GENERAL
	-- ==========================================
	hl.config({
		general = {
			gaps_in   = 5,
			gaps_out  = 10,
			border_size = 2,
			layout    = "dwindle",
			allow_tearing = true,
		},
	})

	-- Borda ativa e inativa (cores sólidas — formato RGBA de 8 dígitos aceito pelo parser Lua)
	-- TODO: restaurar gradiente ($accent1 $accent3 45deg) quando o formato de tabela for confirmado
	hl.config({
		general = {
			col = {
				active_border   = colors.accent1,   -- "88c0d0ff"
				inactive_border = colors.bg3,       -- "4c566aff"
			},
		},
	})

	-- ==========================================
	-- DECORATION
	-- ==========================================
	hl.config({
		decoration = {
			rounding = 10,
			active_opacity = 0.95,
			inactive_opacity = 0.90,
			fullscreen_opacity = 1.0,
			blur = {
				enabled        = true,
				size           = 6,
				passes         = 3,
				new_optimizations = true,
				xray           = true,
				ignore_opacity = true,
			},
			shadow = {
				enabled   = true,
				range     = 15,
				render_power = 3,
				color      = colors.shadow_col,
			},
		},
	})

	-- ==========================================
	-- DWINDLE
	-- ==========================================
	hl.config({
		dwindle = {
			pseudotile    = true,   -- hyprlang: yes → true; NOTA: removido em 0.55+ (ver breaking changes)
			preserve_split = true,
		},
	})

	-- ==========================================
	-- MISC
	-- ==========================================
	hl.config({
		misc = {
			disable_hyprland_logo      = true,
			disable_splash_rendering   = true,
			background_color           = 0x101d31,  -- TODO: hardcoded Aizome; tornar dinâmico por tema
			vrr = 2,
		},
	})

	-- ==========================================
	-- ANIMATIONS
	-- ==========================================
	hl.config({
		animations = {
			enabled = true,
			bezier = {
				myBezier = { 0.05, 0.9, 0.1, 1.05 },
			},
			animation = {
				{ name = "windows",       params = { 1, 5, "myBezier" } },
				{ name = "windowsOut",    params = { 1, 5, "default", "popin 80%" } },
				{ name = "border",        params = { 1, 8, "default" } },
				{ name = "fade",          params = { 1, 5, "default" } },
				{ name = "workspaces",    params = { 1, 4, "default", "slide" } },
			},
		},
	})
end
