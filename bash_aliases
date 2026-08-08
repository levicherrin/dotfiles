# ======================================================================
# CUSTOM COLORS
# ======================================================================

# Ensure 'ls' and 'll' use colors
alias ls='ls --color=auto'
alias ll='ls -al --color=auto'

# Faster parent directory navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'

# Jump back to the last directory you were in
alias -- -='cd -'

# Sort files by last modified date (newest at the bottom - great for finding recent downloads/logs)
alias lt='ls -lha -rt --color=auto'

# Show file sizes in human-readable format (KB, MB, GB)
alias lh='ls -lh --color=auto'

# Directory tree view (requires 'tree' package, or fallback to ls)
alias tree='tree -C'

# Git shorthands
alias gs='git status'
alias ga='git add'
alias gaa='git add --all'
alias gc='git commit -m'
alias gp='git push'
alias gl='git pull'

# Visual Git log right in your terminal
alias glog='git log --oneline --graph --decorate --all'

# Instantly see which ports are currently listening/bound on your machine
alias ports='sudo ss -tulpn'

# Pretty-print your PATH variable (one directory per line) instead of a wall of text
alias path='echo -e ${PATH//:/\\n}'

# Reload .bashrc settings instantly after editing
alias reload='source ~/.bashrc'

# Show public IP address
alias myip='curl -s ipinfo.io; echo'

# Clear screen with a single letter
alias c='clear'
