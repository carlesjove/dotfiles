[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# modify the prompt to contain git branch name if applicable
git_prompt_info() {
  current_branch=$(git branch --show-current 2> /dev/null)
  if [[ -n $current_branch ]]; then
    # \e[0;32m Start color, where 32 is green
    # \e[0m    End color
    # Info: https://en.wikipedia.org/wiki/ANSI_escape_code
    # echo "\e[0;32m($current_branch)\e[0m"
    echo "($current_branch)"
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

## Default prompt
# PS1="%n@%m %1~ %# "
# %~ Current directory, same as PWD. With a number it can be specified how many
#    levels back to display. Ex: %2~ shows parent/child
# %n Current user
# %m Name of the computer (?)
# PS1='$(get_current_dir) $(git_prompt_info) %# '
PS1='%2~ $(git_prompt_info) %# '

# Rbenv: Ruby version manager
eval "$(rbenv init -)"

# Pyenv: Python version manager
if command -v pyenv 1>/dev/null 2>&1; then
  eval "$(pyenv init -)"
fi

# aliases
[[ -f ~/.aliases ]] && source ~/.aliases

# if [ -f ~/.git-completion.bash ]; then
#   source ~/.git-completion.bash
# fi
zstyle ':completion:*:*:git:*' script ~/.git-completion.zsh


# Node version manager
export NVM_DIR="$HOME/.nvm"
source "$NVM_DIR/nvm.sh"
# [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
# [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/carles/google-cloud-sdk/path.zsh.inc' ]; then . '/Users/carles/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/Users/carles/google-cloud-sdk/completion.zsh.inc' ]; then . '/Users/carles/google-cloud-sdk/completion.zsh.inc'; fi

export PATH="$HOME/.poetry/bin:$PATH"
