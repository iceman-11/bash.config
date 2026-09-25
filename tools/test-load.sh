#!/usr/bin/env bash
################################################################################
#
# Load test: check that every file parses, then start an interactive bash with
# this configuration in a throw-away HOME and fail on any unexpected stderr
# output or if the plugins did not load.
#
# Usage: tools/test-load.sh [path/to/bash]
#
# Runs in CI (Linux, Git Bash, minimum bash version) and locally; the real
# HOME, history file and ssh-agent are never touched.
#
################################################################################

set -euo pipefail

BASH_BIN=${1:-bash}
REPO=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
FILES=("$REPO/bashrc" "$REPO"/init/*.bash "$REPO"/plugin/*.bash)

status=0

# shellcheck disable=SC2016
echo "== $("$BASH_BIN" -c 'echo "bash $BASH_VERSION"') on $(uname -s)"

# Syntax check #################################################################

for file in "${FILES[@]}"; do
	if ! "$BASH_BIN" -n "$file"; then
		echo "FAIL syntax: ${file#"$REPO"/}"
		status=1
	fi
done

# Interactive start-up in a throw-away HOME ####################################

sandbox=$(mktemp -d)
trap 'rm -rf "$sandbox"' EXIT

mkdir -p "$sandbox/.config"
cp -R "$REPO" "$sandbox/.config/bash"
rm -rf "$sandbox/.config/bash/.git"

# Minimal environment; keep what Git Bash needs to run Windows programs
env_vars=(HOME="$sandbox" PATH="$PATH" TERM=xterm-256color USER="${USER:-ci}")
for var in MSYSTEM SYSTEMROOT TMP TEMP; do
	[[ -n ${!var:-} ]] && env_vars+=("$var=${!var}")
done

# Run once the configuration is loaded: run the prompt hook, check that the
# plugins were loaded, then stop any agent the ssh-agent plugin started.
# shellcheck disable=SC2016
checks='
	eval "$PROMPT_COMMAND"
	for fn in hgrep xtitle where; do
		[[ $(type -t "$fn") == function ]] || echo "MISSING function $fn" >&2
	done
	[[ -n $PS1 ]] || echo "MISSING PS1" >&2
	[[ -n ${SSH_AGENT_PID:-} ]] && kill "$SSH_AGENT_PID"
	exit 0
'

rc=0
stderr=$(
	cd "$sandbox" &&
	env -i "${env_vars[@]}" \
		"$BASH_BIN" --rcfile "$sandbox/.config/bash/bashrc" -i -c "$checks" \
		2>&1 > /dev/null < /dev/null
) || rc=$?

if (( rc != 0 )); then
	echo "FAIL start-up exited with status $rc"
	status=1
fi

# Drop the messages bash itself prints when started without a terminal
unexpected=$(printf '%s\n' "$stderr" | grep -vE \
	-e 'cannot set terminal process group' \
	-e 'no job control in this shell' \
	-e '^exit$' \
	-e '^$' || true)

if [[ -n $unexpected ]]; then
	echo "FAIL unexpected output on stderr during start-up:"
	printf '%s\n' "$unexpected" | sed 's/^/  /'
	status=1
fi

if (( status == 0 )); then
	echo "OK"
fi

exit $status
