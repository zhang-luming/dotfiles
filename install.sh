#!/usr/bin/env bash
set -Eeuo pipefail

repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$repo_dir"

command -v stow >/dev/null 2>&1 || {
  echo "GNU Stow is required" >&2
  exit 1
}

stow --target="$HOME" shell ssh

# Keep SSH material private after Stow creates the links.
chmod 700 "$HOME/.ssh"
chmod 600 "$HOME/.ssh/config" "$HOME/.ssh/authorized_keys" 2>/dev/null || true
chmod 644 "$HOME/.ssh/id_rsa.pub" 2>/dev/null || true
echo "Dotfiles deployed from $repo_dir"
