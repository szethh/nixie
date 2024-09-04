{ config, pkgs, ... }:
let
  borgmaticRunScript = pkgs.writeScriptBin "borgmatic-run" ''
    #!/bin/bash

    LOCKFILE="/tmp/borgmatic.lock"

    # Check if lock file exists and if the process is still running
    if [ -f "$LOCKFILE" ]; then
      PID=$(cat "$LOCKFILE")
      if ps -p $PID > /dev/null 2>&1; then
        echo "A previous instance of borgmatic is still running."
        exit 1
      else
        echo "Stale lock file found. Removing it."
        rm -f "$LOCKFILE"
      fi
    fi

    # Create a lock file with the current PID
    echo $$ > "$LOCKFILE"

    # Run borgmatic
    ${pkgs.borgmatic}/bin/borgmatic -v 1 $@

    # Remove the lock file after the process completes
    rm -f "$LOCKFILE"
  '';
in
{
  environment.systemPackages = with pkgs; [ borgmaticRunScript ];

  environment.launchDaemons."org.torsion.borgmatic.plist" = {
    enable = true;
    text = ''
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
      <plist version="1.0">
        <dict>
          <key>Label</key>
          <string>org.torsion.borgmatic</string>

          <key>ProgramArguments</key>
          <array>
                  <string>${borgmaticRunScript}/bin/borgmatic-run</string>
          </array>

          <key>StandardOutPath</key>
          <string>/tmp/borgmatic.log</string>

          <key>StandardErrorPath</key>
          <string>/tmp/borgmatic.err</string>

          <key>StartInterval</key>
          <integer>3600</integer>

          <key>UserName</key>
          <string>${config.users.users.szeth.name}</string>

          <key>RunAtLoad</key>
          <true/>
        </dict>
      </plist>
    '';
  };
}
