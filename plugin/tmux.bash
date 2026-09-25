# Exit if tmux is not installed
if ! type tmux > /dev/null 2>&1; then
	return
fi

# Exit if already inside a tmux session
if [[ -n "$TMUX" ]]; then
	return
fi

function __display_tmux_sessions() {
	local sessions name windows plural
	sessions=$(tmux ls -F '#{session_name}:#{session_windows}' 2>/dev/null)

	if [[ -n "$sessions" ]]; then
		printf '\033[0;96m◉ tmux\033[0m\n'
		while IFS=: read -r name windows; do
			plural=s
			(( windows == 1 )) && plural=
			# printf, not echo -e: a backslash in a session name stays as is
			printf '  \033[0;32m→\033[0m \033[1;37m%s\033[0m \033[0;90m(%s window%s)\033[0m\n' \
				"$name" "$windows" "$plural"
		done <<< "$sessions"
	fi
}

__display_tmux_sessions

unset __display_tmux_sessions
