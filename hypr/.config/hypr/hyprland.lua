-- Convertido de hyprland.conf em 2026-11-13; original em hypr-backup-2026-11-13/
-- Entry point da configuração Hyprland 0.55+ (Lua)
-- Carrega módulos a partir de ~/.config/hypr/lua/

-- Ajusta package.path para encontrar os módulos locais
local home = os.getenv("HOME") or ""
package.path = home .. "/.config/hypr/lua/?.lua;" .. package.path

local theme = require("theme")
local general = require("general")
local keybinds = require("keybinds")
local autostart = require("autostart")
local rules = require("rules")

-- ==========================================
-- 1. TEMA E VARIÁVEIS DE AMBIENTE
-- ==========================================
local colors = theme.apply(hl)

-- ==========================================
-- 2. GENERAL / DECORATION / ANIMATIONS / MISC
-- ==========================================
general(hl, colors)

-- ==========================================
-- 3. KEYBINDS
-- ==========================================
keybinds(hl)

-- ==========================================
-- 4. AUTOSTART (hyprland.start event)
-- ==========================================
autostart(hl)

-- ==========================================
-- 5. RULES (window/layer/workspace)
-- ==========================================
rules(hl)

-- ==========================================
-- MONITOR (exemplo; ajustar conforme hardware real)
-- ==========================================
-- hl.monitor({
--     -- TODO: configurar monitor conforme output de `hyprctl monitors`
-- })
