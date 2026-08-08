# Levi's dotfiles

Minimal, portable shell configuration for Debian (WSL2 and Linux) featuring an integrated Git prompt, enhanced aliases, and standard history controls.

## Quick Start

Run these commands in your terminal to clone and link the configuration:

```bash
git clone https://github.com/levicherrin/dotfiles.git ~/repos/dotfiles  
cd ~/repos/dotfiles  
chmod +x install.sh  
./install.sh  
source ~/.bashrc
```

## Repository Structure

| File | Description |
| :---- | :---- |
| `bashrc` | Core shell configuration (history rules, window checks, PATH, Git prompt, LS_COLORS) |
| `bash_aliases` | Shortcuts for navigation, Git workflows, system tools, and terminal utilities |
| `install.sh` | Automated setup script that creates symbolic links to the home directory |

## Included Shortcuts and Highlights

### File Listing and Navigation

* `ll` : Detailed list view (ls -al --color=auto)  
* `lt` : Sort files by last modified date (newest at bottom)  
* `lh` : Human-readable file sizes (KB, MB, GB)  
* `..` / `...` / `....` : Fast parent directory traversal

### Git Shortcuts

* `gs` : git status  
* `ga` / `gaa` : git add / git add --all  
* `gc` : git commit -m  
* `gp` / `gl` : git push / git pull  
* `glog` : Visual one-line Git log graph

### System and Network

* `ports` : Show listening system ports (sudo ss -tulpn)  
* `path` : Print PATH variable on separate lines for readability  
* `myip` : Fetch public IP address via ipinfo.io  
* `reload` : Reload ~/.bashrc instantly

## Manual Linking

If you prefer to link the files manually instead of using install.sh:

```bash
ln -sf ~/repos/dotfiles/bashrc ~/.bashrc  
ln -sf ~/repos/dotfiles/bash_aliases ~/.bash_aliases  
source ~/.bashrc  
```
