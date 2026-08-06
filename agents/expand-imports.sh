#!/usr/bin/env bash
#
# Replace `@path` import lines in an instruction file with the contents of the
# file they point at, and write the result to stdout.
#
# Usage: expand-imports.sh <file>
#
# Claude Code and Gemini CLI resolve `@` imports themselves, but an agent that
# reads its instruction file literally gets the string `@~/dotfiles/...` and
# none of the rules. install.sh pipes those agents' files through here so the
# rules end up inlined. The import lines stay in the source file, so if such an
# agent gains `@` support the source is already correct.
#
# Only a line that is nothing but `@path` is expanded — a stray `@mention` in
# prose is left alone. Imports are not resolved recursively. A path that does
# not exist becomes a one-line note, so a machine missing an optional private
# file still gets a usable file.
#
# The output is a snapshot: re-run install.sh after editing a rule.

set -euo pipefail

source_file="${1:-}"

if [[ -z "$source_file" ]]; then
  echo "Usage: expand-imports.sh <file>" >&2
  exit 1
fi

if [[ ! -f "$source_file" ]]; then
  echo "expand-imports.sh: no such file: $source_file" >&2
  exit 1
fi

# `|| [[ -n "$line" ]]` keeps a final line that has no trailing newline.
while IFS= read -r line || [[ -n "$line" ]]; do
  if [[ "$line" == @* && "$line" != *[[:space:]]* ]]; then
    path="${line#@}"
    path="${path/#\~/$HOME}"

    if [[ -f "$path" ]]; then
      # Command substitution strips trailing newlines; printf puts exactly one
      # back so the imported file cannot run into the line after it.
      content="$(cat "$path")"
      printf '%s\n' "$content"
    else
      printf '_Not present on this machine: %s_\n' "$path"
    fi
  else
    printf '%s\n' "$line"
  fi
done < "$source_file"
