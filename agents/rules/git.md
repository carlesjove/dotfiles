## Git conventions

- Commit to the branch currently checked out. Never switch branches or create one as a side effect of being asked to commit. Read the branch with `git branch --show-current` — the session-start snapshot goes stale mid-session.
- When the work came from a ticket, prefix the subject with its ID in the repo's convention: `LOC-1234 Imperative summary`. Use the ticket being worked in this session or branch; ask when a change spans several.
- Keep messages short: a subject line plus two to four lines on what broke and what the fix does. No per-decision rationale, no walkthrough of the failure modes — that belongs in the PR, the ticket, or a comment at the line it concerns.
