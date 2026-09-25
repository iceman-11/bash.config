################################################################################
#
# SSH Agent
#
# Keep a single ssh-agent per host, shared by every shell on that host.
#
# The agent listens on a fixed socket, so a shell only has to point
# SSH_AUTH_SOCK at it:
#
#   ${XDG_STATE_HOME:-~/.local/state}/ssh-agent/<host>.sock
#   ${XDG_STATE_HOME:-~/.local/state}/ssh-agent/<host>.pid
#
# Files are named after the host so that a home directory shared over NFS
# does not mix up the agents of different systems.
#
# No agent is started when:
#   - an agent is already reachable (forwarded, desktop, systemd, ...)
#   - the shell is a remote SSH login (set SSH_AGENT_FORCE_LOCAL=1 to override)
#
# Commands:
#   ssh_agent_reset         kill the agents started by this script on this
#                           host, then start a fresh one
#   ssh_agent_reset --all   same, but kill every ssh-agent you own on this host
#
# Works in Linux, WSL, Git Bash (MSYS2) and macOS.
#
################################################################################

# Quit on missing components ###################################################

if ! type ssh-agent ssh-add > /dev/null 2>&1; then
	return
fi

# Define functions #############################################################

# True if an agent answers on $SSH_AUTH_SOCK (ssh-add exit code 2: unreachable)
__ssh_agent_reachable() {
	ssh-add -l > /dev/null 2>&1
	[[ $? -ne 2 ]]
}

# Print the command line of process $1
__ssh_agent_cmdline() {
	if [[ -r /proc/$1/cmdline ]]; then
		tr '\0' ' ' < "/proc/$1/cmdline"
	else
		ps -p "$1" -o args= 2> /dev/null
	fi
}

# True if command line $1 is an ssh-agent (optionally listening on socket $2)
__ssh_agent_match() {
	local cmd=${1%% *}
	[[ ${cmd##*/} == ssh-agent && $1 == *"${2:-}"* ]]
}

# True if process $1 is the ssh-agent listening on socket $2
__ssh_agent_owns() {
	[[ $1 =~ ^[0-9]+$ ]] || return 1
	__ssh_agent_match "$(__ssh_agent_cmdline "$1")" "$2"
}

# Take the lock directory $1 (mkdir is atomic, also on NFS and in Git Bash).
# The holder writes its pid inside; a lock whose holder is gone is stale and
# removed. Give up after about 5 seconds.
__ssh_agent_lock() {
	local lock=$1 deadline=$(( SECONDS + 5 )) owner

	while (( SECONDS < deadline )); do
		if mkdir "$lock" 2> /dev/null; then
			echo $$ > "$lock/pid"
			return 0
		fi

		owner=
		{ read -r owner < "$lock/pid"; } 2> /dev/null
		if [[ $owner =~ ^[0-9]+$ ]] && ! kill -0 "$owner" 2> /dev/null; then
			rm -rf "$lock"
			continue
		fi

		sleep 0.1
	done

	return 1
}

__ssh_agent_init() {
	local host dir sock pidfile lock pid output

	# Reuse any agent that already answers (forwarded, desktop, systemd, ...)
	if __ssh_agent_reachable; then
		return
	fi

	# Remote login without agent forwarding: do not start an agent here
	if [[ -n ${SSH_CONNECTION:-} && -z ${SSH_AGENT_FORCE_LOCAL:-} ]]; then
		return
	fi

	host=$(uname -n | tr '[:upper:]' '[:lower:]')
	host=${host%%.*}
	dir=${XDG_STATE_HOME:-$HOME/.local/state}/ssh-agent
	sock=$dir/$host.sock
	pidfile=$dir/$host.pid
	lock=$dir/$host.lock

	mkdir -p "$dir" && chmod 700 "$dir" || return 1

	export SSH_AUTH_SOCK=$sock

	if ! __ssh_agent_reachable; then

		if ! __ssh_agent_lock "$lock"; then
			echo "ssh-agent: could not take lock $lock, agent not started" >&2
			unset SSH_AUTH_SOCK SSH_AGENT_PID
			return 1
		fi

		# Another shell may have started the agent while we were waiting
		if ! __ssh_agent_reachable; then

			# Kill our previous agent if it is still running without its socket
			pid=$(cat "$pidfile" 2> /dev/null)
			if __ssh_agent_owns "$pid" "$sock"; then
				kill "$pid" 2> /dev/null
			fi

			rm -f "$sock"

			if output=$(ssh-agent -s -a "$sock"); then
				eval "$output" > /dev/null
				echo "$SSH_AGENT_PID" > "$pidfile"
			else
				echo "ssh-agent: failed to start agent on $sock" >&2
			fi
		fi

		rm -rf "$lock"
	fi

	# Do not leave SSH_AUTH_SOCK pointing at a socket nobody listens on
	if ! __ssh_agent_reachable; then
		unset SSH_AUTH_SOCK SSH_AGENT_PID
		return 1
	fi

	# Export SSH_AGENT_PID so that 'ssh-agent -k' works
	pid=$(cat "$pidfile" 2> /dev/null)
	if __ssh_agent_owns "$pid" "$sock"; then
		export SSH_AGENT_PID=$pid
	else
		unset SSH_AGENT_PID
	fi
}

ssh_agent_reset() {
	local all=0 host dir sock proc pid args

	[[ ${1:-} == --all ]] && all=1

	host=$(uname -n | tr '[:upper:]' '[:lower:]')
	host=${host%%.*}
	dir=${XDG_STATE_HOME:-$HOME/.local/state}/ssh-agent
	sock=$dir/$host.sock

	# List "pid args" of all processes
	{
		if [[ -d /proc/self ]]; then
			for proc in /proc/[0-9]*; do
				pid=${proc#/proc/}
				echo "$pid $(tr '\0' ' ' < "$proc/cmdline" 2> /dev/null)"
			done
		else
			ps -U "$UID" -o pid=,args=
		fi
	} | while read -r pid args; do
		__ssh_agent_match "$args" || continue
		if (( all )) || [[ $args == *"$dir/"* ]]; then
			kill "$pid" 2> /dev/null && echo "ssh-agent: killed $pid ($args)"
		fi
	done

	rm -f "$sock" "$dir/$host.pid"

	if (( all )) || [[ ${SSH_AUTH_SOCK:-} == "$sock" ]]; then
		unset SSH_AUTH_SOCK SSH_AGENT_PID
	fi

	# Re-run this file to start a fresh agent
	# shellcheck source=/dev/null
	. "${BASH_SOURCE[0]}"
}

# Start agent ##################################################################

__ssh_agent_init

# Unset functions ##############################################################

# __ssh_agent_match is kept: ssh_agent_reset calls it after this file is sourced
unset -f __ssh_agent_reachable
unset -f __ssh_agent_cmdline
unset -f __ssh_agent_owns
unset -f __ssh_agent_lock
unset -f __ssh_agent_init

################################################################################
