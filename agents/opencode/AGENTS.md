# How I work

<!-- Managed by dotfiles/install.sh — it overwrites this file, with the @ imports
     below inlined unless it was run with --no-expand. Machine-specific
     instructions belong in ~/.config/opencode/local.md, which is never
     overwritten; re-run install.sh after editing it.

     Inlining matters here: OpenCode does not resolve `@path` imports the way
     Claude Code does. Its own mechanisms are the `instructions` key in
     opencode.json or telling the model to read a file on demand, so an
     un-inlined file would leave it with none of the rules. -->

@~/dotfiles/agents/rules/tdd.md

## This machine

@~/.config/opencode/local.md

## OpenCode Guidelines

- **Global vs project rules**: this file is the global one. A project's own
  AGENTS.md is loaded too, and there are reports of the project file shadowing
  the global one — if a rule here seems to be ignored inside a project, check
  whether that project has its own AGENTS.md.
