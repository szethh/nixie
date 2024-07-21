{ pkgs, disko, ... }:

{
  imports = [ ./proxmox.nix ];

  deployment = {
    targetUser = "root";
    buildOnTarget = true;

    # https://github.com/zhaofengli/colmena/issues/153
    keys = { age = { keyFile = "/Users/szeth/.config/sops/age/keys.txt"; }; };
  };

}
