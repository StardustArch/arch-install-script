{ config, lib, ... }:

{
  programs.git = {
    enable = true;
    settings.user = {
      name = "StardustArch";
      email = "paulojoaocandrinho4@gmail.com";
    };
  };
}
