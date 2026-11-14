{ config, lib, ... }:

{
  # GTK/Qt: fixo mínimo no Home Manager. As cores são geradas pelo
  # Noctalia (noctalia.css); aqui só se fixam tema, ícones e cursor.
  home.file = {
    ".config/gtk-3.0/settings.ini".text = ''
      [Settings]
      gtk-theme-name = adw-gtk3
      gtk-cursor-theme-name = Bibata-Modern-Ice
      gtk-cursor-theme-size = 24
      gtk-icon-theme-name = Papirus-Dark
    '';

    ".config/gtk-4.0/settings.ini".text = ''
      [Settings]
      gtk-theme-name = adw-gtk3
      gtk-cursor-theme-name = Bibata-Modern-Ice
      gtk-cursor-theme-size = 24
      gtk-icon-theme-name = Papirus-Dark
    '';
  };
}
