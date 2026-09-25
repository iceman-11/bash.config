# Homebrew
# --------

BREW="/home/linuxbrew/.linuxbrew/bin/brew"

if [[ -f "${BREW}" ]]; then
	# 'brew shellenv' always puts brew first in PATH. When a parent shell has
	# already set it up, skip it: the inherited PATH order is kept (e.g. an
	# activated venv stays ahead of brew in a nested shell).
	case ":${PATH}:" in
		*":${BREW%/brew}:"*)
			[[ -n ${HOMEBREW_PREFIX:-} ]] || eval "$("${BREW}" shellenv)"
			;;
		*)
			eval "$("${BREW}" shellenv)"
			;;
	esac
fi
