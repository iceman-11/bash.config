################################################################################
#
# Windows: helpers when bash runs on a Windows PC, in Git Bash or in WSL
#
################################################################################

# Git Bash sets MSYSTEM. WSL sets WSL_DISTRO_NAME, and its kernel release (the
# value 'uname -r' prints, read without starting a process) mentions Microsoft
# or WSL, also for WSL 1 and custom WSL kernels.
__kernel_release=
{ read -r __kernel_release < /proc/sys/kernel/osrelease; } 2> /dev/null

if [[ -n ${MSYSTEM:-} ]]; then
	__windows_env=gitbash
elif [[ -n ${WSL_DISTRO_NAME:-} || ${__kernel_release,,} == *microsoft* ||
	${__kernel_release,,} == *wsl* ]]; then
	__windows_env=wsl
else
	unset __kernel_release
	return
fi

unset __kernel_release

# Set __windows_profile_dir to the Windows profile folder (C:\Users\<name>)
# as a path of this shell. Worked out on first use, then remembered: in WSL
# it may need cmd.exe, which is too slow to run at every start-up.
function __windows_profile {
	[[ -n ${__windows_profile_dir:-} ]] && return 0

	local profile=${USERPROFILE:-}

	if [[ $__windows_env == gitbash ]]; then
		[[ -n $profile ]] && __windows_profile_dir=$(cygpath -u "$profile")
	else
		# WSL only passes USERPROFILE when WSLENV lists it. cmd.exe warns
		# when started from a Linux-only folder: start it from /mnt/c if
		# that exists.
		if [[ -z $profile ]]; then
			profile=$(cd /mnt/c 2> /dev/null || true; cmd.exe /c "echo %USERPROFILE%" 2> /dev/null)
			profile=${profile%$'\r'}
		fi

		# A Windows path (C:\...); with WSLENV=USERPROFILE/p it is already
		# a Linux path
		if [[ $profile == [A-Za-z]:\\* ]]; then
			profile=$(wslpath -u "$profile")
		fi

		__windows_profile_dir=$profile
	fi

	[[ -n ${__windows_profile_dir:-} ]]
}

# cd to the projects folder of the Windows profile
function cdp {
	if ! __windows_profile; then
		echo "cdp: Windows profile folder not found" >&2
		return 1
	fi

	cd "${__windows_profile_dir}/projects" || return
}
