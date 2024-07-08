{ pkgs, ... }:
{
  programs.vscode = {
    enable = true;
    package = pkgs.vscode; # You can choose 'vscode', 'code', or 'codium'

    # obtained with code --list-extensions
    extensions = with pkgs.vscode-extensions; [
        analytic-signal.preview-mp4
        bbenoist.nix
        bradlc.vscode-tailwindcss
        csstools.postcss
        dbaeumer.vscode-eslint
        ecmel.vscode-html-css
        esbenp.prettier-vscode
        george-alisson.html-preview-vscode
        james-yu.latex-workshop
        jirkavrba.subway-surfers
        mgmcdermott.vscode-language-babel
        ms-azuretools.vscode-docker
        ms-python.black-formatter
        ms-python.debugpy
        ms-python.python
        ms-python.vscode-pylance
        ms-toolsai.jupyter
        ms-toolsai.jupyter-keymap
        ms-toolsai.jupyter-renderers
        ms-toolsai.vscode-jupyter-cell-tags
        ms-toolsai.vscode-jupyter-slideshow
        ms-vscode-remote.remote-containers
        ms-vscode-remote.remote-ssh
        ms-vscode-remote.remote-ssh-edit
        ms-vscode-remote.remote-wsl
        ms-vscode.remote-explorer
        pkief.material-icon-theme
        redhat.ansible
        redhat.vscode-yaml
        rust-lang.rust-analyzer
        scala-lang.scala
        selemondev.vscode-shadcn-svelte
        skellock.just
        supermaven.supermaven
        svelte.svelte-vscode
        tamasfe.even-better-toml
        tomoki1207.pdf
        wholroyd.jinja
    ];
  };

}
