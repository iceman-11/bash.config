# FZF
# ---

# Setup fzf key bindings (not in mintty, where they do not work)
# ---------------------------------------------------------------
if [[ ${TERM_PROGRAM:-} != mintty ]] && type fzf > /dev/null 2>&1; then
	if __cache_output fzf fzf --bash 2> /dev/null; then
		# shellcheck source=/dev/null disable=SC2154 # set by __cache_output
		. "$__cache_file"
	else
		# fzf older than 0.48 has no --bash: use the key bindings the
		# distribution installs (Fedora/RHEL, Debian/Ubuntu, Arch)
		for __fzf_bindings in \
			/usr/share/fzf/shell/key-bindings.bash \
			/usr/share/doc/fzf/examples/key-bindings.bash \
			/usr/share/fzf/key-bindings.bash; do
			if [[ -r $__fzf_bindings ]]; then
				# shellcheck source=/dev/null
				. "$__fzf_bindings"
				break
			fi
		done
		unset __fzf_bindings
	fi
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
