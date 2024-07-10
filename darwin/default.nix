{ pkgs, ... }:

{
  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages = with pkgs; [
    ansible
    bitwarden-cli
    btop
    dua
    duf
    docker-compose
    ffmpeg
    git
    htop
    jetbrains-mono  # fonts
    ripgrep
    vim
    zoxide
  ];

  # Necessary for using flakes on this system.
  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      warn-dirty = false;
    };
  };

  homebrew = {
    enable = true;
    onActivation.upgrade = true;
    casks = [
      "audacity"
      "balenaetcher"
      "calibre"
      "discord"
      "docker"
      "drawio"
      "firefox"
      "google-chrome"
      "handbrake"
      "iterm2"
      "jellyfin-media-player"
      "keepassxc"
      "libreoffice"
      "megasync"
      "microsoft-auto-update"
      "microsoft-excel"
      "microsoft-teams"
      "microsoft-word"
      "minecraft"
      "monero-wallet"
      "obsidian"
      "obs"
      "postman"
      "proton-drive"
      "protonmail-bridge"
      "protonvpn"
      "qbittorrent"
      "rider"
      "rectangle"
      "rustdesk"
      "rustrover"
      "steam"
      "spotify"
      "syncthing"
      "textmate"
      "tor-browser"
      "visual-studio-code"
      "vlc"
      "vorta"
      "waterfox"
    ];
  };

  # Auto upgrade nix package and the daemon service.
  services.nix-daemon.enable = true;
  # nix.package = pkgs.nix;

  ## MACOS SETTINGS ##
  # Add ability to used TouchID for sudo authentication
  security.pam.enableSudoTouchIdAuth = true;

  system.activationScripts.postUserActivation.text = ''
    # Following line should allow us to avoid a logout/login cycle
    /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
  '';
  system.defaults = {
    NSGlobalDomain = {
      AppleInterfaceStyle = "Dark";
      AppleShowAllExtensions = true;
      AppleShowAllFiles = true;
      NSDocumentSaveNewDocumentsToCloud = false;
      NSNavPanelExpandedStateForSaveMode = true;
      NSNavPanelExpandedStateForSaveMode2 = true;
      "com.apple.mouse.tapBehavior" = 1;
    };
    
    LaunchServices.LSQuarantine = false; # disables "Are you sure?" for new apps
    loginwindow.GuestEnabled = false;
  };

  system.defaults.CustomUserPreferences = {

    "com.apple.finder" = {
      ShowExternalHardDrivesOnDesktop = true;
      ShowHardDrivesOnDesktop = false;
      ShowMountedServersOnDesktop = false;
      ShowRemovableMediaOnDesktop = true;
      _FXSortFoldersFirst = true;
      # When performing a search, search the current folder by default
      FXDefaultSearchScope = "SCcf";
      "FK_SidebarWidth" = 128;
      NewWindowTarget = "PfHm";
      NewWindowTargetPath = "file://$\{HOME\}";
      AppleShowAllExtensions = true;
      FXEnableExtensionChangeWarning = false;
      ShowStatusBar = true;
      ShowPathbar = true;
    };
    "com.apple.dock" = {
      autohide = false;
      show-recents = false;
      show-process-indicators = true;
      tilesize = 64;
      # can we also declare the apps that are pinned?
    };
    "com.apple.desktopservices" = {
      # Avoid creating .DS_Store files on network or USB volumes
      DSDontWriteNetworkStores = true;
      DSDontWriteUSBStores = true;
    };
    # "com.apple.Safari" = {
    #   # Privacy: don’t send search queries to Apple
    #   UniversalSearchEnabled = false;
    #   SuppressSearchSuggestions = true;
    # };
    "com.apple.AdLib" = {
      allowApplePersonalizedAdvertising = false;
    };
    
    "com.apple.SoftwareUpdate" = {
      AutomaticCheckEnabled = true;
      # Check for software updates daily, not just once per week
      ScheduleFrequency = 1;
      # Download newly available updates in background
      AutomaticDownload = 1;
      # Install System data files & security updates
      CriticalUpdateInstall = 1;
    };

    "com.apple.TimeMachine".DoNotOfferNewDisksForBackup = true;
    # Prevent Photos from opening automatically when devices are plugged in
    "com.apple.ImageCapture".disableHotPlug = true;
    # Turn on app auto-update
    "com.apple.commerce".AutoUpdate = true;
  };

  # Create /etc/zshrc that loads the nix-darwin environment.
  programs.zsh.enable = true;  # default shell on catalina
  # programs.fish.enable = true;

  # Set Git commit hash for darwin-version.
  # system.configurationRevision = self.rev or self.dirtyRev or null;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 4;

  # The platform the configuration will be used on.
  nixpkgs.hostPlatform = "x86_64-darwin";

  # vscode is not free software
  nixpkgs.config.allowUnfree = true;

  users.users.szeth = {
    name = "szeth";
    home = "/Users/szeth";
  };
}