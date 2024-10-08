{ config, pkgs, ... }:
{
  # Enable networking
  # networking.networkmanager.enable = true;
  # networking.networkmanager.dns = "none";

  # # Select internationalisation properties.
  # i18n.defaultLocale = "en_US.UTF-8";

  # i18n.extraLocaleSettings = {
  #   LC_ADDRESS = "nl_NL.UTF-8";
  #   LC_IDENTIFICATION = "nl_NL.UTF-8";
  #   LC_MEASUREMENT = "nl_NL.UTF-8";
  #   LC_MONETARY = "nl_NL.UTF-8";
  #   LC_NAME = "nl_NL.UTF-8";
  #   LC_NUMERIC = "nl_NL.UTF-8";
  #   LC_PAPER = "nl_NL.UTF-8";
  #   LC_TELEPHONE = "nl_NL.UTF-8";
  #   LC_TIME = "nl_NL.UTF-8";
  # };

  # # Enable the X11 windowing system.
  # services.xserver.enable = true;

  # # Enable the GNOME Desktop Environment.
  # services.xserver.displayManager.gdm.enable = true;
  # services.xserver.desktopManager.gnome.enable = true;

  # services.displayManager.autoLogin.enable = true;
  # services.displayManager.autoLogin.user = "szeth";
  # # https://github.com/NixOS/nixpkgs/issues/103746#issuecomment-945091229
  # systemd.services."getty@tty1".enable = false;
  # systemd.services."autovt@tty1".enable = false;
  # # maybe try these if it doesn't work
  # # systemd.sleep.extraConfig = ''
  # #   AllowSuspend=no
  # #   AllowHibernation=no
  # # '';

  # # Configure keymap in X11
  # services.xserver.xkb = {
  #   layout = "us";
  #   variant = "";
  # };

  # # Enable CUPS to print documents.
  # services.printing.enable = true;

  # hardware.pulseaudio.enable = false;
  # security.rtkit.enable = true;
  # services.pipewire = {
  #   enable = true;
  #   alsa.enable = true;
  #   alsa.support32Bit = true;
  #   pulse.enable = true;
  #   # If you want to use JACK applications, uncomment this
  #   #jack.enable = true;

  #   # use the example session manager (no others are packaged yet so this is enabled by default,
  #   # no need to redefine it in your config for now)
  #   #media-session.enable = true;
  # };
}
