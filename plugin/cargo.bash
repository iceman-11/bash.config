CARGO_ENV="${HOME}/.cargo/env"

if [ -r "$CARGO_ENV" ]; then
	# shellcheck source=/dev/null
	. "$CARGO_ENV"
fi

