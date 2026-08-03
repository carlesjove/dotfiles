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
$ ln -s ~/dotfiles/vimrc ~/.vimrc
$ ln -s ~/dotfiles/vimrc.bundles ~/.vimrc.bundles
$ ln -s ~/dotfiles/gitconfig ~/.gitconfig
$ ln -s ~/dotfiles/psqlrc ~/.psqlrc
```

After doing this you should open vim and run `PlugInstall`.

## Claude Code

Claude Code keeps its config in `~/.claude`, but that directory also holds
session transcripts, caches and credentials, which must never be committed.
So only the portable bits live here, in `claude/`, and get symlinked
individually:

```
$ ln -s ~/dotfiles/claude/settings.json ~/.claude/settings.json
$ ln -s ~/dotfiles/claude/CLAUDE.md ~/.claude/CLAUDE.md
$ ln -s ~/dotfiles/claude/commands ~/.claude/commands
```

`settings.json` holds preferences (model, effort level) and the permissions
allowlist. `CLAUDE.md` holds instructions that apply to every session in every
directory, such as working with TDD. `commands/` holds custom slash commands: a
file `foo.md` becomes `/foo`.

Note that `theme` is stored in `~/.claude.json`, not in `settings.json`, so it
does not travel and has to be set once per machine.

Do not symlink `~/.claude` itself, and do not commit `~/.claude.json` (in the
home directory, not in `~/.claude`) — it contains MCP server config and may
hold API tokens.
