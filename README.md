Welcome to my dotfiles :-)

For years I have been using community maintained dotfiles, but at some point I
decided to start my own with only stuff that:

- I need
- I understand

My current .vimrc still has a lot of stuff coming from Thoughtbot's dotfiles (thanks!),
but I've removed everything that didn't meet the criteria above.

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

- `agents/rules/`: Shared, agent-agnostic guidelines (e.g. `tdd.md`, `refactoring.md`).
- `agents/claude/`: Claude Code specific configuration (`CLAUDE.md`, `settings.json`, `commands/`).
- `agents/antigravity/`: Antigravity specific configuration (`GEMINI.md`).
- `agents/opencode/`: opencode specific configuration (`AGENTS.md`, installed to `~/.config/opencode/AGENTS.md`).
- `agents/local.md.example`: Template for per-machine overrides. See below.

To prevent runtime state changes (such as model selection or permission allowlists) from polluting the dotfiles git repository, baseline files are copied to local environment directories during setup. Run `install.sh` and it does all of this for you.

- `agents/expand-imports.sh`: Inlines `@` imports so an agent doesn't have to resolve them itself. See below.

`agents/rules/` holds the universal guidelines — `tdd.md` (test-first workflow) and `refactoring.md` (behaviour-preserving changes) — each imported by `CLAUDE.md`, `GEMINI.md` and `AGENTS.md` via `@` import lines.

### Three kinds of file

Every file the installer puts in `~/.claude`, `~/.gemini` or `~/.config/opencode` falls into one of three buckets, and which bucket decides whether the installer may overwrite it:

| Bucket | Example | Installer behaviour |
|---|---|---|
| **Managed** — only `@` imports, no local content | `CLAUDE.md`, `GEMINI.md`, `AGENTS.md` | Overwritten, no questions asked |
| **Local** — yours, per machine, untracked | `~/.claude/local.md`, `~/.config/opencode/local.md` | Created once if absent, then never touched |
| **Runtime-mutated** — the agent writes to it | `settings.json` | Copied, but asks before overwriting |

This split is what lets a rule change propagate to every machine without the installer ever facing a choice where both answers are wrong. Keeping local edits out of the managed files is the whole point: put them in `~/.claude/local.md` (or `~/.gemini/local.md` or `~/.config/opencode/local.md`) instead, which the managed file imports.

Anything specific to one machine or to a private project belongs in the local file — including per-project exemptions from the shared rules, such as a repo that opts out of TDD.

### How Agent Rules Work

Generic rules live as standalone markdown files in `agents/rules/` (e.g. `agents/rules/tdd.md`). Agent-specific files (`agents/claude/CLAUDE.md`, `agents/antigravity/GEMINI.md`) reference them using `@` import lines, such as `@~/dotfiles/agents/rules/tdd.md`.

- **Modifying an existing rule**: Edit the rule file in `agents/rules/`, then run `~/dotfiles/install.sh` to push the change out to the installed files.
- **Adding a new rule**:
  1. Create the new markdown file in `agents/rules/` (e.g. `agents/rules/git-style.md`).
  2. Add `@~/dotfiles/agents/rules/git-style.md` to `agents/claude/CLAUDE.md`, `agents/antigravity/GEMINI.md` and `agents/opencode/AGENTS.md`.
  3. Run `~/dotfiles/install.sh` to push the new import line out. This overwrites the managed `CLAUDE.md` / `GEMINI.md` / `AGENTS.md`, which is safe by design — nothing local lives in them.

### Imports are inlined at install time

`@` imports are a feature of the agent, not of this repo, and whether a given agent resolves them is its own undocumented business. Claude Code does; Antigravity does not — it reads `GEMINI.md` literally, gets the string `@~/dotfiles/agents/rules/tdd.md`, and silently follows none of the rules. That failure is invisible: the file looks correct and the agent just quietly has no rules.

So `install.sh` doesn't rely on it for anyone. Every agent's instruction file is piped through `agents/expand-imports.sh`, which replaces every line that is nothing but `@path` with the contents of that path, and the *expanded* file is what gets installed. A path that doesn't exist on this machine becomes a one-line note rather than an error, so a machine without the optional private files still gets a usable file.

Because `local.md` is one of those imports, `install.sh` seeds it *before* installing the file that imports it — otherwise the first install on a new machine would inline a note saying the local file is absent.

The import lines stay in the tracked source files, so they remain the single place a rule is wired up. The trade-off is that each installed file is a snapshot: editing a rule, or your own `local.md`, needs another `install.sh` run to reach the agents.

If you'd rather have an agent resolve its own imports and pick up rule edits with no install step, pass `--no-expand` and the files are installed verbatim. It applies to every agent at once, so only use it if all of them support `@`.

```bash
$ ~/dotfiles/install.sh --no-expand
```

Tests live in `tests/` and need nothing installed — `install_test.sh` runs the real installer against a throwaway `$HOME`:

```bash
$ ~/dotfiles/tests/expand_imports_test.sh
$ ~/dotfiles/tests/install_test.sh
```

### Private context

This repo is public, so anything internal stays out of it. `CLAUDE.md` imports
extra files from `~/.claude/private/` with `@` lines; those files are not
version-controlled here and a missing one is harmless. To sync them across
machines, keep them in a private repo and symlink into `~/.claude/private/`.

Do not symlink `~/.claude` or `~/.gemini` directories themselves, and do not commit `~/.claude.json` — it contains MCP server config and may hold API tokens.
