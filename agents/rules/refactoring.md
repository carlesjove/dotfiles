## Refactoring

Removing duplication, or breaking large chunks into smaller pieces (extracting), _without affecting behaviour_. Green tests all the way through are what prove behaviour didn't change — they are the safety net, so a test that needs touching is a red flag.

Refactoring is the exception to test-first: behaviour doesn't change, so no new test is written.

- **Wear one hat at a time.** Never change behaviour in the same step as a refactoring. If you spot a bug or a missing feature, note it and tell me — don't fix it. Refactorings get their own commits.
- **Don't touch tests.** If coverage is too poor to refactor safely, first write tests that bring confidence; they must be green _before_ the refactoring starts.
- **A test failing mid-refactor means undo it**, then pause and explain to me. If you think a test should be changed, pause and ask me how to proceed.
- **Small changes, often**, chained by tests still passing: refactor the tiniest piece of code possible, re-run tests, repeat.
- **Repetition is cheaper than the wrong abstraction.** Don't attempt to remove all duplication — only where removing it keeps a clear idea of what the code is doing.
- Run the narrowest suite covering the code on each increment; run the full suite before reporting done.
