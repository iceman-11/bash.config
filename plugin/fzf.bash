# FZF
# ---

# Exit if on 'mintty'
# -------------------
if [[ ${TERM_PROGRAM} == 'mintty' ]]; then
  return
fi

# Setup fzf
# ---------
if type fzf > /dev/null 2>&1; then
  eval "$(fzf --bash)"
fi

# Use fd with fzf
# ---------------
if type fd > /dev/null 2>&1; then
  export FZF_DEFAULT_COMMAND='fd --type f --strip-cwd-prefix'
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
fi
