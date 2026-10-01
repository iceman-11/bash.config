################################################################################
#
# Description:
# Personal .bashrc file
#
# Author: Stéphane LAMBERT
#
################################################################################

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

# Add folders to PATH; for plugins (including local/ ones) and at the prompt,
# so they are kept after loading:
#
#   path_prepend DIR...   in front of PATH, in the order given
#   path_append DIR...    at the end of PATH, in the order given
#
# A folder that does not exist is skipped. path_append never moves a folder
# already in PATH. path_prepend moves it to the front, except while a shell
# loads a PATH already arranged by a parent shell running this configuration
# (BASHRC_PATH_READY, exported at the end of this file): a nested shell, a
# tmux pane or a shell started from an activated venv keeps the order it was
# given, so the venv stays first. They change PATH directly (no subshell):
# call them as commands, not as $(...).
function path_prepend {
	local dir i rest

	for (( i = $#; i > 0; i-- )); do
		dir=${!i}
		[[ -d $dir ]] || continue
		case ":${PATH}:" in
			*":${dir}:"*)
				[[ -n ${__path_keep_order:-} ]] && continue

				# Move it: remove every copy, then add it in front
				rest=":${PATH}:"
				while [[ $rest == *":${dir}:"* ]]; do
					rest=${rest/":${dir}:"/:}
				done
				rest=${rest#:}
				rest=${rest%:}
				PATH=${dir}${rest:+:${rest}}
				;;
			*)
				PATH=${dir}${PATH:+:${PATH}}
				;;
		esac
	done
}

function path_append {
	local dir

	for dir in "$@"; do
		[[ -d $dir ]] || continue
		case ":${PATH}:" in
			*":${dir}:"*) ;;
			*) PATH=${PATH:+${PATH}:}${dir} ;;
		esac
	done
}

# A PATH already arranged by a parent shell running this configuration is not
# reordered while loading (see path_prepend)
if [[ -n ${BASHRC_PATH_READY:-} ]]; then
	__path_keep_order=1
fi

### Home bin directories first (moved there, unless PATH was already arranged)
path_prepend "${HOME}/.local/bin" "${HOME}/bin"

### Default PATH last, for the directories that are missing
path_append /usr/local/bin /usr/bin /bin /usr/local/sbin /usr/sbin /sbin

### OS Specific PATH
case $OSTYPE in
	solaris* )
		path_append /opt/sfw/bin /usr/sfw/bin /usr/sfw/sbin
	;;
esac

### Clean-up of the inherited PATH (duplicates, non-existent directories)
### and export
__merge_paths "${PATH}"
export PATH

################################################################################
# Stop here for non-interactive shells
################################################################################

# Bail out early for non-interactive shells (e.g. login shells sourced by a
# display manager during graphical session start-up). Without this, the
# XAUTHORITY default and plugin side effects below (ssh-agent, tmux, ...) can
# run in that context and hang or break the session before the desktop ever
# appears.
#
# PATH is set up above on purpose: it only uses built-ins, and commands run
# without a prompt need it too (e.g. 'sudo -i pihole -up', whose secure_path
# lacks /usr/local/bin, or 'ssh host cmd' for a tool in ~/.local/bin).
case $- in
	*i*) ;;
	  *)
		unset __path_keep_order
		unset -f __merge_paths
		return
		;;
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
	local preference locale var key
	local -a locales lc_vars=()
	local -A installed=()

	# Categories set one by one (e.g. by KDE Plasma's formats, or sent by an
	# SSH client); LC_ALL is never set by this configuration
	for var in LC_CTYPE LC_NUMERIC LC_TIME LC_COLLATE LC_MONETARY LC_MESSAGES \
		LC_PAPER LC_NAME LC_ADDRESS LC_TELEPHONE LC_MEASUREMENT LC_IDENTIFICATION; do
		[[ -n ${!var:-} ]] && lc_vars+=("$var")
	done

	# Nothing to check or choose (no process started): a UTF-8 LANG other
	# than C.UTF-8, set by the system, the terminal or a parent shell, and no
	# LC_* variable. Such a LANG is trusted: checking it would cost a process
	# at every start-up (slow on Git Bash); it is checked below when the
	# locale list is read anyway.
	case ${LANG,,} in
		c.* | posix.*) ;;
		*.utf8 | *.utf-8) (( ${#lc_vars[@]} )) || return ;;
	esac

	mapfile -t locales < <(locale -a 2> /dev/null)

	# Installed locales, named the way glibc compares them: en_GB.UTF-8 is
	# listed as en_GB.utf8 (case and '-' in the codeset do not matter)
	for locale in "${locales[@]}"; do
		[[ -n $locale ]] || continue
		key=${locale,,}
		installed[${key//-/}]=1
	done

	# Without a list of installed locales (e.g. musl), nothing can be checked
	(( ${#installed[@]} )) || return 0

	# An LC_* variable naming a locale that is not installed (e.g. en_BE.UTF-8,
	# which KDE offers but glibc does not have) makes programs warn (perl) or
	# fall back to C: drop it, so that the category follows LANG
	for var in "${lc_vars[@]}"; do
		key=${!var,,}
		[[ -n ${installed[${key//-/}]:-} ]] || unset "$var"
	done

	# Keep a UTF-8 LANG that is installed, except C.UTF-8
	case ${LANG,,} in
		c.* | posix.*) ;;
		*.utf8 | *.utf-8)
			key=${LANG,,}
			[[ -n ${installed[${key//-/}]:-} ]] && return
			;;
	esac

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

# PATH is arranged (home folders, system folders, plugins): shells started
# from this one keep its order while loading. At the prompt, path_prepend
# moves folders again.
export BASHRC_PATH_READY=1
unset __path_keep_order

################################################################################
# Clean-up functions
################################################################################

unset -f __set_locale
unset -f __merge_paths
unset -f __cache_output

################################################################################
