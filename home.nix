{ config, pkgs, user, isDarwin ? false, ... }:

let
  dotfiles = "${config.home.homeDirectory}/.dotfiles";
in
{
  home.username = user;
  home.homeDirectory = if isDarwin then "/Users/${user}" else "/home/${user}";
  home.stateVersion = "24.11";

  # Essential User Packages

  home.packages = with pkgs; [
    ripgrep          # Fast search (rg)
    fd               # Fast find (fd)
    fzf              # Fuzzy finder
    jq               # JSON command line tool
    lazygit          # Git TUI
    neovim           # Modern Lua-based editor
    tree             # Directory tree visualizer
    tmux             # Terminal multiplexer
    nerd-fonts.hack  # Terminal icon glyphs
  ];

  fonts.fontconfig.enable = true;
  home.sessionVariables.EDITOR = "nvim";
  home.sessionVariables.VISUAL = "nvim";

  # Enable Home Manager CLI management
  programs.home-manager.enable = true;

  # Bash Shell Configuration

  programs.bash = {
    enable = true;
    enableCompletion = true;
    historyControl = [ "ignoreboth" ];
    historySize = 10000;
    historyFileSize = 20000;
    shellAliases = {
      # File Listing & Navigation
      ".." = "cd ..";
      "..." = "cd ../..";
      "...." = "cd ../../..";
      "....." = "cd ../../../..";
      "-" = "cd -";
      ll = "ls -al --color=auto";

      lt = "ls -lha -rt --color=auto";
      lh = "ls -lh --color=auto";
      tree = "tree -C";

      # Git Shortcuts
      gs = "git status";
      ga = "git add";
      gaa = "git add --all";
      add = "git add .";
      gc = "git commit -m";
      gp = "git push";
      gl = "git pull";
      m = "git switch main";
      glog = "git log --oneline --graph --decorate --all";

      # System & Network
      ports = "sudo ss -tulpn";
      path = "echo -e \${PATH//:/\\\\n}";
      myip = "curl -s ipinfo.io; echo";
      c = "clear";
      reload = "source ~/.bashrc";
    };
    initExtra = ''
      # Automatically switch from Windows user folder to Linux $HOME on shell start
      if [[ "$PWD" == /mnt/c/Users/* ]]; then
          cd ~
      fi

      # WSL clipboard & explorer integration
      if grep -qi microsoft /proc/version 2>/dev/null || [ -n "$WSL_DISTRO_NAME" ]; then
          alias open='explorer.exe'
          alias pbcopy='clip.exe'
          alias pbpaste='powershell.exe -command Get-Clipboard'
      fi

      export PATH="$HOME/.local/bin:$PATH"
    '';
  };

  # Starship Prompt (Styled with Catppuccin Mocha accents)
  programs.starship = {
    enable = true;
    enableBashIntegration = true;
    settings = {
      add_newline = false;
      format = "$directory$git_branch$git_status$cmd_duration$line_break$character";
      character = {
        success_symbol = "[❯](bold #cba6f7)"; # Catppuccin Mauve
        error_symbol = "[❯](bold #f38ba8)";   # Catppuccin Red
      };
      directory = {
        style = "bold #89b4fa"; # Catppuccin Blue
      };
      git_branch = {
        format = "[$branch]($style) ";
        style = "bold #fab387"; # Catppuccin Peach
      };
      git_status = {
        format = "([\\[$all_status$ahead_behind\\]]($style) )";
        style = "bold #f9e2af"; # Catppuccin Yellow
      };
      cmd_duration = {
        format = "[$duration]($style) ";
        style = "italic #a6adc8";
      };
    };
  };

  # Live Edit-in-Place Symlinks
  home.file.".config/nvim".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/.config/nvim";

  home.file.".tmux.conf".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/tmux.conf";
}
