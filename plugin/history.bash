################################################################################
# History
################################################################################

# Clean-up history file: remove duplicate entries, keeping the newest copy.
# An entry is a "#<timestamp>" line and the command lines that follow it
# (several for a multi-line command); lines without a timestamp, written
# before HISTTIMEFORMAT was set, are one entry each.
__cleanup_history() {
	[ -n "$HISTFILE" ] && [ -f "$HISTFILE" ] || return 0

	local lockdir="${HISTFILE}.lock"
	local tmpfile

	# Remove stale lock older than 60 seconds
	if [ -d "$lockdir" ]; then
		find "$lockdir" -maxdepth 0 -mmin +1 -exec rmdir {} \; 2>/dev/null
	fi

	# Try to acquire lock
	mkdir "$lockdir" 2>/dev/null || return 0
	trap 'rmdir "$lockdir" 2>/dev/null' EXIT

	# Deduplicate history by entry, in one process
	tmpfile=$(mktemp "${HISTFILE}.XXXXXX")
	awk '
		# Store the entry being read; the last copy of each text wins
		function flush() {
			if (n) { text[++count] = cmd; stamp[count] = ts; last[cmd] = count }
			n = 0; cmd = ""; ts = ""
		}
		/^#[0-9]+$/ { flush(); ts = $0; next }
		ts == "" { flush(); if (NF) { cmd = $0; n = 1; flush() }; next }
		{ cmd = n++ ? cmd "\n" $0 : $0 }
		END {
			flush()
			for (i = 1; i <= count; i++) {
				if (last[text[i]] != i) continue
				if (stamp[i] != "") print stamp[i]
				print text[i]
			}
		}' "$HISTFILE" > "$tmpfile"

	# Only replace if result is non-empty
	if [ -s "$tmpfile" ]; then
		mv "$tmpfile" "$HISTFILE"
	else
		rm -f "$tmpfile"
	fi

	# Release lock
	rmdir "$lockdir" 2>/dev/null
	trap - EXIT
}

# Run the clean-up at most once a day: it starts several processes, which is
# slow on Git Bash. The time of the last run is kept next to the history file.
if [[ -n $HISTFILE ]]; then
	__history_stamp="${HISTFILE}.cleaned"
	__history_last=
	{ read -r __history_last < "$__history_stamp"; } 2> /dev/null
	printf -v __history_now '%(%s)T' -1

	if [[ ! $__history_last =~ ^[0-9]+$ ]] || (( __history_now - __history_last >= 24 * 3600 )); then
		__cleanup_history && echo "$__history_now" > "$__history_stamp"
	fi

	unset __history_stamp __history_last __history_now
fi

# Try to save multiple lines cmd to one history entry
shopt -s cmdhist

# If cmdhist is set use newline in the HISTFILE
shopt -s lithist

# Append to HISTFILE rather than overwriting it
shopt -s histappend

# Allow to re-edit a failed history substitution
shopt -s histreedit

# Maximum number of history lines in memory
export HISTSIZE=50000

# Maximum number of history lines on disk
export HISTFILESIZE=50000

# Ignore duplicate lines
export HISTCONTROL=ignoreboth:erasedups

# Write a "#<timestamp>" line before each entry in HISTFILE. With lithist,
# bash then reloads a multi-line command as one entry, not one per line. The
# format is empty, so 'history' does not show the time. A value already set
# is kept.
export HISTTIMEFORMAT=${HISTTIMEFORMAT-}

################################################################################
