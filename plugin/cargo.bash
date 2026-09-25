# Rust (cargo)
# ------------

# rustup's environment file adds ~/.cargo/bin to PATH when it is missing
CARGO_ENV="${HOME}/.cargo/env"

if [ -r "$CARGO_ENV" ]; then
	# shellcheck source=/dev/null
	. "$CARGO_ENV"
fi

unset CARGO_ENV
