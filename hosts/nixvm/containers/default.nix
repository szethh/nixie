{ pkgs, ... }:
{
  imports = [
    ../../../apps/media-stack
    ../../../apps/immich
  ];

  # Runtime
  virtualisation.docker = {
    enable = true;
    autoPrune.enable = true;
  };
  virtualisation.oci-containers.backend = "docker";
}
