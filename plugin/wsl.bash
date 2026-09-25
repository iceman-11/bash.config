# Same value as 'uname -r', read without starting a process (missing outside
# Linux, e.g. in Git Bash)
__kernel_release=
{ read -r __kernel_release < /proc/sys/kernel/osrelease; } 2> /dev/null

if ! [[ $__kernel_release =~ WSL2$ ]]; then
	# Stop if no WSL detected
	unset __kernel_release
	return
fi

unset __kernel_release

if ! [[ -z "$USERPROFILE" ]]; then
	alias cdp='cd $USERPROFILE/projects'
fi
