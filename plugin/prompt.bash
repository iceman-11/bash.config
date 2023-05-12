################################################################################
# Shell prompt
################################################################################

function __jobs_ps1 {

	# "jobs %%" prints the job ID of the most recent background process
	# (the "current job") and returns 0 on success or 1 if there is no such job
	if builtin jobs %% &> /dev/null; then
		printf "!"
	else
		printf " "
	fi
}

function __set_prompt {

	local __prmpt_colours __prmpt_jobs_style __prmpt_jobs_flag
	local __prmpt_username_style __prmpt_at_symbol_style __prmpt_hostname_style
	local __prmpt_path_style __prmpt_end_style __prmpt_reset_colours
	local __prmpt_git_style __prmpt_git_ps1

	# Jobs prompt
	__prmpt_jobs_flag='$(__jobs_ps1)'

	# Git Prompt
	if __git_ps1 &> /dev/null; then
		__prmpt_git_ps1='$(__git_ps1 " [%s] ")'
	fi

	# Check if stdout is a terminal...
	if test -t 1; then

		__prmpt_colours=$(tput colors)

		# See if it supports colours...
		if test -n "${__prmpt_colours}" && test ${__prmpt_colours} -ge 8; then

			__prmpt_jobs_style="\[\e[0;31;100m\]"

			if [ $EUID -eq "0" ]; then
				# For root:
				__prmpt_end_style="\[\e[0;31m\]"
			else
				# For normal users:
				__prmpt_end_style="\[\e[0;32m\]"
			fi

			__prmpt_username_style="\[\e[0;30;47m\]"
			__prmpt_at_symbol_style="\[\e[0;30;47m\]"
			__prmpt_hostname_style="\[\e[0;30;47m\]"
			__prmpt_path_style="\[\e[1;97;100m\]"
			__prmpt_git_style="\[\e[0;30;47m\]"
			__prmpt_reset_colours="\[\e[0m\]"
		else

			__prmpt_jobs_style=""
			__prmpt_end_style=""
			__prmpt_username_style=""
			__prmpt_at_symbol_style=""
			__prmpt_hostname_style=""
			__prmpt_path_style=""
			__prmpt_git_style=""
			__prmpt_reset_colours=""
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

	PS1+=${__prmpt_jobs_style}" "${__prmpt_jobs_flag}" "${__prmpt_reset_colours}
	PS1+=${__prmpt_username_style}" \u"${__prmpt_reset_colours}
	PS1+=${__prmpt_at_symbol_style}"@"${__prmpt_reset_colours}
	PS1+=${__prmpt_hostname_style}"\h "${__prmpt_reset_colours}
	PS1+=${__prmpt_path_style}" \w "${__prmpt_reset_colours}
	PS1+=${__prmpt_git_style}${__prmpt_git_ps1}${__prmpt_reset_colours}
	PS1+=$'\n'
	PS1+="\A "${__prmpt_end_style}"\\$"${__prmpt_reset_colours}" "

}

# Save and update history after each command
PROMPT_COMMAND="${PROMPT_COMMAND:+$PROMPT_COMMAND; }"
PROMPT_COMMAND+="history -n; history -w; history -c; history -r"
export PROMPT_COMMAND

# Set theme
THEME="${XDG_CONFIG_HOME}/themes/iceman.omp.json"
if type oh-my-posh > /dev/null 2>&1 && [ -r $THEME ]; then
	export VIRTUAL_ENV_DISABLE_PROMPT=1
	eval "$(oh-my-posh init bash --config ${THEME})"
else
	__set_prompt
	export PS1
fi

# Clean-up
unset __set_prompt

################################################################################
