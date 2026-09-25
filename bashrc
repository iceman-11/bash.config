################################################################################
#
# Description:
# Personal .bashrc file
#
# Author: Stéphane LAMBERT
#
################################################################################

# Bail out early for non-interactive shells (e.g. login shells sourced by a
# display manager during graphical session start-up). Without this, the
# XAUTHORITY default and plugin side effects below (ssh-agent, tmux, ...) can
# run in that context and hang or break the session before the desktop ever
# appears.
case $- in
	*i*) ;;
	  *) return ;;
esac

export XDG_CONFIG_HOME=${XDG_CONFIG_HOME:=${HOME}/.config}
BASH_HOME="${XDG_CONFIG_HOME}/bash"

################################################################################
# Set XAUTHORITY
################################################################################

# Deliberate, do not remove: export the X cookie file explicitly. sudo
# (env_keep), su and sudo -E change HOME, so without this X clients run as
# root (e.g. after ssh -X then sudo -i) would look for the cookie in root's
# home instead of the calling user's. A value already set is kept.
export XAUTHORITY=${XAUTHORITY:=${HOME}/.Xauthority}

################################################################################
# Set UTF-8 locale
################################################################################

function __set_locale {
	local preference locale
	local -a locales

	# Keep a UTF-8 language set by the system, the terminal or a parent
	# shell; C.UTF-8 (the bare default of WSL and containers) is replaced
	case ${LANG,,} in
		c.* | posix.*) ;;
		*.utf8 | *.utf-8) return ;;
	esac

	mapfile -t locales < <(locale -a 2> /dev/null)

	# First available preference, in either spelling (en_US.utf8 on Linux,
	# en_US.UTF-8 elsewhere). Only LANG is set, so that LC_* settings still
	# apply: LC_ALL would override all of them.
	for preference in en_us en_gb c; do
		for locale in "${locales[@]}"; do
			case ${locale,,} in
				"${preference}.utf8" | "${preference}.utf-8")
					export LANG=$locale
					return
					;;
			esac
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

# The inherited PATH is never reordered: a nested shell, a tmux pane or a
# shell started from an activated venv keeps the order it was given.

### Home bin directories first, when the inherited PATH does not have them
for __dir in "${HOME}/bin" "${HOME}/.local/bin"; do
	case ":${PATH}:" in
		*":${__dir}:"*) ;;
		*) PATH="${__dir}:${PATH}" ;;
	esac
done
unset __dir

### Default PATH last, for the directories that are missing
PATH+=:/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin

### OS Specific PATH
case $OSTYPE in
	solaris* )
		PATH+=:/opt/sfw/bin:/usr/sfw/bin:/usr/sfw/sbin
	;;
esac

### Clean-up (duplicates, non-existent directories) and export PATH
__merge_paths "${PATH}"
export PATH

################################################################################
#
# Shell Options
#
################################################################################

set -o notify           # Report exit status of bg jobs immediately [-o]
set +o noclobber        # Allow to overwrite file with redirection [+o]
set +o ignoreeof        # Allow to exit with Ctrl-D [+o]
set +o nounset          # Allow undefined variables (-o: error on them) [+o]

shopt -s cdspell        # Correct misspelling of directory name
shopt -s checkhash      # Check the hash table before path search
shopt -s checkwinsize   # Update LINES and COLUMNS after each command

shopt -s mailwarn
shopt -s sourcepath     # The source built-in use PATH to find file
shopt -s extglob        # Useful for programmable completion

# Do not search $PATH on empty line completion
shopt -s no_empty_cmd_completion

################################################################################
#
# Source the scripts in plugin and local
#
################################################################################

BASH_CACHE="${XDG_CACHE_HOME:-${HOME}/.cache}/bash"

# Cache the output of a slow command that generates shell code, e.g.
# "fzf --bash". Usage from a plugin:
#
#   __cache_output NAME CMD [ARGS...] && . "$__cache_file"
#
# The output is stored in $BASH_CACHE/NAME.bash and regenerated when CMD is
# replaced or updated, or after a week. The caller sources the file itself:
# sourcing it from inside this function would make its 'declare's local.
function __cache_output {
	local name=$1 bin stamp cached_bin cached_cmd now
	shift

	__cache_file="${BASH_CACHE}/${name}.bash"
	# Resolve CMD through the hash table: no subshell
	hash "$1" 2> /dev/null || return 1
	bin=${BASH_CMDS[$1]}
	printf -v now '%(%s)T' -1

	# Header of the cache: "# <creation time> <path of CMD>", then
	# "# <command line>" (a changed argument must regenerate it)
	{ { read -r _ stamp cached_bin; read -r cached_cmd; } < "$__cache_file"; } 2> /dev/null

	if [[ $cached_bin == "$bin" && $cached_cmd == "# $*" && $stamp =~ ^[0-9]+$ ]] &&
		(( now - stamp < 7 * 24 * 3600 )) && [[ ! $bin -nt $__cache_file ]]; then
		return 0
	fi

	mkdir -p "$BASH_CACHE" || return 1
	{ echo "# $now $bin"; echo "# $*"; "$@"; } > "${__cache_file}.$$" &&
		mv -f "${__cache_file}.$$" "$__cache_file" ||
		{ rm -f "${__cache_file}.$$"; return 1; }
}

# Clear the cache used by __cache_output (e.g. after changing a tool's setup)
function bash_cache_clear {
	rm -f "${BASH_CACHE}"/*.bash
}

# Plugins are sourced at the top level (not from a function), so that a
# 'declare' in a plugin creates a global variable
for __plugin in "${BASH_HOME}"/{init,init/local,plugin,plugin/local,post,post/local}/*.bash; do
	if [[ -r $__plugin ]]; then
		# shellcheck source=/dev/null
		. "$__plugin"
	fi
done

unset __plugin __cache_file

################################################################################
# Clean-up functions
################################################################################

unset -f __set_locale
unset -f __merge_paths
unset -f __cache_output

################################################################################
