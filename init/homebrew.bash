# Homebrew
# --------

# Linuxbrew (system-wide or per user), then macOS (Apple Silicon, Intel)
for BREW in \
	/home/linuxbrew/.linuxbrew/bin/brew \
	"${HOME}/.linuxbrew/bin/brew" \
	/opt/homebrew/bin/brew \
	/usr/local/bin/brew; do
	[[ -x ${BREW} ]] && break
done

if [[ -x ${BREW} ]]; then
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

unset BREW
