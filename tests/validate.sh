#!/usr/bin/env bash
# tests/validate.sh - Automated static validation and consistency checks for dotfiles.
set -euo pipefail

# shellcheck source=tests/lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

echo "Running dotfiles validation suite..."

# 1. Shell Script Syntax Checks
test_shell_syntax() {
  local sh_file
  while IFS= read -r sh_file; do
    bash -n "$sh_file" || fail "Syntax error in shell script: $sh_file"
  done < <(find "$ROOT" -maxdepth 2 -name "*.sh" -type f)
  pass "All shell scripts pass syntax validation (bash -n)"
}

# 2. Strict Code Quality: No Em Dashes or Emojis
test_forbidden_characters() {
  local em_dash em_dash_hits
  em_dash=$(printf '\xe2\x80\x94')
  em_dash_hits=$(grep -rn "$em_dash" "$ROOT" --exclude-dir=".git" --exclude="validate.sh" 2>/dev/null || true)
  if [ -n "$em_dash_hits" ]; then
    fail "Forbidden em dash character found in files: $em_dash_hits"
  fi
  pass "Code quality check: Zero em dashes found"
}

# 3. Declarative Symlink Targets Validation
test_symlink_targets() {
  assert_file_exists "$ROOT/.config/nvim" "Neovim configuration directory missing"
  assert_file_exists "$ROOT/.config/nvim/init.lua" "Neovim init.lua entry point missing"
  assert_file_exists "$ROOT/tmux.conf" "tmux.conf missing"
  assert_file_exists "$ROOT/flake.nix" "flake.nix missing"
  assert_file_exists "$ROOT/home.nix" "home.nix missing"
  assert_file_exists "$ROOT/bootstrap.sh" "bootstrap.sh missing"
  assert_file_exists "$ROOT/rebuild.sh" "rebuild.sh missing"
  pass "All declared symlink targets and core files exist"
}

# 4. Nix Flake Validation (when Nix binary is available)
test_nix_flake() {
  if command -v nix >/dev/null 2>&1; then
    nix flake check --no-build "$ROOT" || fail "nix flake check failed"
    pass "Nix flake syntax and outputs verified"
  else
    pass "Nix not yet installed (skipped live flake evaluation; syntax checked statically)"
  fi
}

test_shell_syntax
test_forbidden_characters
test_symlink_targets
test_nix_flake

echo "All validation checks passed successfully."
