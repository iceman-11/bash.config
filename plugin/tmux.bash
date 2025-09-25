# Exit if tmux is not installed
if ! type tmux > /dev/null 2>&1; then
	return
fi

# Exit if already inside a tmux session
if [[ -n "$TMUX" ]]; then
    return
fi

function __display_tmux_sessions() {
	local sessions=$(tmux ls -F '#{session_name}:#{session_windows}' 2>/dev/null)

	if [[ -n "$sessions" ]]; then
		echo -e "\033[0;96m◉ tmux\033[0m"
		while IFS=: read -r name windows; do
			echo -e "  \033[0;32m→\033[0m \033[1;37m$name\033[0m \033[0;90m($windows windows)\033[0m"
		done <<< "$sessions"
	fi
}

__display_tmux_sessions

unset __display_tmux_sessions
