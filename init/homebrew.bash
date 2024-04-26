# Homebrew
# --------

BREW="/home/linuxbrew/.linuxbrew/bin/brew"

if [[ -f "${BREW}" ]]; then
	eval "$(${BREW} shellenv)"
fi
