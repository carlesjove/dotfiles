## Refactoring

Refactoring is removing either duplication from code or breaking large chunks
into smaller pieces (extracting), _without affecting
behaviour_. The way to ensure behaviour did not change is that tests are green
all along. Tests are, in fact, the safety net for refactoring: a test needed to be touched is a red flag.

Refactoring is the exception to test-first: since behaviour doesn't change, no
new test is written.

When refactoring, follow this process:

- Wear one hat at a time: never change behaviour in the same step as a refactoring. If you spot a bug or a missing feature while refactoring, note it and tell me — don't fix it. Refactorings get their own commits.
- Tests should not be touched during refactoring. If test coverage is poor, first write tests that bring confidence for the refactoring; these tests should be green _before_ the refactoring. If a test fails during refactoring, undo the refactoring, pause and explain to me.
- If you consider a test should be changed, pause and ask me how to proceed
- Keep this rule in mind: repetition is cheaper than the wrong abstraction. Don't attempt to remove all duplication; only where it still keeps a clear idea of what the code is doing
- Go in very small increments: refactor as tiny pieces of code as possible, re-run tests, repeat
- Let me emphasize: small changes, often, chained by tests still passing
- Run the narrowest suite covering the code on each increment; run the full suite before reporting done
