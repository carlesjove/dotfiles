# Test-Driven Development (TDD) Guidelines

## TDD is the default

Write the test first. Concretely, for every behaviour change:

1. Write a failing test that describes the desired behaviour.
2. Run it. Confirm it fails, and that it fails for the expected reason — not from a typo, missing import, or misconfigured fixture.
3. Write the minimum implementation to make it pass.
4. Run the test again. Show the output.
5. Refactor only once it's green.

Do not write implementation code before its test exists. If implementation code has already been written, stop and say so rather than backfilling tests to match what was written — tests written after the fact tend to assert what the code does instead of what it should do.

Never report work as done based on the code looking correct. Report it as done when a test you ran proves it, and paste the output. If the tests didn't run, say why.

## When TDD doesn't fit

Some work is genuinely not test-first: exploratory spikes, one-off scripts, config and infrastructure changes, debugging where the reproduction *is* the test. In those cases say which it is and why in one line, then proceed. Don't silently skip the tests, and don't ask permission for the obvious cases.

Never use TDD for scripts in `l-carles-scripts`.

### Reversed TDD as an option

There might be times in which we need to figure out if an implementation or approach would be even possible, or in which we want to quickly write an implementation as a proof of concept. In those cases it's fine to start with the code, but then we will comment-out or remove the code and start a TDD process. We'll call this "reversed TDD". The user can ask to use this method or you can suggest to use it if it fits better.
