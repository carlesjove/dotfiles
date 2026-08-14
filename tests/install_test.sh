#!/usr/bin/env bash
#
# Tests for install.sh, focused on the guarantee that is easiest to break: every
# agent's main instruction file lands on disk with its imports already inlined,
# so no agent has to understand the `@` directive to get the rules — unless the
# user asks for the imports to be left in place with --no-expand.
#
# The whole run is confined to a throwaway $HOME. install.sh only ever writes
# under $HOME, so pointing $HOME at a temp dir makes the installer safe to
# execute for real rather than mocking it.
#
# No test framework on purpose: this repo has no dependencies and a fresh
# machine must be able to run this straight after `git clone`.
#
# Usage: tests/install_test.sh

set -uo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Every agent instruction file the installer is expected to put on disk, as
# HOME-relative paths. A new agent gets a line here and the whole suite covers
# it, expanded and not.
AGENT_FILES=(
  ".claude/CLAUDE.md"
  ".gemini/GEMINI.md"
  ".config/opencode/AGENTS.md"
)

LOCAL_FILES=(
  ".claude/local.md"
  ".gemini/local.md"
  ".config/opencode/local.md"
)

failures=0

pass() { echo "  ✅ $1"; }
fail() {
  echo "  ❌ $1"
  failures=$((failures + 1))
}

assert_contains() {
  local name="$1" haystack="$2" needle="$3"

  if [[ "$haystack" == *"$needle"* ]]; then
    pass "$name"
  else
    fail "$name (expected to find: $needle)"
  fi
}

assert_not_contains() {
  local name="$1" haystack="$2" needle="$3"

  if [[ "$haystack" != *"$needle"* ]]; then
    pass "$name"
  else
    fail "$name (unexpectedly found: $needle)"
  fi
}

# Run install.sh non-interactively against a fresh throwaway HOME and leave its
# path in $INSTALL_HOME. Extra arguments are passed through to the installer.
# Not a command substitution on purpose: a failure reported from inside a
# subshell would be captured as output and lost from the failure count.
run_install() {
  INSTALL_HOME="$(mktemp -d)"
  TMP_HOMES+=("$INSTALL_HOME")

  # The instruction files import `@~/dotfiles/...`, so the fake HOME needs a
  # dotfiles at that path. This mirrors the layout install.sh assumes anyway.
  ln -s "$DOTFILES_DIR" "$INSTALL_HOME/dotfiles"

  if ! HOME="$INSTALL_HOME" "$DOTFILES_DIR/install.sh" -y "$@" \
      > "$INSTALL_HOME/install.log" 2>&1; then
    fail "install.sh $* exited non-zero"
    sed 's/^/  |/' "$INSTALL_HOME/install.log"
  fi
}

TMP_HOMES=()
cleanup() {
  local home
  for home in "${TMP_HOMES[@]:-}"; do
    [[ -n "$home" ]] && rm -rf "$home"
  done
}
trap cleanup EXIT


echo "Test: by default every agent file is installed with its imports inlined"

run_install
default_home="$INSTALL_HOME"

for rel in "${AGENT_FILES[@]}"; do
  file="$default_home/$rel"

  if [[ ! -f "$file" ]]; then
    fail "$rel was not installed"
    continue
  fi

  if grep -q '^@' "$file"; then
    fail "$rel still contains an unexpanded import line"
    grep -n '^@' "$file" | sed 's/^/  |/'
  else
    pass "$rel has no unexpanded import lines"
  fi

  contents="$(cat "$file")"
  assert_contains "$rel inlines the shared TDD rule" \
    "$contents" "Test-Driven Development"
  assert_contains "$rel inlines the machine-local file" \
    "$contents" "Machine-local agent instructions"
done


echo "Test: every machine-local override file is created"

for rel in "${LOCAL_FILES[@]}"; do
  if [[ -f "$default_home/$rel" ]]; then
    pass "seeded $rel"
  else
    fail "did not seed $rel"
  fi
done


echo "Test: an agent file keeps its own content alongside the inlined rules"

assert_contains "GEMINI.md keeps its own content" \
  "$(cat "$default_home/.gemini/GEMINI.md" 2>/dev/null)" "Antigravity Guidelines"


echo "Test: a private file absent on this machine is a note, not a broken build"

assert_contains "absent private import degrades to a note" \
  "$(cat "$default_home/.claude/CLAUDE.md" 2>/dev/null)" "Not present on this machine"


echo "Test: re-running is idempotent and leaves local files alone"

second_run="$(HOME="$default_home" "$DOTFILES_DIR/install.sh" -y 2>&1)"
assert_contains "agent file reported up to date" \
  "$second_run" "Up to date: $default_home/.claude/CLAUDE.md"
assert_contains "local.md left alone on re-run" \
  "$second_run" "Kept local file: $default_home/.claude/local.md"


echo "Test: --no-expand installs every agent file verbatim, imports intact"

run_install --no-expand
raw_home="$INSTALL_HOME"

for rel in "${AGENT_FILES[@]}"; do
  file="$raw_home/$rel"

  if [[ ! -f "$file" ]]; then
    fail "$rel was not installed with --no-expand"
    continue
  fi

  if grep -q '^@' "$file"; then
    pass "$rel keeps its import lines"
  else
    fail "$rel lost its import lines despite --no-expand"
  fi

  contents="$(cat "$file")"
  assert_not_contains "$rel does not inline the TDD rule under --no-expand" \
    "$contents" "Test-Driven Development"
done


echo "Test: --no-expand still seeds the machine-local override files"

for rel in "${LOCAL_FILES[@]}"; do
  if [[ -f "$raw_home/$rel" ]]; then
    pass "seeded $rel under --no-expand"
  else
    fail "did not seed $rel under --no-expand"
  fi
done


echo "Test: --no-expand installs each agent file byte-for-byte from its source"

if cmp -s "$DOTFILES_DIR/agents/claude/CLAUDE.md" "$raw_home/.claude/CLAUDE.md"; then
  pass "CLAUDE.md matches its source under --no-expand"
else
  fail "CLAUDE.md differs from its source under --no-expand"
fi

if cmp -s "$DOTFILES_DIR/agents/antigravity/GEMINI.md" "$raw_home/.gemini/GEMINI.md"; then
  pass "GEMINI.md matches its source under --no-expand"
else
  fail "GEMINI.md differs from its source under --no-expand"
fi

if cmp -s "$DOTFILES_DIR/agents/opencode/AGENTS.md" "$raw_home/.config/opencode/AGENTS.md"; then
  pass "AGENTS.md matches its source under --no-expand"
else
  fail "AGENTS.md differs from its source under --no-expand"
fi


echo "Test: -h documents the flag and exits 0"

help_output="$("$DOTFILES_DIR/install.sh" -h 2>&1)"
status=$?
assert_contains "-h exits 0" "0" "$status"
assert_contains "-h documents --no-expand" "$help_output" "--no-expand"


echo ""
if [[ "$failures" -eq 0 ]]; then
  echo "All tests passed."
else
  echo "$failures assertion(s) failed."
  exit 1
fi
