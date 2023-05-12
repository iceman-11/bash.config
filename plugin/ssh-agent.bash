################################################################################
#
# Start SSH Agent
#
################################################################################

# Define variables #############################################################

HOSTNAME=$(uname -n | tr '[:upper:]' '[:lower:]')
OS=$(uname -s | tr '[:upper:]' '[:lower:]')

SSH_USER_DIR="${HOME}/.ssh"
SSH_AGENT_DIR="${SSH_USER_DIR}/agents"
SSH_AGENT_ENV="${SSH_AGENT_DIR}/${HOSTNAME%%.*}.env"
SSH_AUTOLOAD_KEYS="${SSH_USER_DIR}/autoload_keys"

SUCCESS=0
FAILURE=1

# Quit on missing components ###################################################

if ! type ssh-agent > /dev/null 2>&1; then
	return
elif ! [ -d ${SSH_USER_DIR} ] || ! [ -d ${SSH_AGENT_DIR} ]; then
	return
fi

# Define functions #############################################################

process_is_ssh_agent() {

	if [ -z "$1" ]; then
		return $FAILURE
	fi

	if [[ $OS =~ ^mingw64 ]]; then
		PROCESSES=$(ps -u $UID -p $1 -s | awk '{print $4, $1}' | column -t)
	else
		PROCESSES=$(ps -p $1 -ouid,comm,pid | awk '$1 == uid {print $2, $3}' uid=$UID)
	fi

	if echo $PROCESSES | grep '\<ssh-agent\>' > /dev/null 2>&1; then
		return $SUCCESS
	fi

	return $FAILURE
}

ssh_agent_running() {

	if [ -f $SSH_AGENT_ENV ]; then

		. $SSH_AGENT_ENV > /dev/null

		if [ ! -z "$SSH_AGENT_PID" ] &&
			process_is_ssh_agent $SSH_AGENT_PID
		then
			return $SUCCESS
		fi
	fi

	return $FAILURE
}

ssh_agent_has_keys() {

	if ssh-add -l > /dev/null 2>&1; then
		return $SUCCESS
	fi

	return $FAILURE
}

ssh_agent_add_keys() {

	if ! ssh_agent_has_keys; then
		LIFETIME=$(cat ${SSH_AUTOLOAD_KEYS})
		ssh-add -t ${LIFETIME:=12h} > /dev/null 2>&1
	fi
}

ssh_agent_delete_keys() {

	ssh-add -D > /dev/null 2>&1
}

ssh_agent_start() {

	ssh-agent > $SSH_AGENT_ENV
	chmod 600 $SSH_AGENT_ENV
	eval $(cat $SSH_AGENT_ENV) > /dev/null
}

ssh_agents_cleanup() {

	if [[ $OS =~ ^mingw64 ]]; then
		SSH_AGENTS=$(ps -u $UID -s | awk '$4 ~ /\<ssh-agent\>/ {print $1}')
	else
		SSH_AGENTS=$(ps -u $UID -ocomm,pid | awk '$1 ~/^ssh-agent$/ {print $2}')
	fi

	if [ ! -z "$SSH_AGENT_PID" ]; then
		SSH_AGENTS=$(echo "${SSH_AGENTS}" | egrep -v "^${SSH_AGENT_PID}$")
	fi

	if [ ! -z "$SSH_AGENTS" ]; then
		echo "$SSH_AGENTS" | xargs -i kill {} 2> /dev/null
	fi
}

# Start agent and add keys #####################################################

if ! ssh_agent_running; then
	ssh_agent_start
fi

if [ -f ${SSH_AUTOLOAD_KEYS} ]; then
	ssh_agent_add_keys
fi

ssh_agents_cleanup

# Unset functions ##############################################################

unset ssh_agent_running
unset ssh_agent_has_keys
unset ssh_agent_add_keys
unset ssh_agent_delete_keys
unset ssh_agents_cleanup

################################################################################
