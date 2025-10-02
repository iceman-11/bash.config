################################################################################
# Shell prompt
################################################################################

function __jobs_ps1 {
	local job_count
	# Get the actual number of jobs
	job_count=$(jobs | wc -l)

	# Only display if there are jobs
	if [ "$job_count" -gt 0 ]; then
		printf " !%s" "$job_count"
	fi
}

function __virtual_env_ps1 {
	# Check if we're in a virtual environment
	if [ -n "$VIRTUAL_ENV" ]; then
		# Extract the virtual environment name from the path
		local virtual_env_name=$(basename "$VIRTUAL_ENV")
		printf " (%s)" "$virtual_env_name"
	fi
}

function __set_prompt {

	local __style_username=""
	local __style_at_symbol=""
	local __style_hostname=""
	local __style_path=""
	local __style_git=""
	local __style_virtual_env=""
	local __style_jobs=""
	local __style_time=""
	local __style_end=""
	local __style_reset=""

	# Jobs prompt
	local __prompt_jobs='$(__jobs_ps1)'

	# Git Prompt
	local __prompt_git
	if __git_ps1 &> /dev/null; then
		__prompt_git='$(__git_ps1 " [%s]")'
	fi

	# Virtual environment prompt
	local __prompt_virtual_env='$(__virtual_env_ps1)'

	# Check if stdout is a terminal...
	if test -t 1; then
		local __colors=$(tput colors)

		# See if it supports colors...
		if test -n "${__colors}" && test ${__colors} -ge 8; then

			__style_jobs="\[\e[0;31m\]"

			if [ $EUID -eq "0" ]; then
				# For root:
				__style_end="\[\e[0;31m\]"
			else
				# For normal users:
				__style_end="\[\e[0;32m\]"
			fi

			__style_username="\[\e[0;37m\]"
			__style_at_symbol="\[\e[0;90m\]"
			__style_hostname="\[\e[0;37m\]"
			__style_path="\[\e[0;90m\]"
			__style_git="\[\e[0;32m\]"
			__style_virtual_env="\[\e[0;93m\]"
			__style_time="\[\e[0;90m\]"
			__style_reset="\[\e[0m\]"
		fi
	fi

	# Initialize and set window title
	case $TERM in
		xterm* | screen* | rxvt | cygwin )
			PS1="\[\033]0;\u@\h:\w\007\]"
		;;

		* )
			PS1=""
		;;
	esac

	PS1+=$'\n'
	PS1+=${__style_username}"\u"${__style_reset}
	PS1+=${__style_at_symbol}"@"${__style_reset}
	PS1+=${__style_hostname}"\h"${__style_reset}
	PS1+=${__style_path}" \w"${__style_reset}
	PS1+=${__style_git}${__prompt_git}${__style_reset}
	PS1+=${__style_virtual_env}${__prompt_virtual_env}${__style_reset}
	PS1+=${__style_jobs}${__prompt_jobs}${__style_reset}
	PS1+=$'\n'
	PS1+=${__style_time}"\A "${__style_reset}
	PS1+=${__style_end}"\\$"${__style_reset}" "

}

# Disable default virtual environment prompt
export VIRTUAL_ENV_DISABLE_PROMPT=1

# Set theme
THEME="${XDG_CONFIG_HOME}/oh-my-posh/themes/iceman.omp.json"
if type oh-my-posh > /dev/null 2>&1 && [ -r $THEME ]; then
	eval "$(oh-my-posh init bash --config ${THEME})" 2> /dev/null
else
	__set_prompt
	export PS1
fi

# Configure PROMPT_COMMAND
function prompt_command {
	history -a  # Append new history lines to history file
	history -c  # Clear history
	history -r  # Reload history from history file

	# If running tmux and SSH_AUTH_SOCK is not a socket
	if [ -n "$TMUX" ] && [ ! -S "$SSH_AUTH_SOCK" ]; then
		# Refresh SSH_AUTH_SOCK
		eval "$(tmux show-environment -s SSH_AUTH_SOCK 2> /dev/null)"
	fi
}

# Add prompt_command, if it's not already there
if [[ "$PROMPT_COMMAND" != *"prompt_command"* ]]; then
	PROMPT_COMMAND="${PROMPT_COMMAND:+$PROMPT_COMMAND; }"
	PROMPT_COMMAND+="prompt_command"
fi

export PROMPT_COMMAND

# Clean-up
unset __set_prompt

################################################################################
