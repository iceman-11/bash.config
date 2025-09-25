################################################################################
# Shell prompt
################################################################################

function __jobs_ps1 {
	local job_count
	# Get the actual number of jobs
	job_count=$(jobs | wc -l)

	# Only display if there are jobs
	if [ "$job_count" -gt 0 ]; then
		printf "!%s" "$job_count"
	fi
}

function __set_prompt {

	local __prompt_colors __prompt_jobs_style __prompt_jobs_flag
	local __prompt_username_style __prompt_at_symbol_style __prompt_hostname_style
	local __prompt_path_style __prompt_end_style __prompt_reset_colors
	local __prompt_git_style __prompt_time_style __prompt_git_ps1

	# Jobs prompt
	__prompt_jobs_flag='$(__jobs_ps1)'

	# Git Prompt
	if __git_ps1 &> /dev/null; then
		__prompt_git_ps1='$(__git_ps1 " [%s] ")'
	fi

	# Check if stdout is a terminal...
	if test -t 1; then

		__prompt_colors=$(tput colors)

		# See if it supports colors...
		if test -n "${__prompt_colors}" && test ${__prompt_colors} -ge 8; then

			__prompt_jobs_style="\[\e[0;31m\]"

			if [ $EUID -eq "0" ]; then
				# For root:
				__prompt_end_style="\[\e[0;31m\]"
			else
				# For normal users:
				__prompt_end_style="\[\e[0;32m\]"
			fi

			__prompt_username_style="\[\e[0;37m\]"
			__prompt_at_symbol_style="\[\e[0;90m\]"
			__prompt_hostname_style="\[\e[0;37m\]"
			__prompt_path_style="\[\e[0;90m\]"
			__prompt_git_style="\[\e[0;32m\]"
			__prompt_time_style="\[\e[0;90m\]"
			__prompt_reset_colors="\[\e[0m\]"
		else

			__prompt_jobs_style=""
			__prompt_end_style=""
			__prompt_username_style=""
			__prompt_at_symbol_style=""
			__prompt_hostname_style=""
			__prompt_path_style=""
			__prompt_git_style=""
			__prompt_time_style=""
			__prompt_reset_colors=""
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
	PS1+=${__prompt_username_style}"\u"${__prompt_reset_colors}
	PS1+=${__prompt_at_symbol_style}"@"${__prompt_reset_colors}
	PS1+=${__prompt_hostname_style}"\h "${__prompt_reset_colors}
	PS1+=${__prompt_path_style}" \w "${__prompt_reset_colors}
	PS1+=${__prompt_git_style}${__prompt_git_ps1}${__prompt_reset_colors}
	PS1+=${__prompt_jobs_style}${__prompt_jobs_flag}${__prompt_reset_colors}
	PS1+=$'\n'
	PS1+=${__prompt_time_style}"\A "${__prompt_reset_colors}
	PS1+=${__prompt_end_style}"\\$"${__prompt_reset_colors}" "

}

# Set theme
THEME="${XDG_CONFIG_HOME}/themes/iceman.omp.json"
if type oh-my-posh > /dev/null 2>&1 && [ -r $THEME ]; then
	export VIRTUAL_ENV_DISABLE_PROMPT=1
	eval "$(oh-my-posh init bash --config ${THEME})"
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
