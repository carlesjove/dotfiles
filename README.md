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
$ ls -s ~/dotfiles/gitconfig ~/.gitconfig
```

After doing this you should open vim and run `PlugInstall`.
