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

## Claude Code

Claude Code keeps its config in `~/.claude`, but that directory also holds
session transcripts, caches, credentials, and mutable runtime state (such as
model selection and permission allowlists) which should not pollute the dotfiles
repository.

Baseline configurations live in `claude/` and are copied to `~/.claude/` during
setup so local runtime changes don't dirty the git working tree:

```
$ mkdir -p ~/.claude
$ cp ~/dotfiles/claude/settings.json ~/.claude/settings.json
$ cp ~/dotfiles/claude/CLAUDE.md ~/.claude/CLAUDE.md
$ cp -R ~/dotfiles/claude/commands ~/.claude/commands
```

`settings.json` holds preferences (model, effort level) and the permissions
allowlist. `CLAUDE.md` holds instructions that apply to every session in every
directory, such as working with TDD. `commands/` holds custom slash commands: a
file `foo.md` becomes `/foo`.

Note that `theme` is stored in `~/.claude.json`, not in `settings.json`, so it
does not travel and has to be set once per machine.

### Private context

This repo is public, so anything internal stays out of it. `CLAUDE.md` imports
extra files from `~/.claude/private/` with `@` lines; those files are not
version-controlled here and a missing one is harmless. To sync them across
machines, keep them in a private repo and symlink into `~/.claude/private/`.

Do not symlink `~/.claude` itself, and do not commit `~/.claude.json` (in the
home directory, not in `~/.claude`) — it contains MCP server config and may
hold API tokens.
