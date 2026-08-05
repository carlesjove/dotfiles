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

After doing this you should open vim and run `PlugInstall`.

## AI Agents (`agents/`)

AI coding assistant configurations live under `agents/` to keep root clean and modular:

- `agents/rules/`: Shared, agent-agnostic guidelines (e.g. `tdd.md`).
- `agents/claude/`: Claude Code specific configuration (`CLAUDE.md`, `settings.json`, `commands/`).
- `agents/antigravity/`: Antigravity specific configuration (`GEMINI.md`).

To prevent runtime state changes (such as model selection or permission allowlists) from polluting the dotfiles git repository, baseline files are copied to local environment directories during setup:

```
# Claude Code setup
$ mkdir -p ~/.claude
$ cp ~/dotfiles/agents/claude/settings.json ~/.claude/settings.json
$ cp ~/dotfiles/agents/claude/CLAUDE.md ~/.claude/CLAUDE.md
$ cp -R ~/dotfiles/agents/claude/commands ~/.claude/commands

# Antigravity setup
$ mkdir -p ~/.gemini
$ cp ~/dotfiles/agents/antigravity/GEMINI.md ~/.gemini/GEMINI.md
```

`agents/rules/tdd.md` holds universal TDD guidelines and is imported by both `CLAUDE.md` and `GEMINI.md` via `@` import lines.

### Private context

This repo is public, so anything internal stays out of it. `CLAUDE.md` imports
extra files from `~/.claude/private/` with `@` lines; those files are not
version-controlled here and a missing one is harmless. To sync them across
machines, keep them in a private repo and symlink into `~/.claude/private/`.

Do not symlink `~/.claude` or `~/.gemini` directories themselves, and do not commit `~/.claude.json` — it contains MCP server config and may hold API tokens.
