[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# modify the prompt to contain git branch name if applicable
git_prompt_info() {
  current_branch=$(git branch 2> /dev/null | tr -d '* ' )
  if [[ -n $current_branch ]]; then
    # \e[0;32m Start color, where 32 is green
    # \e[0m    End color
    # Info: https://en.wikipedia.org/wiki/ANSI_escape_code
    echo "\e[0;32m($current_branch)\e[0m"
  fi
}

get_current_dir() {
  # %~ Current directory, same as PWD. With a number it can be specified how many
  #    levels back to display. Ex: %2~ shows parent/child
  # \e[0;32m Start color, where 32 is green
  # \e[0m    End color
  # Info: https://en.wikipedia.org/wiki/ANSI_escape_code
  echo "\e[0;90m%2~\e[0m"
}

# Allow exported PS1 variable to override default prompt.
setopt PROMPT_SUBST

# %~ Current directory, same as PWD. With a number it can be specified how many
#    levels back to display. Ex: %2~ shows parent/child
# %n Current user
# %m Name of the computer (?)
PS1='$(get_current_dir) $(git_prompt_info) %# '

# Pyenv
if command -v pyenv 1>/dev/null 2>&1; then
  eval "$(pyenv init -)"
fi

# aliases
[[ -f ~/.aliases ]] && source ~/.aliases
