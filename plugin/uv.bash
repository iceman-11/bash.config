if type uv > /dev/null 2>&1; then
	alias uvreq='uv export --no-emit-project --no-dev --no-hashes'
	eval "$(uv generate-shell-completion bash)"
fi

if type uv > /dev/null 2>&1; then
	eval "$(uvx --generate-shell-completion bash)"
fi

