################################################################################
# History
################################################################################

# Clean-up history file (deduplicate)
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

	# Deduplicate history, preserving timestamps
	tmpfile=$(mktemp "${HISTFILE}.XXXXXX")
	nl "$HISTFILE" | sort -rn | sort -uk2 | sort -nk1 | cut -f2- | \
		awk '/^#[0-9]+$/ { ts=$0; next } { if (ts) print ts; ts=""; if (NF) print }' > "$tmpfile"

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

################################################################################
