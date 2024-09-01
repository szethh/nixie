## EXPLANATION ##
# for now, we are simply copying the docker-compose.yml file
# so we are not using nix to run the containers
# maybe in the future we can use https://github.com/aksiksi/compose2nix
# i tried it and it works (it generates a nix file)
# but i'm a bit scared that it will differ from the compose implementation
# especially since we rely on docker networking and the containers talking to each other
# so for now i'm parking this here, it works fine.
# one thing to note is that, in order to avoid permission fuckery,
# we should first run `su vpn` and then run the compose command
# since all the files are owned by vpn, not root
{
  pkgs,
  lib,
  config,
  ...
}:

let
  mamUpdater = import ../../packages/mam_updater.nix { inherit pkgs; };
in
{
  sops.secrets = {
    PROTON_OVPN_USER = {
      owner = "vpn";
    };
    PROTON_OVPN_PASS = {
      owner = "vpn";
    };
    QBIT_PASS = {
      owner = "vpn";
    };
  };

  # format secret as env file
  sops.templates.VPN_ENV.content = ''
    QBIT_PASS="${config.sops.placeholder.QBIT_PASS}"
    QBIT_PUID="${toString config.users.users.vpn.uid}"
    QBIT_PGID="${toString config.users.groups.docker.gid}"
    PROTON_OVPN_USER="${config.sops.placeholder.PROTON_OVPN_USER}"
    PROTON_OVPN_PASS="${config.sops.placeholder.PROTON_OVPN_PASS}"
  '';

  # services.docker.enable = true;
  virtualisation.docker.enable = true;

  users.users.vpn = {
    isNormalUser = true;
    description = "VPN stack user";
    # grr we have to manually set the uid
    # so that sops can write the .env file
    # otherwise it gets read as null...
    uid = 1001;
    home = "/var/lib/vpn";
    createHome = true;
    shell = pkgs.bashInteractive;
    extraGroups = [ "docker" ];
  };

  deployment.keys.vpn-compose = {
    name = "docker-compose.yml";
    destDir = "/var/lib/vpn";
    keyFile = ./docker-compose.yml;
    user = config.users.users.vpn.name;
    group = "docker";
    permissions = "0644";
  };

  # Copy the .env file to the user's home directory
  system.activationScripts.copyVpnEnvFile = {
    text = ''
      cp ${config.sops.templates.VPN_ENV.path} ${config.users.users.vpn.home}/.env
      chown ${config.users.users.vpn.name}:${config.users.users.vpn.group} ${config.users.users.vpn.home}/.env
      chmod 400 ${config.users.users.vpn.home}/.env
    '';
  };

  # copy mam updater
  environment.systemPackages = [ pkgs.git ]; # Ensure git is installed
  system.activationScripts.cloneMamUpdater = ''
    # Create the target directory if it doesn't exist
    mkdir -p /var/lib/vpn/mam_updater

    # Copy the repository to the target directory
    cp -r ${mamUpdater}/* /var/lib/vpn/mam_updater/

    # Set the correct ownership and permissions
    chown -R ${config.users.users.vpn.name}:${config.users.users.vpn.group} /var/lib/vpn/mam_updater
  '';

}
