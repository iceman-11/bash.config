################################################################################
#
# Decription :
# Personal .bashrc file
#
# Author     : Stéphane Lambert
#
################################################################################

NO_TTY=`tty > /dev/null 2>&1; echo $?`
OS=$(uname)

export XDG_CONFIG_HOME=${XDG_CONFIG_HOME:=${HOME}/.config}
BASH_HOME="${XDG_CONFIG_HOME}/bash"

# Setup DISPLAY ################################################################

function __set_display() {
	if [ $NO_TTY = "0" ] && [ ! "$DISPLAY" ]; then
		export DISPLAY=$(echo -n `who -m | awk '{print $6}' | sed 's/^(//; s/)$//'`:0.0)
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

LOCALE_PREFERENCES=("en_US.utf8" "en_GB.utf8" "C.utf8")
ALL_LOCALES=$(locale -a 2> /dev/null)

function __get_locale {
	local matching_locales match_result
	matching_locales=$(printf '%s\n' $ALL_LOCALES | grep -E "\<($1)\>")
	match_result=$?

	printf '%s\n' $matching_locales | head -1
	return $match_result
}

for locale_preference in ${LOCALE_PREFERENCES[@]}; do
	locale=$(__get_locale $locale_preference)
	result=$?

	if [ $result -eq 0 ]; then
			export LANG=$locale
			export LC_ALL=$locale
			break
	fi
done

################################################################################
#
# Setup PATH
#
################################################################################

function __merge_paths {

	# Process function's arguments
	local args=$(echo $* | command -p awk '{if (! a[$1]++) print $1}' FS=\\n RS=:)

	local dir
	local path

	local IFS=$'\n'

	for dir in ${args}; do

		# Skip non-existent directories
		if [ -z $dir ] || ! [ -d "$dir" ]; then
			continue
		fi

		# Add directory to the path variable
		if [ -z "${path}" ]; then
			path="${dir}"
		else
			path+=":${dir}"
		fi
	done

	echo $path
}

### Default PATH
PATH=/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin:${PATH}

### OS Specific PATH
case $OS in
	'SunOS' )
		PATH+=:/opt/sfw/bin:/usr/sfw/bin:/usr/sfw/sbin
	;;
esac

### Add home directory, clean-up and export PATH
PATH=$(__merge_paths ${PATH}:${HOME}/.local/bin:${HOME}/bin)
export PATH

################################################################################
#
# Source the scripts in plugin and local
#
################################################################################

PLUGINS=$(ls -1U ${BASH_HOME}/{init,plugin,local}/*.bash 2> /dev/null)

function __source_plugins {
	local oifs=$IFS
	local IFS=$'\n'

	for script in $PLUGINS; do
		if [ -r "$script" ]; then
			local IFS=$oifs
			if [ "${-#*i}" != "$-" ]; then
				. "$script"
			else
				. "$script" > /dev/null 2>&1
			fi
		fi
	done

	return 0
}

__source_plugins

################################################################################
#
# Shell Options
#
################################################################################

set -o notify           # Report exit status of bg jobs immediatly [-o]
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

unset __get_locale
unset __merge_paths
unset __set_display
unset __source_plugins

################################################################################
