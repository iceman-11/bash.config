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

XDG_CONFIG_HOME=${XDG_CONFIG_HOME:=${HOME}/.config}
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

LOCALE="C.UTF-8"

if locale -a | grep $LOCALE > /dev/null 2>&1; then
	export LANG=$LOCALE
fi

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

	local oifs=$IFS
	IFS=$'\n'

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

	IFS=$oifs
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
PATH=$(__merge_paths ${PATH}:${HOME}/bin)
export PATH

################################################################################
#
# Source the scripts in plugin and local
#
################################################################################

# For generic plugins
for script in "${BASH_HOME}"/plugin/*.bash ; do
	if [ -r "$script" ]; then
		if [ "${-#*i}" != "$-" ]; then
			. "$script"
		else
			. "$script" > /dev/null 2>&1
		fi
	fi
done

# For plugins local to this computer
for script in "${BASH_HOME}"/local/*.bash ; do
	if [ -r "$script" ]; then
		if [ "${-#*i}" != "$-" ]; then
			. "$script"
		else
			. "$script" > /dev/null 2>&1
		fi
	fi
done

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

unset __merge_paths
unset __set_display

################################################################################
