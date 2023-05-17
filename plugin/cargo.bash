CARGO_ENV="${HOME}/.cargo/env"

if [ -r "$CARGO_ENV" ]; then
	. "$CARGO_ENV" 
fi

