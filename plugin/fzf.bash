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
if [[ ! "$PATH" == *${FZF_HOME}/bin* ]]; then
  export PATH="${PATH:+${PATH}:}${FZF_HOME}/bin"
fi

# Auto-completion
# ---------------
[[ $- == *i* ]] && source "${FZF_HOME}/shell/completion.bash" 2> /dev/null

# Key bindings
# ------------
source "${FZF_HOME}/shell/key-bindings.bash"
