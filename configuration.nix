# /etc/nixos/configuration.nix
{ config, pkgs, lib, inputs, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  # Bootloader & System Basics
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.initrd.luks.devices."luks-8e49ba55-1183-47f4-86af-d1a814d1ef3c".device = "/dev/disk/by-uuid/8e49ba55-1183-47f4-86af-d1a814d1ef3c"; # Your LUKS config

  networking.hostName = "nixos"; # Should match key in nixosConfigurations in flake.nix
  networking.networkmanager.enable = true;
  programs.nm-applet.enable = true; # NetworkManager tray icon

  time.timeZone = "Europe/Stockholm";
  i18n.defaultLocale = "sv_SE.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "sv_SE.UTF-8"; LC_IDENTIFICATION = "sv_SE.UTF-8";
    LC_MEASUREMENT = "sv_SE.UTF-8"; LC_MONETARY = "sv_SE.UTF-8";
    LC_NAME = "sv_SE.UTF-8"; LC_NUMERIC = "sv_SE.UTF-8";
    LC_PAPER = "sv_SE.UTF-8"; LC_TELEPHONE = "sv_SE.UTF-8";
    LC_TIME = "sv_SE.UTF-8";
  };

  # Graphics, Desktop Environment (LXQt)
  services.xserver.enable = true;
  services.xserver.displayManager.lightdm.enable = true;
  services.xserver.desktopManager.lxqt.enable = true;
  services.xserver.xkb = { layout = "se"; variant = ""; };
  console.keyMap = "sv-latin1";

  # Sound
  security.rtkit.enable = true;
  services.pipewire = { enable = true; alsa.enable = true; alsa.support32Bit = true; pulse.enable = true; };
  services.pulseaudio.enable = false;

  # Nix Settings
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nixpkgs.config.allowUnfree = true;

  # Automated Garbage Collection
  nix.gc = {
    automatic = true;
    persistent = true; # Recommended for Nix 2.4+
    options = "--delete-older-than 30d";
    dates = "weekly";
  };
  boot.loader.systemd-boot.configurationLimit = 10;

  # --- SYSTEM-WIDE ZSH ENABLEMENT ---
  programs.zsh.enable = true; # Ensures Zsh is a valid system shell

  # --- User Account Definition ---
  users.users.blfnix = {
    isNormalUser = true;
    description = "Bengt Frost";
    extraGroups = [ "networkmanager" "wheel" ];
    shell = pkgs.zsh; # Zsh as default shell for blfnix
    packages = [ ];   # User packages are managed by Home Manager
  };

  # --- System-Wide Applications & Settings ---
  programs.firefox.enable = true; # CORRECTLY RE-ADDED

  environment.systemPackages = with pkgs; [
    wget          # Essential CLI utility
    gitMinimal    # Minimal git for system use
    fontconfig    # Font management backend
    # LXQt and its core components (like qterminal) are managed by services.xserver.desktopManager.lxqt.enable
  ];

  fonts.packages = with pkgs; [ nerd-fonts.cousine ];

  # System Services
  programs.gnupg.agent.enable = true;
  services.printing.enable = true;
  services.avahi = { enable = true; nssmdns4 = true; openFirewall = true; };

  # Minimal System-Wide Environment Variables
  environment.sessionVariables = {
    # PAGER = "less"; # Most user-specific vars go into home.sessionVariables
  };

  system.stateVersion = "25.05"; # CRITICAL
}
