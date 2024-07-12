{ modulesPath, lib, name, pkgs, config, ... }:

{
  imports = [
    # not sure what this does
    ./bootstrap.nix
    ../../common/szeth.nix
  ];

  # sops.defaultSopsFile = ../../secrets/secrets.yaml;
  # sops.age.keyFile = "${config.deployment.keys.age.destDir}/age";
  # sops.secrets = {
  #   
  # };

  deployment = {
    targetHost = "htz";
    targetUser = "root";
    buildOnTarget = true;

    # https://github.com/zhaofengli/colmena/issues/153
    keys = { age = { keyFile = "/Users/szeth/.config/sops/age/keys.txt"; }; };
  };

  programs.zsh.enable = true;

  services.tailscale.enable = true;
}
