#!/usr/bin/env bash
#
# Dotfiles installer & interactive sync script.
# Idempotent, non-destructive, and asks confirmation at every step.

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

prompt_ask() {
  local prompt_msg="$1"
  local default="${2:-y}"
  local reply

  if [[ "$default" == "y" ]]; then
    read -rp "$prompt_msg [Y/n] " reply
    reply="${reply:-y}"
  else
    read -rp "$prompt_msg [y/N] " reply
    reply="${reply:-n}"
  fi

  case "$reply" in
    [yY][eE][sS]|[yY]) return 0 ;;
    *) return 1 ;;
  esac
}

link_file() {
  local src="$1"
  local dest="$2"

  if [[ -L "$dest" ]] && [[ "$(readlink "$dest")" == "$src" ]]; then
    echo "  ✔ Already linked: $dest -> $src"
    return 0
  fi

  if prompt_ask "Symlink $dest -> $src?"; then
    mkdir -p "$(dirname "$dest")"
    if [[ -e "$dest" || -L "$dest" ]]; then
      echo "  ⚠️ Existing file found. Backing up $dest to ${dest}.bak"
      mv "$dest" "${dest}.bak"
    fi
    ln -s "$src" "$dest"
    echo "  ✅ Linked $dest"
  else
    echo "  ⏭️ Skipped $dest"
  fi
}

copy_file() {
  local src="$1"
  local dest="$2"

  if prompt_ask "Copy $src -> $dest?"; then
    mkdir -p "$(dirname "$dest")"
    if [[ -e "$dest" ]]; then
      if prompt_ask "  File $dest already exists. Overwrite?" "n"; then
        cp -R "$src" "$dest"
        echo "  ✅ Overwritten $dest"
      else
        echo "  ⏭️ Kept existing $dest"
      fi
    else
      cp -R "$src" "$dest"
      echo "  ✅ Copied $dest"
    fi
  else
    echo "  ⏭️ Skipped $dest"
  fi
}

echo "=========================================="
echo " Starting Dotfiles Setup / Interactive Sync"
echo "=========================================="

echo ""
echo "--- Core Shell & Tool Symlinks ---"
link_file "$DOTFILES_DIR/zshrc" "$HOME/.zshrc"
link_file "$DOTFILES_DIR/aliases" "$HOME/.aliases"
link_file "$DOTFILES_DIR/gitconfig" "$HOME/.gitconfig"
link_file "$DOTFILES_DIR/gitignore" "$HOME/.gitignore"
link_file "$DOTFILES_DIR/vimrc" "$HOME/.vimrc"
link_file "$DOTFILES_DIR/vimrc.bundles" "$HOME/.vimrc.bundles"

echo ""
echo "--- Claude Code Setup ---"
copy_file "$DOTFILES_DIR/agents/claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md"
copy_file "$DOTFILES_DIR/agents/claude/settings.json" "$HOME/.claude/settings.json"
copy_file "$DOTFILES_DIR/agents/claude/commands" "$HOME/.claude/commands"

echo ""
echo "--- Antigravity Setup ---"
copy_file "$DOTFILES_DIR/agents/antigravity/GEMINI.md" "$HOME/.gemini/GEMINI.md"
copy_file "$DOTFILES_DIR/agents/antigravity/GEMINI.md" "$HOME/.gemini/antigravity-cli/GEMINI.md"

echo ""
echo "=========================================="
echo " Setup complete!"
echo "=========================================="
