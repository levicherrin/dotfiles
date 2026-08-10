# Levi's dotfiles

Cross-platform declarative environment configuration for WSL2 Debian, native Debian GNU/Linux, and macOS, powered by Nix, Home Manager, and nix-darwin.

---

## Quick Start by Platform

### 1. macOS Setup (Apple Silicon M-Series & Intel)

On a fresh, out-of-the-box Mac:

#### Step 1: Install Apple Command Line Tools (Provides Git)
Open the stock Terminal app and run:
```bash
xcode-select --install
```
*(Click "Install" in the pop-up window and wait for completion).*

#### Step 2: Set Default Shell to Bash
macOS defaults to zsh. To set Bash as your default login shell:
```bash
chsh -s /bin/bash
```

#### Step 3: Clone & Bootstrap
```bash
git clone https://github.com/levicherrin/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
bash bootstrap.sh
```

**What `bootstrap.sh` provisions automatically on macOS:**
* **Determinate Nix**: Installs the Nix package manager daemon.
* **Nix-Darwin**: Applies macOS system defaults (Dark mode, auto-hide dock, fast key repeat, tap-to-click).
* **Declarative Homebrew**: Bootstraps Homebrew and installs the **WezTerm** application into `/Applications/WezTerm.app`.
* **CLI Suite via Nix**: Installs `neovim`, `tmux`, `ripgrep`, `fd`, `fzf`, `jq`, `lazygit`, `tree`, and `nerd-fonts.hack`.
* **Shell & Prompt**: Configures Bash, Starship prompt, and live symlinks (`~/.config/nvim`, `~/.config/wezterm`, `~/.tmux.conf`).

---

### 2. Windows 11 & WSL2 Setup

#### Step 1: Bootstrap Linux Environment (Inside WSL2 Debian)
```bash
git clone https://github.com/levicherrin/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
bash bootstrap.sh
```

#### Step 2: Windows Host Setup (One-Time in Windows PowerShell)
Run these commands in Windows PowerShell to configure live WezTerm settings and developer fonts:

```powershell
# 1. Create live symbolic link to WezTerm configuration in WSL
Remove-Item "$HOME\.config\wezterm\wezterm.lua" -Force -ErrorAction SilentlyContinue
Remove-Item "$HOME\.wezterm.lua" -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Path "$HOME\.config\wezterm" -Force
New-Item -ItemType SymbolicLink -Path "$HOME\.config\wezterm\wezterm.lua" -Target "\\wsl.localhost\Debian\home\levi\repos\dotfiles\.config\wezterm\wezterm.lua" -Force

# 2. Download, extract, and register Hack Nerd Font
Invoke-WebRequest -Uri "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Hack.zip" -OutFile "$env:TEMP\Hack.zip"
Expand-Archive "$env:TEMP\Hack.zip" -DestinationPath "$env:TEMP\Hack" -Force
New-Item -ItemType Directory -Path "$env:LOCALAPPDATA\Microsoft\Windows\Fonts" -Force
Copy-Item "$env:TEMP\Hack\*.ttf" "$env:LOCALAPPDATA\Microsoft\Windows\Fonts\" -Force
Remove-Item "$env:TEMP\Hack.zip", "$env:TEMP\Hack" -Recurse -Force
$fonts = Get-ChildItem "$env:LOCALAPPDATA\Microsoft\Windows\Fonts\Hack*.ttf"
$regPath = "HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts"
foreach ($f in $fonts) { New-ItemProperty -Path $regPath -Name $f.Name -Value $f.FullName -PropertyType String -Force }
```

---

### 3. Native Debian GNU/Linux (Homelab / Server)

```bash
git clone https://github.com/levicherrin/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
bash bootstrap.sh
```

---

## Daily Workflow

To apply any configuration edits after changing files in your repository:

```bash
cd ~/.dotfiles
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
| `AGENTS.md` | Universal AI agent policy and engineering baseline |
| `VOICE.md` | Writing style guide and persona for agent communication |
| `OPINIONS.md` | Technical opinions and architectural heuristics |
| `tests/` | Automated test suite (`lib.sh`, `validate.sh`) |

---

## Universal AI Agent Layer

Declaratively fanned out via `home.nix` to **Google Antigravity** (`~/.gemini/config/rules/`), **AWS Kiro** (`~/.kiro/steering/`), and standard fallback paths (`~/.config/`):


* **`AGENTS.md` (Core Policy)**: Universal formatting rules (zero emojis, zero unicode em dashes, no AI co-author tag pollution), operator autonomy balance, and engineering excellence standards.
* **`VOICE.md` (Communication Style)**: Writing tone, active voice, short paragraphs, and banned generic AI clichés ("delve", "tapestry", "game-changer", "leverage").
* **`OPINIONS.md` (Architectural Heuristics)**: Technical preferences (simplicity over speculative abstractions, boring technology, minimal dependencies, and mandatory end-to-end bug reproduction).



---

## WezTerm Configuration

Located in `.config/wezterm/wezterm.lua`:

* **Theme & Typography**: Catppuccin Mocha color scheme with Hack Nerd Font at 15.0pt.
* **Contrast & Opacity**: 100% solid opacity for crisp text contrast.
* **Window Ergonomics**: Draggable titlebar with standard window controls.
* **Cross-Platform Auto-Launch**: On Windows hosts, automatically selects the `WSL:Debian` domain and defaults to `$HOME` (`~`). On macOS, enables native window settings.

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

### Shell and Editor Shortcuts

* `v` / `vi` / `vim` : Open modern Neovim (`nvim`)
* `tree` : Detailed directory tree showing hidden files while ignoring `.git`
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

---

## Testing & Validation

Run the automated validation suite to verify script syntax, symlink targets, and code quality before applying changes:

```bash
./tests/validate.sh
```
