# FZF
# ---

# Exit if on 'mintty'
# -------------------
if [[ ${TERM_PROGRAM} == 'mintty' ]]; then
	return
fi

# Setup fzf
# ---------
if __cache_output fzf fzf --bash; then
	# shellcheck source=/dev/null disable=SC2154 # set by __cache_output
	. "$__cache_file"
fi

# Use fd with fzf
# ---------------
if type fd > /dev/null 2>&1; then
	export FZF_DEFAULT_COMMAND='fd --type f --strip-cwd-prefix'
	export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
	export FZF_ALT_C_COMMAND='fd --type d --strip-cwd-prefix'
fi

# Use tree with fzf
# -----------------
if type tree > /dev/null 2>&1; then
	export FZF_ALT_C_OPTS="--preview 'tree -C {} | head -200'"
fi
