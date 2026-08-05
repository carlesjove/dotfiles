Welcome to my dotfiles :-)

For years I have been using community maintained dotfiles, mostly Thoughtbot's
dotfiles. Now I have switched from macOS to Linux and I'm taking this as an
opportunity to start my own dotfiles, with only stuff that:

- I need
- I understand

My current .vimrc still has a lot of stuff coming from Thoughtbot's (thanks!),
but I've removed everything that didn't met the criteria above.

## How to use

```
$ git clone https://github.com/carlesjove/dotfiles ~/dotfiles
$ ln -s ~/dotfiles/zshrc ~/.zshrc
$ ln -s ~/dotfiles/aliases ~/.aliases
$ ln -s ~/dotfiles/gitconfig ~/.gitconfig
$ ln -s ~/dotfiles/gitignore ~/.gitignore
$ ln -s ~/dotfiles/vimrc ~/.vimrc
$ ln -s ~/dotfiles/vimrc.bundles ~/.vimrc.bundles
```

Alternatively, you can run the interactive setup script which prompts [Y/n] before taking action on each file:

```bash
$ ~/dotfiles/install.sh
```

After doing this you should open vim and run `PlugInstall`.

## AI Agents (`agents/`)

AI coding assistant configurations live under `agents/` to keep root clean and modular:

- `agents/rules/`: Shared, agent-agnostic guidelines (e.g. `tdd.md`).
- `agents/claude/`: Claude Code specific configuration (`CLAUDE.md`, `settings.json`, `commands/`).
- `agents/antigravity/`: Antigravity specific configuration (`GEMINI.md`).
- `agents/local.md.example`: Template for per-machine overrides. See below.

To prevent runtime state changes (such as model selection or permission allowlists) from polluting the dotfiles git repository, baseline files are copied to local environment directories during setup. Run `install.sh` and it does all of this for you.

`agents/rules/tdd.md` holds universal TDD guidelines and is imported by both `CLAUDE.md` and `GEMINI.md` via `@` import lines.

### Three kinds of file

Every file the installer puts in `~/.claude` or `~/.gemini` falls into one of three buckets, and which bucket decides whether the installer may overwrite it:

| Bucket | Example | Installer behaviour |
|---|---|---|
| **Managed** — only `@` imports, no local content | `CLAUDE.md`, `GEMINI.md` | Overwritten, no questions asked |
| **Local** — yours, per machine, untracked | `~/.claude/local.md` | Created once if absent, then never touched |
| **Runtime-mutated** — the agent writes to it | `settings.json` | Copied, but asks before overwriting |

This split is what lets a rule change propagate to every machine without the installer ever facing a choice where both answers are wrong. Keeping local edits out of the managed files is the whole point: put them in `~/.claude/local.md` (or `~/.gemini/local.md`) instead, which the managed file imports.

Anything specific to one machine or to a private project belongs in the local file — including per-project exemptions from the shared rules, such as a repo that opts out of TDD.

### How Agent Rules Work

Generic rules live as standalone markdown files in `agents/rules/` (e.g. `agents/rules/tdd.md`). Agent-specific files (`agents/claude/CLAUDE.md`, `agents/antigravity/GEMINI.md`) reference them using `@` import lines, such as `@~/dotfiles/agents/rules/tdd.md`.

- **Modifying an existing rule**: Edit the rule file in `agents/rules/`. Changes are active immediately in your next session with any agent without needing to re-copy or re-run any setup script.
- **Adding a new rule**:
  1. Create the new markdown file in `agents/rules/` (e.g. `agents/rules/git-style.md`).
  2. Add `@~/dotfiles/agents/rules/git-style.md` to `agents/claude/CLAUDE.md` and `agents/antigravity/GEMINI.md`.
  3. Run `~/dotfiles/install.sh` to push the new import line out. This overwrites the managed `CLAUDE.md` / `GEMINI.md`, which is safe by design — nothing local lives in them.

Note that `@` imports are resolved by the agent, not by this repo, so this only works for agents that implement them (Claude Code and Gemini CLI do). An agent that reads its instruction file literally would need the rules concatenated in instead.

### Private context

This repo is public, so anything internal stays out of it. `CLAUDE.md` imports
extra files from `~/.claude/private/` with `@` lines; those files are not
version-controlled here and a missing one is harmless. To sync them across
machines, keep them in a private repo and symlink into `~/.claude/private/`.

Do not symlink `~/.claude` or `~/.gemini` directories themselves, and do not commit `~/.claude.json` — it contains MCP server config and may hold API tokens.
