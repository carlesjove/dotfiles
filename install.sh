#!/usr/bin/env bash
#
# Dotfiles installer & interactive sync script.
# Idempotent, non-destructive, and asks confirmation at every step.
#
# Usage: install.sh [-y] [-h] [--no-expand]
#   -y            Non-interactive: accept the default answer for every prompt.
#   -h            Show this help.
#   --no-expand   Install each agent's instruction file verbatim, leaving its
#                 `@` import lines for the agent to resolve itself. Only use
#                 this if every agent you run supports them — Antigravity, for
#                 one, does not, and would silently get none of the rules.
#                 By default the imports are inlined at install time.
#
# Safe to re-run to pick up updates. Re-running never discards a local edit
# without either backing it up first or leaving the file alone entirely.
# The one exception: a file in ~/.claude/commands/ that you edited locally AND
# that also exists in dotfiles is overwritten with no backup.

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ASSUME_DEFAULTS=false
EXPAND_IMPORTS=true

# getopts is short-option only, so pull the long options out first and hand it
# what's left. `${short[@]+...}` keeps `set --` from inventing an empty argument
# when every option was a long one.
short_opts=()
for arg in "$@"; do
  case "$arg" in
    --no-expand) EXPAND_IMPORTS=false ;;
    --*) echo "Unknown option: $arg" >&2; exit 1 ;;
    *) short_opts+=("$arg") ;;
  esac
done
set -- ${short_opts[@]+"${short_opts[@]}"}

while getopts ":yh" opt; do
  case "$opt" in
    y) ASSUME_DEFAULTS=true ;;
    h) sed -n '3,${/^#/!q;p;}' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
    \?) echo "Unknown option: -$OPTARG" >&2; exit 1 ;;
  esac
done

prompt_ask() {
  local prompt_msg="$1"
  local default="${2:-y}"
  local reply

  if [[ "$default" == "y" ]]; then
    if [[ "$ASSUME_DEFAULTS" == true ]]; then
      echo "$prompt_msg [Y/n] Y (assumed)"
      return 0
    fi
    read -rp "$prompt_msg [Y/n] " reply
    reply="${reply:-y}"
  else
    if [[ "$ASSUME_DEFAULTS" == true ]]; then
      echo "$prompt_msg [y/N] N (assumed)"
      return 1
    fi
    read -rp "$prompt_msg [y/N] " reply
    reply="${reply:-n}"
  fi

  case "$reply" in
    [yY][eE][sS]|[yY]) return 0 ;;
    *) return 1 ;;
  esac
}

# Move an existing path aside without ever clobbering a previous backup.
backup_path() {
  local target="$1"
  local backup="${target}.bak.$(date +%Y%m%d%H%M%S)"

  # Same-second reruns would otherwise collide.
  local n=1
  while [[ -e "$backup" || -L "$backup" ]]; do
    backup="${target}.bak.$(date +%Y%m%d%H%M%S).$n"
    n=$((n + 1))
  done

  mv "$target" "$backup"
  echo "$backup"
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
      local backup
      backup="$(backup_path "$dest")"
      echo "  ⚠️ Existing file found. Backed up to $backup"
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
        cp "$src" "$dest"
        echo "  ✅ Overwritten $dest"
      else
        echo "  ⏭️ Kept existing $dest"
      fi
    else
      cp "$src" "$dest"
      echo "  ✅ Copied $dest"
    fi
  else
    echo "  ⏭️ Skipped $dest"
  fi
}

# For files that hold no local content, only imports of dotfiles-tracked rules.
# Overwriting is always safe, so don't ask a keep-or-destroy question whose
# every answer is wrong: "keep" strands the machine on stale rules, "overwrite"
# would eat local edits if there were any. There are none — see seed_file.
install_verbatim_file() {
  local src="$1"
  local dest="$2"

  if cmp -s "$src" "$dest"; then
    echo "  ✔ Up to date: $dest"
    return 0
  fi

  if prompt_ask "Install managed $dest (overwrites, holds no local content)?"; then
    mkdir -p "$(dirname "$dest")"
    cp "$src" "$dest"
    echo "  ✅ Installed $dest"
  else
    echo "  ⏭️ Skipped $dest"
  fi
}

# Same contract as install_verbatim_file, but the file is installed with its `@`
# imports replaced by the contents of the files they point at. This is the
# default for every agent: whether a given one resolves `@` itself is its own
# undocumented business, and an agent that doesn't would silently run with no
# rules at all. The installed copy is therefore a snapshot — a rule or local.md
# edit needs another install.sh run to reach the agents.
install_expanded_file() {
  local src="$1"
  local dest="$2"
  local built
  built="$(mktemp)"

  if ! "$DOTFILES_DIR/agents/expand-imports.sh" "$src" > "$built"; then
    rm -f "$built"
    echo "  ❌ Failed to expand imports in $src; left $dest alone" >&2
    return 1
  fi

  if cmp -s "$built" "$dest"; then
    rm -f "$built"
    echo "  ✔ Up to date: $dest"
    return 0
  fi

  if prompt_ask "Install managed $dest (imports inlined, overwrites, holds no local content)?"; then
    mkdir -p "$(dirname "$dest")"
    cp "$built" "$dest"
    echo "  ✅ Installed $dest with imports inlined"
  else
    echo "  ⏭️ Skipped $dest"
  fi
  rm -f "$built"
}

# Install an agent's main instruction file, inlining its imports unless
# --no-expand was passed. Every agent goes through here, so the choice is the
# user's once and applies everywhere.
install_agent_file() {
  if [[ "$EXPAND_IMPORTS" == true ]]; then
    install_expanded_file "$1" "$2"
  else
    install_verbatim_file "$1" "$2"
  fi
}

# Create dest from a template only if it is absent. Once it exists it belongs to
# the machine and the installer never touches it again.
seed_file() {
  local src="$1"
  local dest="$2"

  if [[ -e "$dest" ]]; then
    echo "  ✔ Kept local file: $dest"
    return 0
  fi

  if prompt_ask "Seed empty local override file $dest?"; then
    mkdir -p "$(dirname "$dest")"
    cp "$src" "$dest"
    echo "  ✅ Seeded $dest"
  else
    echo "  ⏭️ Skipped $dest"
  fi
}

# Merge a directory's *contents* into dest. `cp -R src dest` would nest as
# dest/$(basename src) once dest exists, so the trailing /. matters.
# Merge, not mirror: files you add locally survive, but files deleted from
# dotfiles are not removed from dest.
sync_dir() {
  local src="$1"
  local dest="$2"

  if prompt_ask "Sync contents of $src -> $dest/?"; then
    mkdir -p "$dest"
    cp -R "$src/." "$dest/"
    echo "  ✅ Synced $dest"
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
# local.md is seeded before CLAUDE.md is installed because it is one of the
# files CLAUDE.md imports — inlining can only pick it up once it exists.
seed_file "$DOTFILES_DIR/agents/local.md.example" "$HOME/.claude/local.md"
install_agent_file "$DOTFILES_DIR/agents/claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md"
copy_file "$DOTFILES_DIR/agents/claude/settings.json" "$HOME/.claude/settings.json"
sync_dir "$DOTFILES_DIR/agents/claude/commands" "$HOME/.claude/commands"

echo ""
echo "--- OpenCode Setup ---"
# OpenCode reads its global rules from $XDG_CONFIG_HOME/opencode/AGENTS.md. It does
# not resolve `@` imports itself, so the default expanded install is what gets it
# the shared rules — see the note in agents/opencode/AGENTS.md.
seed_file "$DOTFILES_DIR/agents/local.md.example" "$HOME/.config/opencode/local.md"
install_agent_file "$DOTFILES_DIR/agents/opencode/AGENTS.md" "$HOME/.config/opencode/AGENTS.md"

echo ""
echo "--- Antigravity Setup ---"
seed_file "$DOTFILES_DIR/agents/local.md.example" "$HOME/.gemini/local.md"
install_agent_file "$DOTFILES_DIR/agents/antigravity/GEMINI.md" "$HOME/.gemini/GEMINI.md"
# Antigravity's CLI reads its own copy; link it so the two cannot drift.
link_file "$HOME/.gemini/GEMINI.md" "$HOME/.gemini/antigravity-cli/GEMINI.md"

echo ""
echo "=========================================="
echo " Setup complete!"
echo "=========================================="
