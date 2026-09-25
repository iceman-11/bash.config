# Zoxide
# ------

# With zoxide, cd jumps to the best match when the folder is not found
# (by choice); '--cmd cd' makes cd and cdi zoxide functions, the supported
# way, instead of an alias. z stays available as the same command.
if __cache_output zoxide zoxide init bash --cmd cd; then
	# shellcheck source=/dev/null disable=SC2154 # set by __cache_output
	. "$__cache_file"
fi

alias z='cd'
