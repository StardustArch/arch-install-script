-- Convertido de colors.conf + env.conf em 2026-11-13; original em hypr-backup-2026-11-13/
-- Módulo de tema: cores semânticas e variáveis de ambiente (hl.config/env)

local M = {}

-- ==========================================
-- PALETA SEMÂNTICA (NORD por padrão; sobrescrevível via hl.config)
-- ==========================================
M.colors = {
	bg0   = "2e3440ff",
	bg1   = "3b4252ff",
	bg2   = "434c5eff",
	bg3   = "4c566aff",
	fg0   = "d8dee9ff",
	fg1   = "e5e9f0ff",
	fg2   = "eceff4ff",
	accent0 = "8fbcbbff",
	accent1 = "88c0d0ff",
	accent2 = "81a1c1ff",
	accent3 = "5e81acff",
	red   = "bf616aff",
	orange = "d08770ff",
	yellow = "ebcb8bff",
	green  = "a3be8cff",
	purple = "b48eadff",
	shadow_col = "00000055",
}

-- ==========================================
-- VARIÁVEIS DE AMBIENTE (hl.config → env)
-- ==========================================
M.env = {
	XCURSOR_THEME  = "Bibata-Modern-Ice",
	XCURSOR_SIZE   = "24",
	GTK_THEME      = "Nordic",      -- atualizado pelo Nix via home.nix
	QT_QPA_PLATFORMTHEME = "gtk3",  -- align com sessionVariables do home.nix
	XDG_CURRENT_DESKTOP = "Hyprland",
	XDG_SESSION_TYPE    = "wayland",
	XDG_SESSION_DESKTOP = "Hyprland",
	GDK_BACKEND    = "wayland,x11",
	QT_AUTO_SCREEN_SCALE_FACTOR = "1",
	QT_WAYLAND_DISABLE_WINDOWDECORATION = "1",
	XDG_DATA_DIRS  = os.getenv("HOME") .. "/.nix-profile/share:/usr/local/share:/usr/share:" .. (os.getenv("XDG_DATA_DIRS") or ""),
}

-- ==========================================
-- FUNÇÃO DE APLICAÇÃO (chamada do hyprland.lua)
-- ==========================================
function M.apply(hl)
	-- Aplica variáveis de ambiente
	for k, v in pairs(M.env) do
		hl.env(k, v)
	end

	-- Retorna a tabela de cores para uso noutros módulos
	return M.colors
end

return M
