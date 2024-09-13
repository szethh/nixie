{ config, ... }:

let
  cfg = config.services.mastodon;
in
{
  imports = [ ./proxy.nix ];

  sops.secrets = {
    MASTODON_DB_PASSWORD = {
      owner = "mastodon";
    };
  };

  # to create an account
  # sudo -u mastodon mastodon-tootctl accounts create username --email=username@localhost --confirmed --role=Owner
  # then approve it
  # sudo -u mastodon mastodon-tootctl accounts approve username
  # then reset the password
  # sudo -u mastodon mastodon-tootctl accounts modify --reset-password username

  services.mastodon = {
    enable = true;
    localDomain = "social.bnuuy.net"; # Replace with your own domain
    smtp.fromAddress = "noreply@social.bnuuy.net"; # Email address used by Mastodon to send emails, replace with your own
    extraConfig = {
      SINGLE_USER_MODE = "true";
      LOCAL_HTTPS = "true";
    };
    streamingProcesses = 3; # Number of processes used by the mastodon-streaming service. recommended is the amount of your CPU cores minus one.
    # configureNginx = true;
    database.passwordFile = config.sops.secrets.MASTODON_DB_PASSWORD.path;
  };
}
