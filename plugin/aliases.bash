################################################################################
#
# Aliases and Functions
#
################################################################################

################################################################################
# Aliases
################################################################################

#alias grh='history | grep'

alias which='type -all'
alias path='echo -e ${PATH//:/\\n}'
alias disp='echo $DISPLAY'

if type cygpath > /dev/null 2>&1; then
	alias winpwd='cygpath -w $(pwd)'
fi

# The 'ls' family ##############################################################

if [ -x /usr/bin/dircolors ]; then
	test -r "${HOME}/.dircolors" && eval $(dircolors -b "${HOME}/.dircolors") || eval $(dircolors -b)
fi

if ls --color=auto -d > /dev/null 2>&1; then
	alias ls='ls --color=auto'
fi

alias la='ls -Al'           # Show hidden files
alias ll='ls -l'            # Use long format
alias lr='ls -lR'           # Recursive ls
alias lt='ls -ltr'          # Sort by date

# The 'grep' family ############################################################

if (echo a | grep --color=auto a) > /dev/null 2>&1; then
	alias grep='grep --color=auto'
fi

if (echo a | fgrep --color=auto a) > /dev/null 2>&1; then
	alias fgrep='fgrep --color=auto'
fi

if (echo a | egrep --color=auto a) > /dev/null 2>&1; then
	alias egrep='egrep --color=auto'
fi

################################################################################
# Functions
################################################################################

# Grep from history

function hgrep () {

	builtin history | grep "$@"
}

# X-Windows title

function xtitle () {

	case $TERM in
		xterm* | screen* | rxvt | cygwin )
			echo -e -n "\033]0;$*\007"
		;;
	esac
}

# Misc.

function man () {

	xtitle The $(basename ${@:$#} | tr -d .[:digit:]) manual
	command man "$@"
}

function where() {

	which $1 2> /dev/null | head -1 | sed 's/^[^/]*//'
}

################################################################################
