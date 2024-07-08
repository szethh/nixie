{ pkgs, ... }:
{
  enable = true;
  package = pkgs.vscode; # You can choose 'vscode', 'code', or 'codium'

  # obtained with code --list-extensions
  # extensions = pkgs.vscode-utils.extensionsFromVscodeMarketplace 
  #   (import ./extensions.nix).extensions;
  # extensions = [
  #   pkgs.vscode-extensions.analytic-signal.preview-mp4
  # ];
  # extensions = with pkgs.vscode-extensions; [
  #     analytic-signal.preview-mp4
  #     bbenoist.nix
  #     bradlc.vscode-tailwindcss
  #     csstools.postcss
  #     dbaeumer.vscode-eslint
  #     ecmel.vscode-html-css
  #     esbenp.prettier-vscode
  #     george-alisson.html-preview-vscode
  #     james-yu.latex-workshop
  #     jirkavrba.subway-surfers
  #     mgmcdermott.vscode-language-babel
  #     ms-azuretools.vscode-docker
  #     ms-python.black-formatter
  #     ms-python.debugpy
  #     ms-python.python
  #     ms-python.vscode-pylance
  #     ms-toolsai.jupyter
  #     ms-toolsai.jupyter-keymap
  #     ms-toolsai.jupyter-renderers
  #     ms-toolsai.vscode-jupyter-cell-tags
  #     ms-toolsai.vscode-jupyter-slideshow
  #     ms-vscode-remote.remote-containers
  #     ms-vscode-remote.remote-ssh
  #     ms-vscode-remote.remote-ssh-edit
  #     ms-vscode-remote.remote-wsl
  #     ms-vscode.remote-explorer
  #     pkief.material-icon-theme
  #     redhat.ansible
  #     redhat.vscode-yaml
  #     rust-lang.rust-analyzer
  #     scala-lang.scala
  #     selemondev.vscode-shadcn-svelte
  #     skellock.just
  #     supermaven.supermaven
  #     svelte.svelte-vscode
  #     tamasfe.even-better-toml
  #     tomoki1207.pdf
  #     wholroyd.jinja
  # ];

  userSettings = {
    ### APPEARANCE
    "editor.fontSize" = 12;
    "editor.formatOnSave" = true;
    "editor.defaultFormatter" = "esbenp.prettier-vscode";
    "editor.fontFamily" = "'FiraCode Nerd Font', Menlo, Monaco, 'Courier New', monospace";
    
    "workbench.colorTheme" = "Default Dark+";
    "workbench.iconTheme" = "material-icon-theme";
    "workbench.editor.labelFormat" = "short";
    "workbench.editorAssociations" = {
      "*.pdf" = "latex-workshop-pdf-hook";
    };
    "diffEditor.ignoreTrimWhitespace" = false;

    ### MISC
    "explorer.confirmDragAndDrop" = false;
    "explorer.confirmDelete" = false;
    "terminal.integrated.enableMultiLinePasteWarning" = false;
    "update.showReleaseNotes"= false;

    "git.confirmSync" = false;
    "git.autofetch" = true;

    "supermaven.otherWarning" = false;
    "supermaven.enable" = {
      "*" = true;
    };

    ### LANGUAGES

    "prettier.tabWidth" = 4;
    "eslint.validate" = ["javascript" "svelte"];

    "typescript.updateImportsOnFileMove.enabled" = "always";
    "javascript.updateImportsOnFileMove.enabled" = "always";

    "[javascript][typescript][css]" = {
      "editor.defaultFormatter" = "esbenp.prettier-vscode";
      "editor.tabSize" = 2;
      "editor.formatOnSave" = true;
    };
    
    "[svelte]" = {
      "editor.defaultFormatter" = "svelte.svelte-vscode";
      "editor.tabSize" = 2;
      "enable-ts-plugin" = true;
    };
    "[rust]" = {
      "editor.defaultFormatter" = "rust-lang.rust-analyzer";
    };
    "[nix]" = {
      "editor.defaultFormatter" = "brettm12345.nixfmt-vscode";
    };
    "[yaml]" = {
      "editor.defaultFormatter" = "redhat.vscode-yaml";
    };
    "[caddyfile]" = {
        "editor.defaultFormatter" = "matthewpi.caddyfile-support";
    };

    "redhat.telemetry.enabled" = false;
    "files.associations" = {
      "*.j2" = "ansible-jinja";
    };
  };
}
