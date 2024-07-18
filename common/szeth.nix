{ config, pkgs, ... }:

{
  imports = [ ./shell.nix ];

  environment.systemPackages = with pkgs; [ bat starship docker ];

  users.users.szeth = {
    isNormalUser = true;
    uid = 1000;
    home = "/home/szeth";
    createHome = true;
    shell = pkgs.zsh;
    extraGroups = [ "wheel" ];

    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDgnIn7uXqucLjBn3fcJtRoeTVtpAIs/vFub8ULiud1f szeth@mackie.local"
    ];
  };
}
