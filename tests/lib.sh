#!/usr/bin/env bash
# tests/lib.sh - Shared primitives for dotfiles automated validation and testing.
#
# Source this from a test file:
#   # shellcheck source=tests/lib.sh
#   . "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

if [ -n "${DOTFILES_TEST_LIB_SOURCED:-}" ]; then
  return 0
fi
DOTFILES_TEST_LIB_SOURCED=1

# shellcheck disable=SC2034
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

fail() {
  printf 'not ok - %s\n' "$1" >&2
  exit 1
}

pass() {
  printf 'ok - %s\n' "$1"
}

# --- Self-cleaning temp directory --------------------------------------------

DOTFILES_TEST_CLEANUP_DIRS=()

dotfiles_test_cleanup() {
  local d
  for d in "${DOTFILES_TEST_CLEANUP_DIRS[@]:-}"; do
    [ -n "$d" ] && rm -rf "$d"
  done
}

dotfiles_test_tmproot() {
  local prefix=${1:-dotfiles-test} root
  root=$(mktemp -d "${TMPDIR:-/tmp}/${prefix}.XXXXXX")
  if [ "${#DOTFILES_TEST_CLEANUP_DIRS[@]}" -eq 0 ]; then
    trap dotfiles_test_cleanup EXIT
  fi
  DOTFILES_TEST_CLEANUP_DIRS+=("$root")
  printf '%s\n' "$root"
}

# --- Assertions --------------------------------------------------------------

assert_contains() {
  local haystack=$1 needle=$2 message=$3
  case "$haystack" in
    *"$needle"*) : ;;
    *) fail "$message" ;;
  esac
}

assert_not_contains() {
  local haystack=$1 needle=$2 message=$3
  case "$haystack" in
    *"$needle"*) fail "$message" ;;
    *) : ;;
  esac
}

assert_file_exists() {
  local path=$1 message=$2
  if [ ! -f "$path" ] && [ ! -d "$path" ]; then
    fail "$message: $path does not exist"
  fi
}
