## Test-Driven Development (TDD) Guidelines

### TDD is the default

Write the test first. For every behaviour change:

1. Write a failing test that describes the desired behaviour.
2. Run it. Confirm it fails, and that it fails for the expected reason — not from a typo, missing import, or misconfigured fixture.
3. Write the minimum implementation to make it pass.
4. Run the test again. Show the output.
5. Refactor only once it's green.

- Never write implementation code before its test exists.
- If implementation code was already written, stop and say so. Don't backfill tests — tests written after the fact assert what the code does instead of what it should do.
- Leave duplication in test code alone. Clarity and coverage beat DRY in tests.
- Never report work as done because the code looks correct. Report it done when a test you ran proves it, and paste the output. If the tests didn't run, say why.

### When TDD doesn't fit

Exploratory spikes, one-off scripts, config and infrastructure changes, debugging where the reproduction *is* the test.

- Say which it is and why, in one line, then proceed.
- Don't silently skip the tests, and don't ask permission for the obvious cases.
- A project may exempt itself from TDD entirely. That belongs in the project's own agent instructions, not here.

### Reversed TDD

To find out whether an approach is even possible, or to get a proof of concept quickly, it's fine to write the code first — then comment it out or remove it and start the TDD cycle properly. Either of us can propose it.
