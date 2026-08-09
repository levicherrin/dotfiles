# Levi's dotfiles

Cross-platform declarative environment configuration for WSL2 Debian, native Debian GNU/Linux, and macOS, powered by Nix, Home Manager, and nix-darwin.

## Quick Start

### Automated Setup (Nix & Home Manager)

Clone the repository and run the bootstrap script:

```bash
git clone https://github.com/levicherrin/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./bootstrap.sh
```

`bootstrap.sh` performs the following steps:
1. Installs Determinate Nix if not already present.
2. Symlinks the repository to `~/.dotfiles`.
3. Verifies and personalizes the configured username in `flake.nix`.
4. Runs the initial build (`home-manager switch` on Linux/WSL2, or `darwin-rebuild switch` on macOS).

### Daily Workflow

To apply configuration edits:

```bash
./rebuild.sh
```

---

## Repository Structure

| File / Directory | Description |
| :---- | :---- |
| `flake.nix` | Flake entry point declaring Linux and macOS configurations |
| `home.nix` | Universal user environment (CLI tools, Starship prompt, shell, symlinks) |
| `darwin.nix` | macOS system defaults, Dock/Finder settings, and Homebrew integration |
| `bootstrap.sh` | Automated bootstrap script for fresh machines |
| `rebuild.sh` | Script to apply configuration changes |
| `tmux.conf` | Terminal multiplexer configuration (mouse scrolling, 50k buffer, vi mode) |
| `.config/nvim/` | Modular Neovim configuration (Catppuccin Mocha, snacks.nvim, oil.nvim, neogit) |
| `.config/wezterm/` | Cross-platform WezTerm configuration (Catppuccin Mocha, focus dimming, WSL auto-launch) |
| `tests/` | Automated test suite (`lib.sh`, `validate.sh`) |
| `bashrc` | Standalone shell configuration |
| `bash_aliases` | Standalone shell shortcuts and utilities |
| `install.sh` | Legacy symlinking setup script for non-Nix environments |

---

## WezTerm Configuration

Located in `.config/wezterm/wezterm.lua`:

* **Theme & Typography**: Catppuccin Mocha color scheme with Hack Nerd Font at 15.0pt.
* **Focus Dimming**: Active window renders at 80% opacity, while unfocused windows automatically dim to 62% opacity with reduced text saturation.
* **Window Ergonomics**: Single tab auto-hide and minimal resizable borders.
* **Cross-Platform Auto-Launch**: On Windows hosts, automatically selects the `WSL:Debian` domain, defaults to `$HOME` (`~`), and enables Windows Acrylic blur. On macOS, enables native glassmorphism blur.

### Windows Host Setup (One-Time Operator Setup)

When running WezTerm on a Windows host accessing WSL2, perform the following one-time configuration steps from Windows PowerShell:

#### 1. Live Configuration Symbolic Link

```powershell
# Remove any static copies
Remove-Item "$HOME\.config\wezterm\wezterm.lua" -Force -ErrorAction SilentlyContinue
Remove-Item "$HOME\.wezterm.lua" -Force -ErrorAction SilentlyContinue

# Create directory and live symbolic link to repository in WSL
New-Item -ItemType Directory -Path "$HOME\.config\wezterm" -Force
New-Item -ItemType SymbolicLink -Path "$HOME\.config\wezterm\wezterm.lua" -Target "\\wsl.localhost\Debian\home\levi\repos\dotfiles\.config\wezterm\wezterm.lua" -Force
```

#### 2. Hack Nerd Font Installation & Registration

```powershell
# Download and extract Hack Nerd Font
Invoke-WebRequest -Uri "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Hack.zip" -OutFile "$env:TEMP\Hack.zip"
Expand-Archive "$env:TEMP\Hack.zip" -DestinationPath "$env:TEMP\Hack" -Force

# Copy TTF files to Windows user font directory
New-Item -ItemType Directory -Path "$env:LOCALAPPDATA\Microsoft\Windows\Fonts" -Force
Copy-Item "$env:TEMP\Hack\*.ttf" "$env:LOCALAPPDATA\Microsoft\Windows\Fonts\" -Force
Remove-Item "$env:TEMP\Hack.zip", "$env:TEMP\Hack" -Recurse -Force

# Register font files in Windows registry
$fonts = Get-ChildItem "$env:LOCALAPPDATA\Microsoft\Windows\Fonts\Hack*.ttf"
$regPath = "HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts"
foreach ($f in $fonts) { New-ItemProperty -Path $regPath -Name $f.Name -Value $f.FullName -PropertyType String -Force }
```




---

## Testing & Validation

Run the automated validation suite to verify script syntax, symlink targets, and code quality before applying changes:

```bash
./tests/validate.sh
```


---

## Neovim Configuration

A fast, modern Neovim setup managed by `lazy.nvim` and styled in **Catppuccin Mocha** with auto-detected terminal transparency:

* **Theme**: Catppuccin Mocha (`catppuccin/nvim`) with full plugin integrations
* **File Manager**: `oil.nvim` (`<leader>e`) to edit the filesystem like a regular buffer
* **Fuzzy Finder & Grep**: `snacks.nvim`
  * `<leader>f` : Find files (uses `fd`)
  * `<leader>s` : Live grep text (uses `ripgrep`)
  * `<leader>b` : Open buffers
  * `gd` : Go to LSP definition
* **Git Workflows**:
  * `<leader>g` : Open `neogit` + `diffview.nvim`
  * `gitsigns.nvim` : Inline git diffs with current line blame
* **Leader & Shortcuts**:
  * `<Space>` is the leader key (with `which-key.nvim` popup guides)
  * `<Esc>` : Quick save (`:w<CR>`)
  * `<C-a>` : Select all buffer content
  * Smart paste without clobbering the register

---

## Included Shortcuts and Highlights

### File Listing and Navigation

* `ll` : Detailed list view (`ls -al --color=auto`)
* `lt` : Sort files by last modified date (newest at bottom)
* `lh` : Human-readable file sizes (KB, MB, GB)
* `..` / `...` / `....` : Fast parent directory traversal

### Git Shortcuts

* `gs` : `git status`
* `ga` / `gaa` : `git add` / `git add --all`
* `add` : `git add .`
* `gc` : `git commit -m`
* `gp` / `gl` : `git push` / `git pull`
* `m` : `git switch main`
* `glog` : Visual one-line Git log graph

### System and Network

* `ports` : Show listening system ports (`sudo ss -tulpn`)
* `path` : Print PATH variable on separate lines for readability
* `myip` : Fetch public IP address via ipinfo.io
* `reload` : Reload `~/.bashrc` instantly
