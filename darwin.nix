{ lib, pkgs, user, ... }:

{
  # Determinate manages the Nix daemon
  nix.enable = false;

  nixpkgs.config.allowUnfree = true;
  nixpkgs.hostPlatform = "aarch64-darwin";

  # Enable modern Bash managed by nix-darwin in /etc/shells
  programs.bash.enable = true;
  environment.shells = [ pkgs.bashInteractive ];

  # nix-darwin's /etc/bashrc and /etc/zshrc rebuild PATH from scratch, dropping
  # the /opt/homebrew/bin entry macOS adds via /etc/paths.d. Re-add Homebrew
  # after the Nix profiles (default order) and before the macOS system paths
  # (order 1200): Nix-declared tools win, Homebrew fills gaps, and Homebrew
  # still shadows stale /usr/bin copies such as python3. Nonexistent entries
  # are harmless on Macs without Homebrew.
  environment.systemPath = lib.mkOrder 1100 [ "/opt/homebrew/bin" "/opt/homebrew/sbin" ];

  # Install GUI applications and system tools directly via Nix
  environment.systemPackages = [
    pkgs.wezterm
    pkgs.bashInteractive
  ];

  system.primaryUser = user;
  users.users.${user} = {
    home = "/Users/${user}";
    shell = pkgs.bashInteractive;
  };
  system.stateVersion = 6;
  system.defaults = {
    NSGlobalDomain = {
      AppleInterfaceStyle = "Dark";
      KeyRepeat = 2;          # Fast key repeat
      InitialKeyRepeat = 15;  # Short delay before repeat
      _HIHideMenuBar = true;  # Auto-hide the menu bar
      AppleShowAllExtensions = true;
    };
    dock.autohide = true;
    finder.FXPreferredViewStyle = "Nlsv";  # List view by default
    finder.CreateDesktop = false;          # Clean desktop
    trackpad.Clicking = true;              # Tap to click
  };
}
