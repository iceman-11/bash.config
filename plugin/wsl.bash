if ! [[ $(uname -r) =~ WSL2$ ]]; then
    # Stop if no WSL detected
    return
fi

if ! [[ -z "$USERPROFILE" ]]; then
    alias cdp='cd $USERPROFILE/projects'
fi
