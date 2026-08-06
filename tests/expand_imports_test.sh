#!/usr/bin/env bash
#
# Tests for agents/expand-imports.sh, which replaces `@path` import lines with
# the contents of the file they point at, so that agents which read their
# instruction file literally still get the rules.
#
# No test framework on purpose: this repo has no dependencies and a fresh
# machine must be able to run this straight after `git clone`.
#
# Usage: tests/expand_imports_test.sh

set -uo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
EXPAND="$DOTFILES_DIR/agents/expand-imports.sh"

failures=0

assert_equal() {
  local name="$1" expected="$2" actual="$3"

  if [[ "$expected" == "$actual" ]]; then
    echo "  ✅ $name"
  else
    echo "  ❌ $name"
    echo "  --- expected ---"
    printf '%s\n' "$expected" | sed 's/^/  |/'
    echo "  --- actual ---"
    printf '%s\n' "$actual" | sed 's/^/  |/'
    echo "  ---"
    failures=$((failures + 1))
  fi
}

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

printf '# Rule\n\nRule body.\n' > "$tmp/rule.md"


echo "Test: an import line is replaced by the file it points at"

cat > "$tmp/absolute.md" <<EOF
# How I work

@$tmp/rule.md

## Footer
EOF

expected="$(cat <<'EOF'
# How I work

# Rule

Rule body.

## Footer
EOF
)"
actual="$("$EXPAND" "$tmp/absolute.md")"
assert_equal "import replaced by file contents" "$expected" "$actual"


echo "Test: a leading ~ in the import path is expanded"

printf '@~/dotfiles/agents/rules/tdd.md\n' > "$tmp/tilde.md"
actual="$("$EXPAND" "$tmp/tilde.md")"
if [[ "$actual" == *"Test-Driven Development"* ]]; then
  echo "  ✅ ~ expanded to \$HOME"
else
  echo "  ❌ ~ was not expanded to \$HOME"
  failures=$((failures + 1))
fi


echo "Test: an import of a file that is not on this machine is a note, not a failure"

printf '@%s/absent.md\n' "$tmp" > "$tmp/missing.md"
actual="$("$EXPAND" "$tmp/missing.md")"
status=$?
assert_equal "missing import exits 0" "0" "$status"
assert_equal "missing import leaves a note" \
  "_Not present on this machine: $tmp/absent.md_" "$actual"


echo "Test: only a line that is nothing but an import is expanded"

cat > "$tmp/inline.md" <<EOF
Ask @someone about it.
See @$tmp/rule.md for details.
  @$tmp/rule.md
EOF

expected="$(cat <<EOF
Ask @someone about it.
See @$tmp/rule.md for details.
  @$tmp/rule.md
EOF
)"
actual="$("$EXPAND" "$tmp/inline.md")"
assert_equal "@ mentions and indented imports pass through verbatim" "$expected" "$actual"


echo "Test: an imported file with no trailing newline does not swallow the next line"

printf '# No newline\n\nBody.' > "$tmp/no-newline.md"
cat > "$tmp/two.md" <<EOF
@$tmp/no-newline.md
## Footer
EOF

expected="$(cat <<'EOF'
# No newline

Body.
## Footer
EOF
)"
actual="$("$EXPAND" "$tmp/two.md")"
assert_equal "imported file is newline-terminated" "$expected" "$actual"


echo "Test: a file with no imports passes through verbatim"

printf '# Nothing to expand\n\nJust prose.\n' > "$tmp/verbatim.md"
expected="$(printf '# Nothing to expand\n\nJust prose.')"
actual="$("$EXPAND" "$tmp/verbatim.md")"
assert_equal "file without imports is unchanged" "$expected" "$actual"


echo "Test: the real GEMINI.md expands with no import lines left"

actual="$("$EXPAND" "$DOTFILES_DIR/agents/antigravity/GEMINI.md")"
status=$?
assert_equal "real GEMINI.md exits 0" "0" "$status"
if printf '%s\n' "$actual" | grep -q '^@'; then
  echo "  ❌ real GEMINI.md still contains an unexpanded import line"
  failures=$((failures + 1))
else
  echo "  ✅ real GEMINI.md has no unexpanded import lines"
fi
if [[ "$actual" == *"Test-Driven Development"* ]]; then
  echo "  ✅ real GEMINI.md inlines the TDD rule"
else
  echo "  ❌ real GEMINI.md did not inline the TDD rule"
  failures=$((failures + 1))
fi
if [[ "$actual" == *"Antigravity Guidelines"* ]]; then
  echo "  ✅ real GEMINI.md keeps its own content"
else
  echo "  ❌ real GEMINI.md lost its own content"
  failures=$((failures + 1))
fi


echo "Test: a missing input file is an error"

"$EXPAND" "$tmp/does-not-exist.md" >/dev/null 2>&1
status=$?
if [[ "$status" -ne 0 ]]; then
  echo "  ✅ missing input exits non-zero"
else
  echo "  ❌ missing input should exit non-zero"
  failures=$((failures + 1))
fi


echo ""
if [[ "$failures" -eq 0 ]]; then
  echo "All tests passed."
else
  echo "$failures assertion(s) failed."
  exit 1
fi
