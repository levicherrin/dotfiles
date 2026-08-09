# Changelog & Capabilities History

## [Unified Cross-Platform Nix Architecture] - 2026-08-09

Integrated cross-platform Nix Flakes and Home Manager architecture supporting WSL2 Debian, native Debian GNU/Linux, and macOS.

### What Was Added & Updated

1. **Declarative Package & System Management**:
   * **`flake.nix`** - Defines unified inputs (nixpkgs, home-manager, nix-darwin, nix-homebrew) and multi-target outputs (`homeConfigurations.linux`, `homeConfigurations.linux-arm`, and `darwinConfigurations.mac`).
   * **`home.nix`** - Universal user blueprint managing CLI tools (`ripgrep`, `fd`, `fzf`, `jq`, `lazygit`, `neovim`, `tree`, `tmux`, `nerd-fonts.hack`), shell aliases, Starship prompt, and live out-of-store symlinks.
   * **`darwin.nix`** - macOS system settings, Dock/Finder defaults, and Homebrew cask declarations.
   * **`bootstrap.sh`** - OS-aware setup script that provisions Determinate Nix and builds the initial environment.
   * **`rebuild.sh`** - Single command switch script to apply configuration updates across Linux and macOS.
   * **`tests/lib.sh` & `tests/validate.sh`** - Automated test suite running static shell syntax checks, symlink integrity validation, code quality checks, and flake evaluations.

---

## [Neovim Integration & Visual Baseline] - 2026-08-09

Absorbed modern Neovim capabilities from Kun's dotfiles with customized Catppuccin Mocha theming.

### What Was Added & Updated

1. **Neovim Configuration Suite (`.config/nvim/`)**:
   * **`init.lua`** - Modular entry point loading config, plugins, and keybindings.
   * **`lua/vim_config.lua`** - Core editor defaults:
     * Persistent undo (`undofile = true`)
     * 2-space indentation (`expandtab = true`, `shiftwidth = 2`)
     * Hybrid line numbers (`number = true`, `relativenumber = true`)
     * Smart case search (`ignorecase = true`, `smartcase = true`)
     * System clipboard sharing (`clipboard = 'unnamedplus'`)
     * Cursor offset padding (`scrolloff = 16`)
   * **`lua/keys.lua`** - Ergonomic shortcuts:
     * `<Esc>` : Quick save buffer (`:w<CR>`)
     * `<C-a>` : Select entire buffer (`ggVG`)
     * Paste over visual selection without clobbering clipboard register
   * **`lua/plugin.lua`** - `lazy.nvim` plugin loader with automatic bootstrapping.
   * **`lua/plugins/colorscheme.lua`** - **Catppuccin Mocha** (`catppuccin/nvim`) with auto-detected terminal transparency across Linux, WSL2, and macOS, plus integrations with `snacks`, `neogit`, `gitsigns`, and `which-key`.
   * **`lua/plugins/navigation.lua`**:
     * `folke/snacks.nvim` for fuzzy file searching (`<leader>f`), live text grep (`<leader>s`), buffer picker (`<leader>b`), and LSP definition jump (`gd`).
     * `stevearc/oil.nvim` to edit the filesystem directly like a Vim buffer (`<leader>e`).
   * **`lua/plugins/git.lua`**:
     * `NeogitOrg/neogit` + `sindrets/diffview.nvim` for interactive git UI (`<leader>g`).
     * `lewis6991/gitsigns.nvim` for inline git diff highlights and current line blame.
   * **`lua/plugins/ui.lua`**:
     * `folke/which-key.nvim` popup guides for keybinding discovery.

2. **Environment & Tooling**:
   * Added `tmux.conf` with `set -g mouse on` (mouse wheel scrolling), 50,000 line history limit, vi mode, and 24-bit color support.
   * Updated `bashrc` to set `export EDITOR="nvim"` and `export VISUAL="nvim"`.
   * Updated `install.sh` to symlink `~/.tmux.conf`, `~/.config/nvim`, and auto-reload active tmux sessions.
   * Updated `README.md` with complete documentation, keymaps, and linking steps.
