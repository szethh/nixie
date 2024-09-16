{
  config,
  pkgs,
  inputs,
  lib,
  ...
}:

let
  # taken from https://github.com/nix-community/home-manager/issues/5757#issuecomment-2297141696
  mkExclusionList =
    path:
    let
      content = builtins.readFile path;
      lines = builtins.split "\n" content;
      nonEmptyLines = lib.filter (
        line: (builtins.isString (line) && line != "" && !lib.strings.hasPrefix "#" line)
      ) lines;
    in
    nonEmptyLines;

  # these come from https://github.com/SterlingHooten/borg-backup-exclusions-macos
  macOsExclusions = lib.optionals pkgs.stdenv.isDarwin (
    lib.concatMap (path: mkExclusionList path) [
      ./resources/borgmatic/exclusions/macos/core.lst
      ./resources/borgmatic/exclusions/macos/applications.lst
      ./resources/borgmatic/exclusions/macos/programming.lst
    ]
  );
in
{
  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "24.05"; # Please read the comment before changing.

  imports = [ inputs.sops-nix.homeManagerModules.sops ];

  home.homeDirectory = "/Users/szeth";

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = with pkgs; [
    bat
    borgmatic
    eza
    nerdfonts # necessary for agnoster theme
    starship
    yt-dlp
    vscode
    # # It is sometimes useful to fine-tune packages, for example, by applying
    # # overrides. You can do that directly here, just don't forget the
    # # parentheses. Maybe you want to install Nerd Fonts with a limited number of
    # # fonts?
    # (pkgs.nerdfonts.override { fonts = [ "FantasqueSansMono" ]; })

    # # You can also create simple shell scripts directly inside your
    # # configuration. For example, this adds a command 'my-hello' to your
    # # environment:
    # (pkgs.writeShellScriptBin "my-hello" ''
    #   echo "Hello, ${config.home.username}!"
    # '')
  ];

  programs.zoxide.enable = true;
  programs.thefuck.enable = true;

  programs = {
    starship =
      let
        shellConfig = import ./common/shell.nix { inherit pkgs; };
      in
      shellConfig.programs.starship;
  };

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;

    # for some reason these are flipped
    initExtra = ''
      bindkey '^[[Z'   complete-word       # tab          | complete
      bindkey '^I'     autosuggest-accept  # shift + tab  | autosuggest
    '';
  };

  programs.git = {
    enable = true;
    userEmail = "33635766+szethh@users.noreply.github.com";
    userName = "szethh";
    extraConfig = {
      init = {
        defaultBranch = "main";
      };
    };
  };

  programs.bat.enable = true;
  programs.bat.config.theme = "Nord";

  programs.vscode = import ./darwin/apps/vscode.nix { inherit pkgs inputs; };

  # this does not work yet
  programs.firefox = import ./darwin/apps/firefox.nix { inherit pkgs inputs; };

  sops = {
    # does not seem to work
    age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt"; # must have no password!
    # It's also possible to use a ssh key, but only when it has no password:
    age.sshKeyPaths = [ "${config.home.homeDirectory}/.ssh/id_ed25519" ];
    age.generateKey = true;
    defaultSopsFile = ./secrets/secrets.yaml;
    # test secret
    secrets.test = {
      # sopsFile = ./secrets.yml.enc; # optionally define per-secret files

      # %r gets replaced with a runtime directory, use %% to specify a '%'
      # sign. Runtime dir is $XDG_RUNTIME_DIR on linux and $(getconf
      # DARWIN_USER_TEMP_DIR) on darwin.
      # path = "%r/test.txt"; 
    };
  };

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    # # Building this configuration will create a copy of 'dotfiles/screenrc' in
    # # the Nix store. Activating the configuration will then make '~/.screenrc' a
    # # symlink to the Nix store copy.
    # ".screenrc".source = dotfiles/screenrc;
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  sops.secrets.BORG_PASSPHRASE = { };

  ### BORG ###
  # options here: https://home-manager-options.extranix.com/?query=programs.borg&release=master
  # note: the first time we have to manually initialize the repo
  # borgmatic init --encryption repokey
  programs.borgmatic = {
    enable = true;
    package = pkgs.borgmatic;
    backups = {
      "borgbase" = {
        location = {
          repositories = [ "ssh://f9xvfh0h@f9xvfh0h.repo.borgbase.com/./repo" ];
          patterns = [
            # i figured it's easier to just list what we want to backup
            # rather than trying to exclude everything
            "R ${config.home.homeDirectory}/uni"
            "R ${config.home.homeDirectory}/Zotero"
            "R ${config.home.homeDirectory}/gallery-dl"
            "R ${config.home.homeDirectory}/Monero"
            "R ${config.home.homeDirectory}/MEGAsync"
            # todo: do i want to backup dev?
            # a lot of stuff is in git already
            # but many projects aren't
            # "! ${config.home.homeDirectory}/dev"
          ] ++ macOsExclusions;

          excludeHomeManagerSymlinks = true;
        };
        storage = {
          encryptionPasscommand = "cat ${config.sops.secrets.BORG_PASSPHRASE.path}";
        };

        retention = {
          keepWithin = "1d";
          keepDaily = 7;
          keepWeekly = 4;
          keepMonthly = 6;
        };

        consistency.checks = [
          {
            name = "repository";
            frequency = "2 weeks";
          }
          {
            name = "archives";
            frequency = "2 weeks";
          }
        ];
      };
    };
  };
}
