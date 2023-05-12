################################################################################
#
# Coniguration for Vim/Vi
#
################################################################################

# Environment

if type nvim > /dev/null 2>&1; then
	export EDITOR='nvim'
elif type vimx > /dev/null 2>&1; then
	export EDITOR='vimx'
elif type vim > /dev/null 2>&1; then
	export EDITOR='vim'
else
	export EDITOR='vi'
fi

# Aliases

if type sudo > /dev/null 2>&1; then
	alias svi='sudo -e'
fi

if type nvim > /dev/null 2>&1; then
	alias vi='nvim'
	alias view='nvim -R'
elif type vimx > /dev/null 2>&1; then
	alias vi='vimx'
	alias view='vimx -R'
elif type vim > /dev/null 2>&1; then
	alias vi='vim'
	alias view='vim -R'
fi

################################################################################
