# /etc/nixos/users/blfnix.nix
{ pkgs, config, lib, inputs, ... }:

{
  home.username = "blfnix";
  home.homeDirectory = "/home/blfnix";
  home.stateVersion = "25.05";

  home.packages = with pkgs; [
    # Desktop Environment specific tools (LXQt's qterminal is usually part of lxqt full)
    # If qterminal isn't available after LXQt install, add `(lxqt.qterminal)` here.
    openbox # Good to have explicitly for clarity, though LXQt provides it
    (lxqt.qterminal) # Ensure qterminal is available

    p7zip gnupg pinentry-tty curl file tree sqlite xdg-utils mpv    
    ffmpeg audacious qbittorrent gimp3 libreoffice simple-scan xorg.xev

    # Dev Toolchains
    rustup python313 uv nodejs_24 zig zls zsh-autocomplete
    # Build Tools
    cmake ninja llvmPackages_20.clang llvmPackages_20.llvm llvmPackages_20.lld llvmPackages_20.clang-tools
    # Editors & LSPs
    helix marksman ruff python313Packages.python-lsp-server
    nodePackages.typescript-language-server nodePackages.vscode-json-languageserver
    nodePackages.yaml-language-server dprint taplo
    # CLI Tools
    tmux pass keychain git gh fd ripgrep bat jq xclip yazi
    ueberzugpp unar ffmpegthumbnailer poppler_utils w3m zathura
    # AI Tools
    aider-chat litellm
  ];

    # --- MANAGING OPENBOX CONFIGURATION (rc.xml) DIRECTLY ---
  # This approach gives you full control over the rc.xml content.
  # Home Manager will place this file at ~/.config/openbox/rc.xml
  xdg.configFile."openbox/rc.xml" = {
    source = ../dotfiles/openbox/rc.xml; # Adjust path as needed
  };
    
  programs.zsh = {
    enable = true; # Enable Zsh management by Home Manager for this user
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    # keyMap = "vi"; # Using bindkey -v as it was more reliable for you

    plugins = [ # For zsh-autocomplete
      { name = "zsh-autocomplete"; src = pkgs.zsh-autocomplete; }
    ];

    shellAliases = {
      ls = "ls --color=auto -F"; ll = "ls -alhF"; la = "ls -AF"; l  = "ls -CF";
      glog = "git log --oneline --graph --decorate --all";
      nix-update-system = "sudo nixos-rebuild switch --flake ~/Utveckling/NixOS/#nixos"; # Adjust path/hostname
      cc = "clang"; cxx = "clang++";
    };
    history = {
      size = 10000; path = "${config.xdg.dataHome}/zsh/history";
      share = true; ignoreDups = true; ignoreSpace = true; save = 10000;
    };
    initContent = ''
      bindkey -v # Enable Vi Keybindings

      # PATH Exports
      export PATH="$HOME/.cargo/bin:$PATH"
      export PATH="$HOME/.local/bin:$PATH"
      export PATH="$HOME/.npm-global/bin:$PATH"

      export KEYTIMEOUT=150

      # History search keybindings (Commented out for zsh-autocomplete)
      # autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
      # zle -N up-line-or-beginning-search; zle -N down-line-or-beginning-search
      # bindkey "^[[A" up-line-or-beginning-search; bindkey "^[[B" down-line-or-beginning-search

      # Custom Functions
      multipull() {
        local BASE_DIR=~/.code
        if [[ ! -d "$BASE_DIR" ]]; then echo "multipull: Base dir $BASE_DIR not found" >&2; return 1; fi
        echo "Searching Git repos under $BASE_DIR..."
        fd --hidden --no-ignore --type d '^\.git$' "$BASE_DIR" | while read -r gitdir; do
          local workdir=$(dirname "$gitdir")
          echo -e "\n=== Updating $workdir ==="
          if (cd "$workdir" && git rev-parse --abbrev-ref --symbolic-full-name '@{u}' &>/dev/null); then
            git -C "$workdir" pull
          else
            local branch=$(git -C "$workdir" rev-parse --abbrev-ref HEAD)
            echo "--- Skipping pull (no upstream for branch: $branch) ---"
          fi
        done
        echo -e "\nMultipull finished."
      }
      _activate_venv() {
        local venv_name="$1"; local venv_activate_path="$2"
        if [[ ! -f "$venv_activate_path" ]]; then echo "Error: Venv script $venv_activate_path not found" >&2; return 1; fi
        if (( $+commands[deactivate] )) && [[ "$(type -t deactivate)" != "builtin" ]]; then deactivate; fi
        . "$venv_activate_path" && echo "Activated venv: $venv_name"
      }
      v_mlmenv() { _activate_venv "mlmenv (Python 3.13)" "$HOME/.venv/python3.13/mlmenv/bin/activate"; }
      v_crawl4ai() { _activate_venv "crawl4ai (Python 3.13)" "$HOME/.venv/python3.13/crawl4ai/bin/activate"; }
    '';
  };

  # programs.starship.enable = true;
  programs.starship = {
    enable = true;
    # Add your custom Starship settings here
    settings = {
      add_newline = false; # Don't print a new line at the start of the prompt
      directory = {
        truncation_length = 3;
        truncation_symbol = "…/";
      };
      # Add other starship settings if you have them, for example:
      # character = {
      #   success_symbol = "[➜](bold green)";
      #   error_symbol = "[✗](bold red)";
      # };
    };
  };

  programs.helix.enable = true;

  programs.keychain = {
    enable = true;        # Enable keychain management
    agents = [ "ssh" ];   # We want it to manage ssh-agent
    keys = [ "id_ecdsa" ]; # List of private key *filenames* in ~/.ssh/ to add automatically
                           # It will prompt for passphrases on first add after agent starts.
    # Optional settings:
    # evalInit = true; # This is usually default and ensures it sets up the env vars for the shell.
    # quiet = true;
    # clear = true; # If you want to clear identities on startup (usually not needed)
    # extraFlags = [ "--noask" ]; # Example: if keys have no passphrase, though usually you want the prompt.
  };

  programs.git = {
    enable = true; userName = "Bengt Frost"; userEmail = "bengtfrost@gmail.com";
    extraConfig = { core.editor = "hx"; init.defaultBranch = "main"; };
  };

  programs.fzf = {
    enable = true; enableZshIntegration = true;
    defaultCommand = "fd --type f --hidden --follow --exclude .git";
    defaultOptions = [ "--height 40%" "--layout=reverse" "--border" "--prompt='➜  '" ];
  };

  programs.zathura = {
    enable = true;
    options = {
      selection-clipboard = "clipboard"; adjust-open = "best-fit"; default-bg = "#212121";
      default-fg = "#303030"; statusbar-fg = "#B2CCD6"; statusbar-bg = "#353535";
      inputbar-bg = "#212121"; inputbar-fg = "#FFFFFF"; notification-bg = "#212121";
      notification-fg = "#FFFFFF"; notification-error-bg = "#212121";
      notification-error-fg = "#F07178"; notification-warning-bg = "#212121";
      notification-warning-fg = "#F07178"; highlight-color = "#FFCB6B";
      highlight-active-color = "#82AAFF"; completion-bg = "#303030";
      completion-fg = "#82AAFF"; completion-highlight-fg = "#FFFFFF";
      completion-highlight-bg = "#82AAFF"; recolor-lightcolor = "#212121";
      recolor-darkcolor = "#EEFFFF"; recolor = false; recolor-keephue = false;
    };
  };

  # Manage Helix config files (ensure paths are correct relative to this file's location in the Flake)
  # Assuming blfnix.nix is in /etc/nixos/users/ and dotfiles are in /etc/nixos/dotfiles/
  xdg.configFile."helix/languages.toml".source = ../dotfiles/helix/languages.toml;
  # xdg.configFile."helix/config.toml".source = ../dotfiles/helix/config.toml;

  home.sessionVariables = {
    EDITOR = "hx"; VISUAL = "hx"; PAGER = "less";
    CC = "clang"; CXX = "clang++"; GIT_TERMINAL_PROMPT = "1";
    FZF_ALT_C_COMMAND = "fd --type d --hidden --follow --exclude .git";
  };
}
