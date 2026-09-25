if type uv > /dev/null 2>&1; then
	alias uvreq='uv export --no-emit-project --no-dev --no-hashes'
fi

if __cache_output uv uv generate-shell-completion bash; then
	# shellcheck source=/dev/null disable=SC2154 # set by __cache_output
	. "$__cache_file"
fi

if __cache_output uvx uvx --generate-shell-completion bash; then
	# shellcheck source=/dev/null disable=SC2154 # set by __cache_output
	. "$__cache_file"
fi

