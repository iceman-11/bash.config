################################################################################
#
# Description:
# Personal .bashrc file
#
# Author: Stéphane LAMBERT
#
################################################################################

# Bail out early for non-interactive shells (e.g. login shells sourced by a
# display manager during graphical session start-up). Without this, DISPLAY/
# XAUTHORITY overrides and plugin side effects below can run in that context
# and hang or break the session before the desktop ever appears.
case $- in
	*i*) ;;
	  *) return ;;
esac

export XDG_CONFIG_HOME=${XDG_CONFIG_HOME:=${HOME}/.config}
BASH_HOME="${XDG_CONFIG_HOME}/bash"

# Setup DISPLAY ################################################################

function __set_display() {
	local host

	if [[ -t 0 ]] && [ ! "$DISPLAY" ]; then
		host=$(who -m | awk '{print $6}' | sed 's/^(//; s/)$//')
		export DISPLAY="${host}:0.0"
	fi
}

__set_display

################################################################################
# Set XAUTHORITY
################################################################################

export XAUTHORITY=${XAUTHORITY:=${HOME}/.Xauthority}

################################################################################
# Set UTF-8 locale
################################################################################

function __set_locale {
	local preference locale
	local -a locales

	# Already set up by a parent shell: nothing to do
	case ${LC_ALL,,} in
		*.utf8 | *.utf-8) return ;;
	esac

	mapfile -t locales < <(locale -a 2> /dev/null)

	for preference in en_US.utf8 en_GB.utf8 C.utf8; do
		for locale in "${locales[@]}"; do
			if [[ $locale == "$preference" ]]; then
				export LANG=$locale
				export LC_ALL=$locale
				return
			fi
		done
	done
}

__set_locale

################################################################################
#
# Setup PATH
#
################################################################################

# Set PATH to the existing directories of $1, keeping the first occurrence of
# each (no subshell: a fork is slow on Windows)
function __merge_paths {
	local dir path=
	local -a dirs
	local -A seen=()

	IFS=: read -ra dirs <<< "$1"

	for dir in "${dirs[@]}"; do
		# Skip empty entries, duplicates and non-existent directories
		if [[ -z $dir || -n ${seen[$dir]:-} || ! -d $dir ]]; then
			continue
		fi

		seen[$dir]=1
		path+=${path:+:}$dir
	done

	PATH=$path
}

### Default PATH
PATH=/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin:${PATH}

### OS Specific PATH
case $OSTYPE in
	solaris* )
		PATH+=:/opt/sfw/bin:/usr/sfw/bin:/usr/sfw/sbin
	;;
esac

### Add home directory, clean-up and export PATH
__merge_paths "${PATH}:${HOME}/.local/bin:${HOME}/bin"
export PATH

################################################################################
#
# Source the scripts in plugin and local
#
################################################################################

# Plugins are sourced at the top level (not from a function), so that a
# 'declare' in a plugin creates a global variable
for __plugin in "${BASH_HOME}"/{init,init/local,plugin,plugin/local,post,post/local}/*.bash; do
	if [[ -r $__plugin ]]; then
		# shellcheck source=/dev/null
		. "$__plugin"
	fi
done

unset __plugin

################################################################################
#
# Shell Options
#
################################################################################

set -o notify           # Report exit status of bg jobs immediately [-o]
set +o noclobber        # Allow to overwrite file with redirection [+o]
set +o ignoreeof        # Allow to exit with Ctrl-D [+o]
set +o nounset          # Error when using an undefined variable [-o]

shopt -s cdspell        # Correct misspelling of directory name
shopt -s checkhash      # Check the hash table before path search
shopt -s dotglob        # Add files beginning with . in the pathname completion
shopt -s checkwinsize   # Update LINES and COLUMNS after each command

shopt -s mailwarn
shopt -s sourcepath     # The source built-in use PATH to find file
shopt -s extglob        # Useful for programmable completion

# Do not search $PATH on empty line completion
shopt -s no_empty_cmd_completion

################################################################################
# Clean-up functions
################################################################################

unset -f __set_locale
unset -f __merge_paths
unset -f __set_display

################################################################################
