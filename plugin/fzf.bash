# FZF
# ---

FZF_HOME="${HOME}/.fzf"

if [[ ! -d "${FZF_HOME}" ]]; then
  return
fi

# Exit if on 'mintty'
# -------------------
if [[ ${TERM_PROGRAM} == 'mintty' ]]; then
  return
fi

# Setup fzf
# ---------
if [[ ! "$PATH" == *${HOME}/.fzf/bin* ]]; then
  export PATH="${PATH:+${PATH}:}${HOME}/.fzf/bin"
fi

# Auto-completion
# ---------------
[[ $- == *i* ]] && source "${HOME}/.fzf/shell/completion.bash" 2> /dev/null

# Key bindings
# ------------
source "${HOME}/.fzf/shell/key-bindings.bash"
