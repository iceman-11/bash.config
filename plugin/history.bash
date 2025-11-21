################################################################################
# History
################################################################################

# Clean-up history file
if [ "${-#*i}" != "$-" ]; then
	TMPFILE=$(mktemp)
	nl $HISTFILE | sort -rn | sort -uk2 | sort -nk1 | cut -f2- | \
		awk '/^#[0-9]+$/ { ts=$0; next } { if (ts) print ts; ts=""; if (NF) print }' > $TMPFILE
	cp $TMPFILE $HISTFILE
	rm $TMPFILE
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
