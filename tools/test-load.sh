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

# Only parses if extglob is already on while plugins are loaded
mkdir -p "$sandbox/.config/bash/plugin/local"
printf 'case x in @(x|y)) ;; esac
' > "$sandbox/.config/bash/plugin/local/zz-test-extglob.bash"

# PATH checks: a directory standing for the inherited PATH, a venv for the
# nested shell, and the home bin directories
mkdir -p "$sandbox/inherited" "$sandbox/venv" "$sandbox/.local/bin" "$sandbox/bin"

# A stand-in 'man' (Git Bash has none), so that the man wrapper is defined
printf '#!/bin/sh\nexit 0\n' > "$sandbox/inherited/man"
chmod +x "$sandbox/inherited/man"

# A stand-in tmux: logs each show-environment call to ~/tmux-calls and
# answers with the line in ~/tmux-env ("VAR=value", or "-VAR" when tmux has
# the variable marked as removed), in the -s format when asked like tmux
cat > "$sandbox/inherited/tmux" <<'EOF'
#!/bin/sh
if [ "$1" = ls ]; then
	cat "$HOME/tmux-sessions" 2> /dev/null
fi
if [ "$1" = show-environment ]; then
	echo x >> "$HOME/tmux-calls"
	line=$(cat "$HOME/tmux-env" 2> /dev/null)
	if [ "$2" = -s ]; then
		case $line in
			-*) echo "unset ${line#-};" ;;
			*=*) echo "${line%%=*}=\"${line#*=}\"; export ${line%%=*};" ;;
		esac
	else
		echo "$line"
	fi
fi
exit 0
EOF
chmod +x "$sandbox/inherited/tmux"

# Stand-ins: fd (fzf settings), an fzf older than 0.48 (no --bash), and for a
# simulated WSL: cmd.exe printing the Windows profile, wslpath converting it
printf '#!/bin/sh\nexit 0\n' > "$sandbox/inherited/fd"
printf '#!/bin/sh\n[ "$1" = --bash ] && { echo "unknown option: --bash" >&2; exit 2; }\nexit 0\n' \
	> "$sandbox/inherited/fzf"
cat > "$sandbox/inherited/cmd.exe" <<'EOF'
#!/bin/sh
# Like cmd.exe /c "echo %USERPROFILE%": a Windows path, CRLF line ending
printf '%s\r\n' 'C:\Users\tester'
EOF
cat > "$sandbox/inherited/wslpath" <<'EOF'
#!/bin/sh
[ "$1" = -u ] && shift
if [ "$1" = 'C:\Users\tester' ]; then echo "$HOME/winprofile"; else echo "$1"; fi
EOF
chmod +x "$sandbox/inherited/fd" "$sandbox/inherited/fzf" "$sandbox/inherited/cmd.exe" "$sandbox/inherited/wslpath"
mkdir -p "$sandbox/winprofile/projects"

# A stale ssh-agent lock without a pid file (its holder died before writing
# it): the plugin must not wait for it
host=${HOSTNAME,,}
mkdir -p "$sandbox/.local/state/ssh-agent/${host%%.*}.lock"
touch -d "2000-01-01" "$sandbox/.local/state/ssh-agent/${host%%.*}.lock"

# Minimal environment; keep what Git Bash needs to run Windows programs
env_vars=(HOME="$sandbox" PATH="$sandbox/inherited:$PATH" TERM=xterm-256color USER="${USER:-ci}")
for var in MSYSTEM SYSTEMROOT TMP TEMP; do
	[[ -n ${!var:-} ]] && env_vars+=("$var=${!var}")
done

# Run once the configuration is loaded: run the prompt hook, check that the
# plugins were loaded and what the configuration sets, then stop any agent the
# ssh-agent plugin started.
# shellcheck disable=SC2016
checks='
	# What bash runs before each prompt (PROMPT_COMMAND may be an array)
	run_prompt() { local c; for c in "${PROMPT_COMMAND[@]}"; do eval "$c"; done; }

	run_prompt
	for fn in hgrep xtitle where; do
		[[ $(type -t "$fn") == function ]] || echo "MISSING function $fn" >&2
	done
	[[ -n $PS1 ]] || echo "MISSING PS1" >&2

	# Home bin directories, then the inherited PATH in its order (a plugin
	# such as Homebrew may put its own directories in front)
	case $PATH in
		"$HOME/.local/bin:$HOME/bin:$HOME/inherited:"* | \
		*":$HOME/.local/bin:$HOME/bin:$HOME/inherited:"*) ;;
		*) echo "PATH lacks ~/.local/bin:~/bin:<inherited> in this order: ${PATH:0:200}" >&2 ;;
	esac

	# A nested shell keeps the PATH it inherits unchanged (e.g. a venv first)
	nested=$(PATH="$HOME/venv:$PATH" "$BASH" --rcfile "$HOME/.config/bash/bashrc" \
		-ic "printf %s \"\$PATH\"" 2> /dev/null < /dev/null)
	[[ $nested == "$HOME/venv:$PATH"* ]] ||
		echo "PATH reordered in a nested shell: ${nested:0:200}" >&2

	# System tools come from /usr/bin, not from a Windows directory
	if [[ -x /usr/bin/find ]]; then
		[[ $(type -P find) -ef /usr/bin/find ]] || echo "find resolves to $(type -P find)" >&2
	fi

	# Nothing the configuration should set or enable by itself
	for var in DISPLAY LC_ALL; do
		[[ -v $var ]] && echo "$var set by the configuration: ${!var}" >&2
	done

	# XAUTHORITY is exported, so that a process whose HOME differs (su, sudo)
	# still finds the calling user'"'"'s cookie; a value already set is kept
	[[ $(declare -p XAUTHORITY 2> /dev/null) == "declare -x XAUTHORITY=\"$HOME/.Xauthority\"" ]] ||
		echo "XAUTHORITY not exported as ~/.Xauthority: $(declare -p XAUTHORITY 2>&1)" >&2
	as_root=$(HOME=/nonexistent "$BASH" --norc -c "printf %s \"\$XAUTHORITY\"")
	[[ $as_root == "$HOME/.Xauthority" ]] ||
		echo "XAUTHORITY lost when HOME changes: $as_root" >&2
	kept=$(XAUTHORITY=/run/user/1000/gdm/Xauthority "$BASH" --rcfile "$HOME/.config/bash/bashrc" \
		-ic "printf %s \"\$XAUTHORITY\"" 2> /dev/null < /dev/null)
	[[ $kept == /run/user/1000/gdm/Xauthority ]] ||
		echo "XAUTHORITY already set was not kept: $kept" >&2
	shopt -q dotglob && echo "dotglob is on" >&2

	# History: timestamps are saved (HISTTIMEFORMAT set) but not shown (empty),
	# so a multi-line command is still one entry after the per-prompt reload
	[[ -v HISTTIMEFORMAT && -z $HISTTIMEFORMAT ]] ||
		echo "HISTTIMEFORMAT is not set to an empty value: ${HISTTIMEFORMAT-<unset>}" >&2
	history -s "$(printf "for i in 1 2\ndo\n  echo \$i\ndone")"
	run_prompt
	(( $(fc -ln -1 | wc -l) == 4 )) ||
		echo "multi-line history entry split by the per-prompt reload: $(fc -ln -1)" >&2

	# aliases.bash: where, path, winpwd, xtitle, man
	[[ $(where ls) == /* ]] || echo "where ls: \"$(where ls)\" is not a path" >&2
	[[ $( (PATH="$PATH:/x  y"; path) | tail -n 1) == "/x  y" ]] ||
		echo "path changes a PATH entry with two spaces: $( (PATH="$PATH:/x  y"; path) | tail -n 1)" >&2
	if type cygpath > /dev/null 2>&1; then
		mkdir -p "$HOME/dir with space" && cd "$HOME/dir with space" &&
			[[ $(winpwd) == *"dir with space" ]] ||
			echo "winpwd in a directory with a space: $(winpwd)" >&2
		cd "$HOME"
	fi
	[[ $(TERM=tmux-256color xtitle "a\\tb") == "$(printf "\033]0;%s\007" "a\\tb")" ]] ||
		echo "xtitle: no title for TERM=tmux-256color or backslash interpreted" >&2
	[[ $(TERM=xterm man 3 printf) == "$(printf "\033]0;The printf manual\007")" ]] ||
		echo "man 3 printf: wrong window title" >&2
	[[ -z $(TERM=xterm man) ]] || echo "man without a page sets a window title" >&2

	# prompt.bash: not exported (a child bash without this configuration
	# would print raw escapes or "prompt_command: command not found")
	[[ $(declare -p PS1 2> /dev/null) != "declare -x"* ]] || echo "PS1 is exported" >&2
	env | grep -q "^PROMPT_COMMAND=" && echo "PROMPT_COMMAND is exported" >&2

	# prompt.bash: fallback prompt (no oh-my-posh theme in the sandbox) shows
	# the venv and the job count without subshells (only the git part runs one)
	no_git=${PS1//\$(__git_ps1/}
	[[ $no_git != *"\$("* ]] || echo "fallback prompt starts subshells: $PS1" >&2
	[[ ${PS1@P} != *" !"* ]] || echo "fallback prompt shows jobs without jobs" >&2
	{ sleep 5 & } 2> /dev/null
	[[ ${PS1@P} == *" !1"* ]] || echo "fallback prompt: no job count with one job" >&2
	kill $! 2> /dev/null
	wait $! 2> /dev/null
	[[ $(VIRTUAL_ENV=/x/app/.venv; printf %s "${PS1@P}") == *" (.venv)"* ]] ||
		echo "fallback prompt: no venv name" >&2
	title=$(TERM=alacritty "$BASH" --rcfile "$HOME/.config/bash/bashrc" \
		-ic "printf %s \"\$PS1\"" 2> /dev/null < /dev/null)
	[[ $title == *"\\033]0;"* ]] || echo "fallback prompt: no window title for TERM=alacritty" >&2

	# prompt.bash: tmux SSH_AUTH_SOCK refresh, with the stand-in tmux and the
	# socket of the agent the ssh-agent plugin started in the sandbox
	if [[ -S ${SSH_AUTH_SOCK:-} ]]; then
		real_sock=$SSH_AUTH_SOCK
		export TMUX=/tmp/fake-tmux,1,0

		# A stale socket is replaced by the one tmux has
		printf "SSH_AUTH_SOCK=%s\n" "$real_sock" > "$HOME/tmux-env"
		SSH_AUTH_SOCK=$HOME/stale.sock
		run_prompt
		[[ $SSH_AUTH_SOCK == "$real_sock" ]] ||
			echo "tmux: stale SSH_AUTH_SOCK not replaced: ${SSH_AUTH_SOCK-<unset>}" >&2

		# Marked as removed in tmux: not unset, and tmux asked at most once
		# over several quick prompts
		echo "-SSH_AUTH_SOCK" > "$HOME/tmux-env"
		rm -f "$HOME/tmux-calls"
		SSH_AUTH_SOCK=$HOME/stale.sock
		for i in 1 2 3 4 5; do run_prompt; done
		[[ ${SSH_AUTH_SOCK-} == "$HOME/stale.sock" ]] ||
			echo "tmux: SSH_AUTH_SOCK changed to ${SSH_AUTH_SOCK-<unset>}" >&2
		calls=$(cat "$HOME/tmux-calls" 2> /dev/null | wc -l)
		(( calls <= 1 )) || echo "tmux: asked $calls times in 5 prompts" >&2

		unset TMUX
		SSH_AUTH_SOCK=$real_sock
	fi

	# A nested interactive shell with this configuration: run "$@" in it
	nested() { "$BASH" --rcfile "$HOME/.config/bash/bashrc" -ic "$*" 2> /dev/null < /dev/null; }

	# git.bash: __git_ps1 is defined wherever git-prompt.sh is installed
	for f in /usr/lib/git-core/git-sh-prompt \
		/usr/share/git-core/contrib/completion/git-prompt.sh \
		/usr/share/git/completion/git-prompt.sh \
		/mingw64/share/git/completion/git-prompt.sh; do
		if [[ -r $f ]]; then
			declare -F __git_ps1 > /dev/null || echo "__git_ps1 not defined although $f exists" >&2
			break
		fi
	done

	# vim.bash: an editor is chosen, and VISUAL is the same
	[[ -n ${EDITOR:-} && ${VISUAL:-} == "$EDITOR" ]] ||
		echo "EDITOR/VISUAL: \"${EDITOR-}\" / \"${VISUAL-}\"" >&2

	# fzf.bash: the fd settings also apply under mintty (the stand-in fzf is
	# older than 0.48: an error message would show up as unexpected output)
	[[ -n $(unset FZF_DEFAULT_COMMAND; TERM_PROGRAM=mintty nested "printf %s \"\$FZF_DEFAULT_COMMAND\"") ]] ||
		echo "fzf: fd settings skipped under mintty" >&2

	# zoxide.bash: cd and cdi are zoxide functions (where zoxide is installed),
	# and z is an alias of cd
	if type zoxide > /dev/null 2>&1; then
		[[ $(type -t cd) == function && $(type -t cdi) == function ]] ||
			echo "zoxide: cd is a(n) $(type -t cd), cdi is a(n) $(type -t cdi)" >&2
	fi
	[[ $(alias z 2> /dev/null) == *cd* ]] || echo "z is not an alias of cd" >&2

	# tmux.bash: session list (stand-in tmux), with singular and plural
	printf "main:1\nwork:3\n" > "$HOME/tmux-sessions"
	list=$(nested true)
	[[ $list == *"(1 window)"* && $list == *"(3 windows)"* ]] ||
		echo "tmux session list: $list" >&2
	rm -f "$HOME/tmux-sessions"

	# windows.bash: cdp goes to <Windows profile>/projects
	if type cygpath > /dev/null 2>&1; then
		dir=$(USERPROFILE=$(cygpath -w "$HOME/winprofile") nested "cdp && pwd")
		[[ $dir == "$HOME/winprofile/projects" ]] || echo "cdp (Git Bash): \"$dir\"" >&2
	elif [[ $OSTYPE == linux* ]]; then
		dir=$(WSL_DISTRO_NAME=Test nested "cdp && pwd")
		[[ $dir == "$HOME/winprofile/projects" ]] || echo "cdp (WSL, via cmd.exe): \"$dir\"" >&2
		dir=$(WSL_DISTRO_NAME=Test USERPROFILE="$HOME/winprofile" nested "cdp && pwd")
		[[ $dir == "$HOME/winprofile/projects" ]] || echo "cdp (WSL, USERPROFILE set): \"$dir\"" >&2
		[[ -z $(nested "type -t cdp") ]] || echo "cdp defined outside WSL and Git Bash" >&2
	fi

	# bashrc: an LC_* variable or LANG naming a locale that is not installed
	# (e.g. en_BE.UTF-8 from KDE Plasma) is dropped; installed ones are kept.
	# Only where locale -a lists the installed locales (not with musl).
	if [[ -n $(locale -a 2> /dev/null) ]]; then
		lc=$(LC_MONETARY=xx_YY.UTF-8 LC_PAPER=C nested "printf %s \"\${LC_MONETARY-unset}/\${LC_PAPER-unset}\"")
		[[ $lc == unset/C ]] || echo "LC_* not installed: LC_MONETARY/LC_PAPER = $lc (expected unset/C)" >&2
		# (a UTF-8 LANG alone is trusted without starting a process; it is
		# checked when an LC_* variable makes the configuration read the list)
		lang=$(LANG=xx_YY.UTF-8 LC_PAPER=C nested "printf %s \"\$LANG\"")
		[[ $lang != xx_YY.UTF-8 ]] || echo "LANG not installed was kept: $lang" >&2
	fi

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
