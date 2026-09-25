# Zoxide
# ------

if __cache_output zoxide zoxide init bash; then
	# shellcheck source=/dev/null disable=SC2154 # set by __cache_output
	. "$__cache_file"
	alias cd='z'
else
	alias z='cd'
fi
