-- Auto-start config
-- Use UWSM if available, otherwise add your auto start programs here

hl.on("hyprland.start", function ()
    hl.exec_cmd("dbus-update-activation-environment --systemd --all")
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")
    hl.exec_cmd("noctalia")
    hl.exec_cmd("hyprctl setcursor Bibata-Modern-Ice 24")
end)
