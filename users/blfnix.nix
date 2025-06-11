# /etc/nixos/users/blfnix.nix
{ pkgs, config, lib, inputs, ... }:

{
  home.username = "blfnix";
  home.homeDirectory = "/home/blfnix";
  home.stateVersion = "25.05";

  home.packages = with pkgs; [
    # === Desktop Environment & General Utilities ===
    openbox
    (lxqt.qterminal)
    p7zip
    gnupg
    pinentry-tty
    curl
    file
    tree
    sqlite
    xdg-utils
    mpv
    ffmpeg
    audacious
    qbittorrent
    gimp3
    libreoffice
    simple-scan
    xorg.xev

    # === Helix Editor ===
    helix

    # === Core Development Toolchains ===
    rustup # For rustc, cargo, rust-analyzer, rustfmt
    python313
    uv
    nodejs_24 # Provides node, npm (runtime for many LSPs/tools)
    zig
    zls # LSP for system's stable Zig
    zsh-autocomplete

    # === Build Tools ===
    cmake
    ninja
    llvmPackages_20.clang
    llvmPackages_20.llvm
    llvmPackages_20.lld
    llvmPackages_20.clang-tools # Provides clangd, clang-format
    llvmPackages_20.lldb # LLDB Debugger

    # === LSPs & Formatters for Helix (and general use) ===
    # (Ensure these align with your Helix languages.toml)
    marksman # Markdown LSP
    ruff # Python: 'ruff server' (LSP) & formatter
    python313Packages.python-lsp-server # 'pylsp' (alternative Python LSP)
    nodePackages.typescript-language-server # 'typescript-language-server' for TS/JS
    nodePackages.vscode-json-languageserver # 'json-language-server' for JSON
    nodePackages.yaml-language-server # 'yaml-language-server' for YAML
    taplo # TOML: 'taplo lsp stdio' (LSP) & 'taplo format' (formatter)
    bash-language-server
    nil # Nix Language Server
    # rust-analyzer is installed via `rustup component add rust-analyzer`
    # zls is already listed with zig toolchain
    # clangd is from llvmPackages_20.clang-tools

    # Formatters (some overlap with LSPs)
    dprint # General purpose formatter (used by Helix for several languages)
    # stylua # Lua formatter
    shfmt # Shell script formatter
    nixpkgs-fmt # For formatting Nix files
    python313Packages.black # If Helix config uses it as an alternative to ruff for Python

    # === Tools for Neovim Plugins (Commented out as Helix is primary) ===
    # unzip
    # tree-sitter # Helix has its own tree-sitter integration
    # lua-language-server # Not needed if not configuring Neovim

    # === Other CLI Tools & Applications ===
    tmux
    pass
    keychain
    git
    gh
    fd
    ripgrep
    bat
    jq
    xclip
    yazi
    ueberzugpp
    unar
    ffmpegthumbnailer
    poppler_utils
    w3m
    zathura

    # === AI Tools ===
    aider-chat
    litellm
  ];

  # --- ZSH CONFIGURATION ---
  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    plugins = [{ name = "zsh-autocomplete"; src = pkgs.zsh-autocomplete; }];
    shellAliases = {
      ls = "ls --color=auto -F";
      ll = "ls -alhF";
      la = "ls -AF";
      l = "ls -CF";
      glog = "git log --oneline --graph --decorate --all";
      nix-update-system = "sudo nixos-rebuild switch --flake ~/Utveckling/NixOS#nixos"; # Your Flake path
      cc = "clang";
      cxx = "clang++";
    };
    history = {
      size = 10000;
      path = "${config.xdg.dataHome}/zsh/history";
      share = true;
      ignoreDups = true;
      ignoreSpace = true;
      save = 10000;
    };
    initContent = ''
      bindkey -v # Enable Vi Keybindings

      export PATH="$HOME/.cargo/bin:$PATH"
      export PATH="$HOME/.local/bin:$PATH"
      export PATH="$HOME/.npm-global/bin:$PATH"

      export KEYTIMEOUT=150

      # Custom Functions (ensure these are fully defined from your working config)
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

  # --- APPLICATION CONFIGURATIONS ---
  programs.starship = {
    enable = true;
    settings = {
      add_newline = false;
      directory = { truncation_length = 3; truncation_symbol = "…/"; };
    };
  };

  # programs.helix.enable = true; # This HM module is for basic settings;
  # we use xdg.configFile for full control.

  programs.keychain = { enable = true; agents = [ "ssh" ]; keys = [ "id_ecdsa" ]; };

  programs.git = {
    enable = true;
    userName = "Bengt Frost";
    userEmail = "bengtfrost@gmail.com";
    extraConfig = { core.editor = "hx"; init.defaultBranch = "main"; }; # Editor changed to hx
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    defaultCommand = "fd --type f --hidden --follow --exclude .git";
    defaultOptions = [ "--height 40%" "--layout=reverse" "--border" "--prompt='➜  '" ];
  };

  programs.zathura = {
    enable = true;
    options = {
      selection-clipboard = "clipboard";
      adjust-open = "best-fit";
      default-bg = "#212121";
      default-fg = "#303030";
      statusbar-fg = "#B2CCD6";
      statusbar-bg = "#353535";
      inputbar-bg = "#212121";
      inputbar-fg = "#FFFFFF";
      notification-bg = "#212121";
      notification-fg = "#FFFFFF";
      notification-error-bg = "#212121";
      notification-error-fg = "#F07178";
      notification-warning-bg = "#212121";
      notification-warning-fg = "#F07178";
      highlight-color = "#FFCB6B";
      highlight-active-color = "#82AAFF";
      completion-bg = "#303030";
      completion-fg = "#82AAFF";
      completion-highlight-fg = "#FFFFFF";
      completion-highlight-bg = "#82AAFF";
      recolor-lightcolor = "#212121";
      recolor-darkcolor = "#EEFFFF";
      recolor = false;
      recolor-keephue = false;
    };
  };

  # --- Alacritty Configuration ---
  programs.alacritty = {
    enable = true;
    settings = {
      env.TERM = "alacritty";

      window = {
        # Set initial window dimensions (columns x lines)
        dimensions = { columns = 83; lines = 25; }; # ADDED/MODIFIED

        padding = { x = 0; y = 0; };
        dynamic_title = true;
        # decorations = "full"; # Keep as "full" for XFCE to draw decorations
      };

      scrolling.history = 10000;

      font = {
        normal = { family = "Cousine Nerd Font Mono"; style = "Regular"; };
        bold = { family = "Cousine Nerd Font Mono"; style = "Bold"; };
        italic = { family = "Cousine Nerd Font Mono"; style = "Italic"; };
        bold_italic = { family = "Cousine Nerd Font Mono"; style = "Bold Italic"; };
        size = 9.0; # Or the size that worked best for you
      };

      cursor = {
        style = { shape = "Block"; blinking = "Off"; };
      };

      colors = {
        primary = { background = "0x242424"; foreground = "0xdedede"; };
        cursor = { text = "CellBackground"; cursor = "0xf0f0f0"; };
        normal = {
          black = "0x1e1e1e";
          red = "0xc01c28";
          green = "0x26a269";
          yellow = "0xa2734c";
          blue = "0x12488b";
          magenta = "0xa347ba";
          cyan = "0x258f8f";
          white = "0xa0a0a0";
        };
        bright = {
          black = "0x4d4d4d";
          red = "0xf66151";
          green = "0x33d17a";
          yellow = "0xf8e45c";
          blue = "0x3584e4";
          magenta = "0xc061cb";
          cyan = "0x33c7de";
          white = "0xf0f0f0";
        };
      };

      bell = {
        animation = "EaseOutExpo";
        duration = 100;
      };

      mouse.hide_when_typing = true;

      # Shell
      # shell = { program = "${pkgs.zsh}/bin/zsh", args = ["-l"] };
    };
  };

  # --- NEOVIM CONFIGURATION (Commented out) ---
  # xdg.configFile."nvim" = {
  #   source = ../dotfiles/nvim;
  #   recursive = true;
  # };

  # --- OPENBOX CONFIGURATION ---
  xdg.configFile."openbox/rc.xml" = {
    source = ../dotfiles/openbox/rc.xml;
  };

  # --- HELIX CONFIGURATION (via dotfiles) ---
  # This ensures Home Manager places your custom Helix configuration files.
  # Assumes these files exist in your Flake structure, e.g.,
  # ~/Utveckling/NixOS/dotfiles/helix/languages.toml
  # ~/Utveckling/NixOS/dotfiles/helix/config.toml
  xdg.configFile."helix/languages.toml" = {
    source = ../dotfiles/helix/languages.toml; # Your languages.toml from earlier
  };
  xdg.configFile."helix/config.toml" = {
    # Create this file in your dotfiles directory with your desired Helix settings
    # Example content:
    # text = ''
    #   theme = "adwaita-dark" # Example: if an Adwaita-Dark theme for Helix exists
    #                          # Or any other theme you like, e.g., "catppuccin_mocha_helix"
    #                          # Ensure the theme is compatible/available.
    #   [editor]
    #   line-number = "relative"
    #   mouse = false
    #   # shell = ["zsh", "-l"] # If Helix needs to pick up login shell env
    #
    #   [editor.lsp]
    #   display-messages = true
    # '';
    # For a real config, better to use `source`:
    source = ../dotfiles/helix/config.toml; # Create this file
  };

  # --- GLOBAL USER ENVIRONMENT VARIABLES ---
  home.sessionVariables = {
    EDITOR = "hx"; # Changed to hx
    VISUAL = "hx"; # Changed to hx
    PAGER = "less";
    CC = "clang";
    CXX = "clang++";
    GIT_TERMINAL_PROMPT = "1";
    FZF_ALT_C_COMMAND = "fd --type d --hidden --follow --exclude .git";
  };
}
