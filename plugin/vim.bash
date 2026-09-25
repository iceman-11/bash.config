################################################################################
#
# Configuration for Vim/Vi
#
################################################################################

# Environment: the first editor found, for EDITOR and VISUAL (some tools,
# like crontab -e or less's 'v', read VISUAL first)

for __editor in nvim vimx vim vi; do
	type "$__editor" > /dev/null 2>&1 && break
done

export EDITOR=$__editor
export VISUAL=$__editor

# Aliases

if type sudo > /dev/null 2>&1; then
	alias svi='sudo -e'
fi

# The editor's name is expanded now, on purpose (SC2139)
# shellcheck disable=SC2139
if [[ $__editor != vi ]]; then
	alias vi="$__editor"
	alias view="$__editor -R"
	alias vimdiff="$__editor -d"
fi

unset __editor

################################################################################
